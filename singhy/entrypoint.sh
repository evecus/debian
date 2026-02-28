#!/bin/bash

# 检查必要变量
if [ -z "$PASSWORD" ]; then
    echo "错误: 请设置 PASSWORD 环境变量。"
    exit 1
fi

PORT=52233
SNI="www.bing.com"

# 1. 生成自签名证书 (Hysteria2 必须)
# 即使客户端忽略证书，服务端也必须持有证书才能启动 TLS
openssl req -x509 -nodes -newkey rsa:2048 -keyout /tmp/server.key -out /tmp/server.crt -days 3650 -subj "/CN=bing.com" > /dev/null 2>&1

# 2. 生成 sing-box 配置文件
cat <<EOF > /etc/sing-box.json
{
  "log": { "level": "warn", "timestamp": true },
  "inbounds": [
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": ${PORT},
      "users": [ { "password": "${PASSWORD}" } ],
      "tls": {
        "enabled": true,
        "server_name": "${SNI}",
        "certificate_path": "/tmp/server.crt",
        "key_path": "/tmp/server.key"
      }
    }
  ],
  "outbounds": [{ "type": "direct", "tag": "direct" }]
}
EOF

# 3. 获取外网 IP
IP=$(curl -s https://api.ipify.org || echo "YOUR_SERVER_IP")

# 4. 生成 Hysteria2 链接
# 格式: hysteria2://password@ip:port?insecure=1&sni=www.bing.com#Name
HY2_LINK="hysteria2://${PASSWORD}@${IP}:${PORT}?insecure=1&sni=${SNI}#Hy2-${IP}"

# 5. 输出日志
echo "---------------------------------------------------"
echo "🚀 Hysteria2 服务已启动"
echo "监听端口: ${PORT} (UDP)"
echo "SNI 伪装: ${SNI}"
echo "---------------------------------------------------"
echo "Hysteria2 节点链接:"
echo "${HY2_LINK}"
echo "---------------------------------------------------"

# 6. 静默运行 sing-box
sing-box run -c /etc/sing-box.json > /dev/null 2>&1
