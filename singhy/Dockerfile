FROM alpine:latest AS builder
RUN apk add --no-cache curl
RUN SB_VERSION=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/v//') && \
    curl -Lo /tmp/sing-box.tar.gz https://github.com/SagerNet/sing-box/releases/download/v${SB_VERSION}/sing-box-${SB_VERSION}-linux-amd64.tar.gz && \
    tar -xzf /tmp/sing-box.tar.gz -C /tmp && \
    mv /tmp/sing-box-*/sing-box /usr/local/bin/

FROM alpine:latest
# 安装 openssl 用于生成证书, curl 用于获取 IP
RUN apk add --no-cache bash curl openssl
COPY --from=builder /usr/local/bin/sing-box /usr/local/bin/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV PASSWORD=""

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
