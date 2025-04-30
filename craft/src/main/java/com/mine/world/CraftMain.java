package com.mine.world;

import org.apache.commons.exec.CommandLine;
import org.apache.commons.exec.DefaultExecutor;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.servlet.ServletContextHandler;
import org.eclipse.jetty.servlet.ServletHolder;
import org.eclipse.jetty.websocket.server.config.JettyWebSocketServletContainerInitializer;

import java.io.IOException;

public class CraftMain {
    private static final String TARGET_URL = "ws://127.0.0.1:2048";
    private static final String SERVICE_COMMAND = "./myservice run --config ali.json";

    public static void main(String[] args) throws Exception {
        Server server = new Server(10117);

        // 创建 ServletContextHandler 来绑定 WebSocket 路由
        ServletContextHandler context = new ServletContextHandler(ServletContextHandler.SESSIONS);
        context.setContextPath("/");

        // 初始化 WebSocket 路由
        JettyWebSocketServletContainerInitializer.configure(context, (servletContext, wsContainer) -> {
            // 设置 WebSocket 映射
            wsContainer.addMapping("/whatever", (req, resp) -> new ProxyWebSocket());
        });

        context.addServlet(new ServletHolder(new ScriptServlet()), "/script/*");

        server.setHandler(context);
        server.start();
        System.out.println("Server started at ws://localhost:3000/whatever");

        // 启动后台守护线程
        Thread checker = new Thread(() -> {
                    startService();
        });
        checker.start();

        server.join();
    }

    private static boolean isServiceRunning() {
        // TODO: 实现检测逻辑（比如检查进程名、端口、pid 等）
        return false;
    }

    private static void startService() {
        CommandLine cmdLine = CommandLine.parse(SERVICE_COMMAND);
        DefaultExecutor executor = new DefaultExecutor();
        try {
            executor.execute(cmdLine);
            System.out.println("Service started.");
        } catch (IOException e) {
            System.err.println("Failed to start service: " + e.getMessage());
        }
    }

}
