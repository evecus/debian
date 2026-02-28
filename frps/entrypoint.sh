#!/bin/bash

# 配置文件路径
CONF="/app/frps.toml"

# 如果设置了名为 token 的环境变量，则修改配置文件
if [ ! -z "$token" ]; then
    echo "检测到环境变量 token，正在同步至配置文件..."
    # 移除可能存在的 Windows 换行符并替换 token
    sed -i 's/\r$//' "$CONF"
    sed -i "s/auth.token = .*/auth.token = \"$token\"/" "$CONF"
else
    echo "未检测到 token 变量，使用配置文件默认值。"
fi

echo "正在启动 frps..."
# 使用 exec 确保 frps 能够接收到 Docker 的停止信号
exec /app/frps -c "$CONF"
