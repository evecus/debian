#!/bin/bash

# 1. 设置 root 密码
if [ -z "$ssh_password" ]; then
  echo "root:debian12" | chpasswd
  echo "Warning: ssh_password not set, using default: debian12"
else
  echo "root:$ssh_password" | chpasswd
fi

# 2. 启动 SSH 服务
/usr/sbin/sshd

# 3. 自动后台运行 /usr/local/bin 中的其他二进制文件
# 遍历目录，如果是可执行文件且不是本脚本，则后台运行
for file in /usr/local/bin/*; do
    if [ -x "$file" ] && [ "$file" != "/usr/local/bin/entrypoint.sh" ]; then
        echo "Starting $file in background..."
        "$file" & 
    fi
done

# 4. 保持容器不退出
echo "Container is running..."
tail -f /dev/null
