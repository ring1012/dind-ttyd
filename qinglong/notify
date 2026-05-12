#!/bin/bash
# ============================================================
# 用法: bash remote_email.sh "任务摘要" "https://链接地址"
# ============================================================

SUMMARY="$1"
LINK="$2"

if [ -z "$SUMMARY" ] || [ -z "$LINK" ]; then
    echo "❌ 错误: 请提供两个参数: 摘要 和 链接"
    echo "用法: $0 \"签到成功\" \"https://example.com/detail\""
    exit 1
fi

# 1. 加载青龙面板中的 SMTP 环境变量文件
ENV_FILE="/ql/shell/preload/env.sh"
if [ -f "$ENV_FILE" ]; then
    echo "🔄 正在从 $ENV_FILE 加载环境变量..."
    source "$ENV_FILE"
else
    echo "❌ 错误: 未找到环境变量文件 $ENV_FILE"
    exit 1
fi

# 2. 检查变量是否已加载
if [ -z "$SMTP_SERVER" ] || [ -z "$SMTP_EMAIL" ] || [ -z "$SMTP_PASSWORD" ]; then
    echo "❌ 错误: 加载后仍缺少 SMTP 环境变量，请检查 $ENV_FILE 内容"
    exit 1
fi
echo "✅ 成功加载 SMTP 环境变量"

# 3. 使用 Python 发送邮件（内嵌代码）
python3 - <<EOF
import os
import sys
import smtplib
from email.message import EmailMessage

smtp_server = os.environ.get('SMTP_SERVER', '')
smtp_email = os.environ.get('SMTP_EMAIL', '')
smtp_password = os.environ.get('SMTP_PASSWORD', '')
smtp_name = os.environ.get('SMTP_NAME', '')

summary = '''$SUMMARY'''
link = '''$LINK'''

def get_smtp_port(server):
    if ':' in server:
        host, port = server.split(':', 1)
        return host, int(port)
    return server, 465

server_host, server_port = get_smtp_port(smtp_server)

msg = EmailMessage()
msg['From'] = f"{smtp_name} <{smtp_email}>" if smtp_name else smtp_email
msg['To'] = "1223305593@qq.com"   # 发给自己，可修改
msg['Subject'] = f"【青龙通知】{summary}"

html_content = f"""
<html>
<body>
    <p><strong>{summary}</strong></p>
    <p>点击查看详情：<a href="{link}">{link}</a></p>
</body>
</html>
"""
msg.add_alternative(html_content, subtype='html')

try:
    if server_port == 465:
        with smtplib.SMTP_SSL(server_host, server_port) as smtp:
            smtp.login(smtp_email, smtp_password)
            smtp.send_message(msg)
    else:
        with smtplib.SMTP(server_host, server_port) as smtp:
            smtp.starttls()
            smtp.login(smtp_email, smtp_password)
            smtp.send_message(msg)
    print("✅ 邮件发送成功")
except Exception as e:
    print(f"❌ 邮件发送失败: {e}")
    sys.exit(1)
EOF

exit $?
