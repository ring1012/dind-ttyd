const express = require('express');
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('/home/container/certs/privkey.pem'),
  cert: fs.readFileSync('/home/container/certs/fullchain.pem')
};

const httpProxy = require('http-proxy');
const { exec, spawn } = require('child_process');
const path = require('path');

// myservice 文件的路径
const servicePath = path.resolve(__dirname, 'myservice');

// 确保 myservice 文件具有执行权限
fs.chmodSync(servicePath, 0o755); // 等同于 chmod 755 myservice

// 设置定时任务间隔为 10 秒
const CHECK_INTERVAL = 10000; // 10秒
const target = 'http://127.0.0.1:2048'; // 代理目标

// 创建 Express 应用和 HTTP 服务器
const app = express();
const server = https.createServer(options, app);

const proxy = httpProxy.createProxyServer({});

// 异常处理：捕获未处理的异常
process.on('uncaughtException', (err) => {
  console.error('未捕获的异常:', err);
  // 退出或做其他处理
});

// 异常处理：捕获未处理的 Promise 拒绝
process.on('unhandledRejection', (reason, promise) => {
  console.error('未处理的拒绝:', reason);
  // 退出或做其他处理
});

// 动态导入 ps-list 并检查目标服务是否运行
async function checkAndStartService() {
  console.log("checkAndStartService");
  try {
    // 动态导入 ps-list
    //const psList = (await import('ps-list')).default;

    // 使用 await 等待 psList() 的结果
    //const processes = await psList();

    //const isServiceRunning = processes.some(process => process.cmd && process.cmd.includes('myservice'));

   // if (!isServiceRunning) {
      console.log('Service not running. Starting myservice...');
      
      // 启动服务进程，并将输出重定向到 /dev/null（即不显示输出）
      const myservice = spawn('./myservice', ['run', '--config', 'ali.json'], {
        detached: true, // 使进程脱离当前进程
        stdio: ['ignore', 'ignore', 'ignore'] // 忽略输出
      });

      myservice.unref(); // 使子进程不会阻止 Node.js 主进程退出

      console.log('Service started in the background');
    //} else {
     // console.log('Service is already running');
   // }
  } catch (err) {
    console.error(`Error checking processes: ${err.message}`);
  }
}

// 启动定时任务
//setInterval(checkAndStartService, CHECK_INTERVAL);
checkAndStartService()
// WebSocket 请求处理
app.use('/whatever', (req, res, next) => {
  const upgradeHeader = req.headers['upgrade'];

  if (upgradeHeader && upgradeHeader.toLowerCase() === 'websocket') {
    // WebSocket 请求，交由 upgrade 事件处理
    next();
  } else {
    // 非 WebSocket 请求，返回 mask 页面
    res.redirect('/mask-page');
  }
});

// mask 页面路由
app.get('/mask-page', (req, res) => {
  res.send('<h1>This is a mask page</h1>');
});

// WebSocket 代理事件处理
server.on('upgrade', (req, socket, head) => {
  try {
    if (req.url.startsWith('/whatever') && req.headers['upgrade'] === 'websocket') {
      proxy.ws(req, socket, head, { target }, (err) => {
        if (err) {
          socket.destroy(); // 代理请求错误时，销毁连接
        }
      });
    } else {
      socket.destroy(); // 不是 WebSocket 请求，断开连接
    }
  } catch (err) {
    socket.destroy(); // 确保关闭连接
  }
});

// 启动服务器
server.listen(process.env.PORT || 27465, () => {
  console.log('Proxy server listening on port', process.env.PORT || 27465);
});