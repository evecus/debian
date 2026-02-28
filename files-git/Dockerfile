# ---------- 第一阶段：下载 cloudflared ----------
FROM alpine:latest AS fetcher

RUN apk add --no-cache curl

ARG TARGETARCH
RUN set -eux; \
    case "$TARGETARCH" in \
      amd64) CF_ARCH="amd64" ;; \
      arm64) CF_ARCH="arm64" ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac; \
    curl -fsSL -o /usr/local/bin/cloudflared \
      "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}"; \
    chmod +x /usr/local/bin/cloudflared

# ---------- 第二阶段：运行镜像 ----------
FROM nginx:alpine

RUN apk add --no-cache git wget cronie tzdata ca-certificates

ENV TZ=Asia/Shanghai
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# 从第一阶段拷贝 cloudflared
COPY --from=fetcher /usr/local/bin/cloudflared /usr/local/bin/cloudflared

# nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 前端页面（独立目录，不会被同步覆盖）
RUN mkdir -p /app
COPY index.html /app/index.html

# 启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/data"]

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
