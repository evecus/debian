FROM nginx:alpine

RUN apk add --no-cache git wget cronie tzdata ca-certificates

ENV TZ=Asia/Shanghai
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

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
