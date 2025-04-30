package com.mine.world;

import org.eclipse.jetty.websocket.api.Session;
import org.eclipse.jetty.websocket.api.WebSocketListener;
import org.eclipse.jetty.websocket.client.WebSocketClient;

import java.io.IOException;
import java.net.URI;
import java.nio.ByteBuffer;

public class ProxyWebSocket implements WebSocketListener {

    private Session clientSession;  // 与前端的 WebSocket 会话
    private Session targetSession;  // 与目标 WebSocket 服务的会话

    // 当 WebSocket 连接成功时调用
    @Override
    public void onWebSocketConnect(Session session) {
        this.clientSession = session;

        // 连接到目标 WebSocket 服务
        try {
            // 假设目标 WebSocket 服务地址为 "ws://127.0.0.1:2048"
            WebSocketClient client = new WebSocketClient();
            client.start();
            URI targetUri = new URI("ws://127.0.0.1:2048/whatever");
            client.connect(new TargetWebSocket(), targetUri).get();
        } catch (Exception e) {
            e.printStackTrace();
            closeSession(clientSession);
        }
    }

    // 当接收到来自客户端的文本消息时调用
    @Override
    public void onWebSocketText(String message) {
        if (targetSession != null && targetSession.isOpen()) {
            try {
                targetSession.getRemote().sendString(message);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    // 当接收到来自客户端的二进制消息时调用
    @Override
    public void onWebSocketBinary(byte[] payload, int offset, int len) {
        if (targetSession != null && targetSession.isOpen()) {
            try {
                targetSession.getRemote().sendBytes(ByteBuffer.wrap(payload, offset, len));
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    // 当 WebSocket 连接关闭时调用
    @Override
    public void onWebSocketClose(int statusCode, String reason) {
        closeSession(clientSession);
        closeSession(targetSession);
    }

    // 当 WebSocket 发生错误时调用
    @Override
    public void onWebSocketError(Throwable cause) {
    }

    // 关闭 WebSocket 会话
    private void closeSession(Session session) {
        if (session != null && session.isOpen()) {
            try {
                session.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    // 内部类用于连接到目标 WebSocket 服务并处理响应
    public class TargetWebSocket implements WebSocketListener {

        @Override
        public void onWebSocketConnect(Session session) {
            targetSession = session;
        }

        @Override
        public void onWebSocketText(String message) {
            if (clientSession != null && clientSession.isOpen()) {
                try {
                    clientSession.getRemote().sendString(message);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }

        @Override
        public void onWebSocketBinary(byte[] payload, int offset, int len) {
            if (clientSession != null && clientSession.isOpen()) {
                try {
                    clientSession.getRemote().sendBytes(ByteBuffer.wrap(payload, offset, len));
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }

        @Override
        public void onWebSocketClose(int statusCode, String reason) {
        }

        @Override
        public void onWebSocketError(Throwable cause) {
        }
    }
}
