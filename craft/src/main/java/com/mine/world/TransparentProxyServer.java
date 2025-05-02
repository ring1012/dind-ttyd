package com.mine.world;

import io.netty.bootstrap.Bootstrap;
import io.netty.bootstrap.ServerBootstrap;
import io.netty.channel.*;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.http.*;
import io.netty.buffer.Unpooled;
import java.net.InetSocketAddress;

public class TransparentProxyServer {
    private final int listenPort;
    private final String remoteHost;
    private final int remotePort;

    public TransparentProxyServer(int listenPort, String remoteHost, int remotePort) {
        this.listenPort = listenPort;
        this.remoteHost = remoteHost;
        this.remotePort = remotePort;
    }

    public void start() throws InterruptedException {
        EventLoopGroup bossGroup = new NioEventLoopGroup(1);
        EventLoopGroup workerGroup = new NioEventLoopGroup();
        try {
            ServerBootstrap sb = new ServerBootstrap();
            sb.group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel ch) {
                            ChannelPipeline p = ch.pipeline();
                            p.addLast(new HttpServerCodec());
                            p.addLast(new HttpObjectAggregator(8192));
                            p.addLast(new ProxyFrontendHandler(remoteHost, remotePort));
                        }
                    });

            ChannelFuture f = sb.bind(listenPort).sync();
            System.out.println("Transparent proxy listening on port " + listenPort);
            f.channel().closeFuture().sync();
        } finally {
            bossGroup.shutdownGracefully();
            workerGroup.shutdownGracefully();
        }
    }

    public static void main(String[] args) throws InterruptedException {
        new TransparentProxyServer(8080, "192.168.3.214", 2048).start();
    }
}

class ProxyFrontendHandler extends SimpleChannelInboundHandler<FullHttpRequest> {
    private final String remoteHost;
    private final int remotePort;

    public ProxyFrontendHandler(String remoteHost, int remotePort) {
        this.remoteHost = remoteHost;
        this.remotePort = remotePort;
    }

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, FullHttpRequest req) {
        if (HttpHeaderValues.WEBSOCKET.contentEqualsIgnoreCase(req.headers().get(HttpHeaderNames.UPGRADE))) {
            handleWebsocketProxy(ctx, req);
        } else {
            FullHttpResponse resp = new DefaultFullHttpResponse(
                    HttpVersion.HTTP_1_1, HttpResponseStatus.NOT_FOUND);
            ctx.writeAndFlush(resp).addListener(ChannelFutureListener.CLOSE);
        }
    }

    private void handleWebsocketProxy(ChannelHandlerContext ctx, FullHttpRequest req) {
        FullHttpRequest upstreamReq = req.retainedDuplicate();
        // 重写 Host
        upstreamReq.headers().set(HttpHeaderNames.HOST, remoteHost + ":" + remotePort);
        // 设置透传客户端 IP 头
        String clientIp = ((InetSocketAddress) ctx.channel().remoteAddress()).getAddress().getHostAddress();
        upstreamReq.headers().set("X-Real-IP", clientIp);
        String existingXFF = req.headers().get("X-Forwarded-For");
        if (existingXFF != null) {
            upstreamReq.headers().set("X-Forwarded-For", existingXFF + ", " + clientIp);
        } else {
            upstreamReq.headers().set("X-Forwarded-For", clientIp);
        }

        Bootstrap b = new Bootstrap();
        b.group(ctx.channel().eventLoop())
                .channel(NioSocketChannel.class)
                .handler(new ChannelInitializer<SocketChannel>() {
                    @Override
                    protected void initChannel(SocketChannel ch) {
                        ChannelPipeline p = ch.pipeline();
                        p.addLast(new HttpClientCodec());
                        p.addLast(new HttpObjectAggregator(8192));
                        p.addLast(new BackendHandshakeHandler(ctx.channel()));
                    }
                });

        b.connect(remoteHost, remotePort).addListener((ChannelFutureListener) future -> {
            if (future.isSuccess()) {
                future.channel().writeAndFlush(upstreamReq);
                // 等待 BackendHandshakeHandler 处理握手响应后，再切换到透传
            } else {
                FullHttpResponse resp = new DefaultFullHttpResponse(
                        HttpVersion.HTTP_1_1, HttpResponseStatus.BAD_GATEWAY);
                ctx.writeAndFlush(resp).addListener(ChannelFutureListener.CLOSE);
            }
        });
    }

    private boolean isWebsocketUpgrade(FullHttpRequest req) {
        return HttpHeaderValues.WEBSOCKET.contentEqualsIgnoreCase(req.headers().get(HttpHeaderNames.UPGRADE));
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        cause.printStackTrace();
        ctx.close();
    }
}

class BackendHandshakeHandler extends SimpleChannelInboundHandler<FullHttpResponse> {
    private final Channel frontChannel;

    public BackendHandshakeHandler(Channel frontChannel) {
        this.frontChannel = frontChannel;
    }

    @Override
    protected void channelRead0(ChannelHandlerContext ctx, FullHttpResponse msg) {
        if (msg.status().equals(HttpResponseStatus.SWITCHING_PROTOCOLS)) {
            // 握手成功：先回传给客户端
            frontChannel.writeAndFlush(msg.retainedDuplicate());

            // 切换到纯 ByteBuf 透传模式
            frontChannel.pipeline().remove(HttpServerCodec.class);
            frontChannel.pipeline().remove(HttpObjectAggregator.class);
            ctx.pipeline().remove(HttpClientCodec.class);
            ctx.pipeline().remove(HttpObjectAggregator.class);

            frontChannel.pipeline().addLast(new RelayHandler(ctx.channel()));
            ctx.pipeline().addLast(new RelayHandler(frontChannel));

            // 移除自己
            ctx.pipeline().remove(this);
        } else {
            // 非 101 响应：直接回传并关闭
            frontChannel.writeAndFlush(msg).addListener(f -> frontChannel.close());
            ctx.close();
        }
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        cause.printStackTrace();
        frontChannel.writeAndFlush(Unpooled.EMPTY_BUFFER).addListener(ChannelFutureListener.CLOSE);
        ctx.close();
    }
}

class RelayHandler extends ChannelInboundHandlerAdapter {
    private final Channel relayChannel;

    public RelayHandler(Channel relayChannel) {
        this.relayChannel = relayChannel;
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) {
        relayChannel.writeAndFlush(msg);
    }

    @Override
    public void channelInactive(ChannelHandlerContext ctx) {
        if (relayChannel.isActive()) {
            relayChannel.writeAndFlush(Unpooled.EMPTY_BUFFER).addListener(ChannelFutureListener.CLOSE);
        }
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        cause.printStackTrace();
        if (relayChannel.isActive()) {
            relayChannel.writeAndFlush(Unpooled.EMPTY_BUFFER).addListener(ChannelFutureListener.CLOSE);
        }
    }
}
