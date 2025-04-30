package com.mine.world;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.apache.commons.exec.CommandLine;
import org.apache.commons.exec.DefaultExecutor;
import org.apache.commons.exec.Executor;
import org.apache.commons.exec.PumpStreamHandler;


import java.io.IOException;

// 示例 HTTP Servlet 用于处理 /script 请求
public class ScriptServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // 获取请求的路径部分，提取脚本名
        String pathInfo = request.getPathInfo();  // 获取例如 "/1.sh"
        if (pathInfo != null && pathInfo.startsWith("/")) {
            pathInfo = pathInfo.substring(1); // 去掉开头的 "/"
        }

        // 执行脚本
        String scriptPath = "./" + pathInfo; // 替换为你实际的脚本存放路径
        String result = executeScript(scriptPath);

        // 设置响应内容类型
        response.setContentType("text/plain");
        response.setStatus(HttpServletResponse.SC_OK);
        response.getWriter().write(result);
    }

    // 执行 bash 脚本并返回命令行输出
    private String executeScript(String scriptPath) {
        StringBuilder output = new StringBuilder();
        Executor executor = new DefaultExecutor();
        CommandLine cmdLine = CommandLine.parse("bash " + scriptPath);

        // 捕获命令输出
        PumpStreamHandler streamHandler = new PumpStreamHandler(
                new java.io.OutputStream() {
                    @Override
                    public void write(int b) throws IOException {
                        output.append((char) b);
                    }
                });

        executor.setStreamHandler(streamHandler);
        try {
            int exitCode = executor.execute(cmdLine);
            if (exitCode != 0) {
                output.append("Script execution failed with exit code: " + exitCode);
            }
        } catch (IOException e) {
            output.append("Error executing script: " + e.getMessage());
        }

        return output.toString();
    }

}
