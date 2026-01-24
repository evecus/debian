#!/bin/bash

# 1. 设置 root 密码
if [ -z "$ssh_password" ]; then
    # 若未设置环境变量，则使用默认密码 root
    echo "root:root" | chpasswd
    echo "Warning: ssh_password is not set, using default: root"
else
    echo "root:$ssh_password" | chpasswd
    echo "Success: Password set from environment variable."
fi

# 2. 启动 SSH 服务
/usr/sbin/sshd

# 3. 自动加载 Cron 定时任务
# 逻辑：如果挂载的 /root 目录下有 crontab.txt，则将其导入系统定时任务
if [ -f "/root/crontab.txt" ]; then
    echo "Loading custom cron tasks from /root/crontab.txt..."
    chmod 600 /root/crontab.txt
    crontab /root/crontab.txt
fi
# 启动 cron 服务
service cron start

# 4. 后台执行二进制文件
# 逻辑：自动运行 /root/bin 目录下所有具备可执行权限的文件
if [ -d "/root/bin" ]; then
    echo "Scanning /root/bin for binaries to start..."
    for file in /root/bin/*; do
        if [ -f "$file" ] && [ -x "$file" ]; then
            echo "Starting background process: $file"
            "$file" &
        fi
    done
fi

# 5. 保持容器后台运行
echo "Debian 12 environment is ready."
tail -f /dev/null
