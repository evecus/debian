#!/bin/bash

# --- 1. 设置 Root 密码 ---
if [ -z "$ssh_password" ]; then
    echo "root:root" | chpasswd
    echo "Warning: No ssh_password environment variable found, using default: root"
else
    echo "root:$ssh_password" | chpasswd
    echo "Success: Root password updated."
fi

# --- 2. 启动核心服务 ---
# 启动 SSH 服务
/usr/sbin/sshd

# --- 3. 处理定时任务 (加载 /root/cron) ---
if [ -f "/root/cron" ]; then
    echo "Checking /root/cron..."
    # 移除 Windows 换行符
    sed -i 's/\r$//' /root/cron
    chmod 600 /root/cron
    crontab /root/cron
    echo "Cron tasks loaded."
else
    echo "Notice: /root/cron not found, skipping."
fi
# 启动定时任务守护进程
service cron start

# --- 4. 启动后台常驻任务 (加载 /root/autostart) ---
if [ -f "/root/autostart" ]; then
    echo "Reading /root/autostart list..."
    while IFS= read -r line || [[ -n "$line" ]]; do
        # 移除回车符，并过滤注释(#)和空行
        line=$(echo "$line" | sed 's/\r$//')
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        
        echo "Launching in background: $line"
        eval "$line" &
    done < "/root/autostart"
else
    echo "Notice: /root/autostart not found, skipping."
fi

# --- 5. 保持容器前台运行 ---
echo "Debian 12 environment is ready."
# 打印已加载的定时任务供检查
crontab -l 2>/dev/null || echo "No active cron jobs."

# 阻塞主进程
tail -f /dev/null
