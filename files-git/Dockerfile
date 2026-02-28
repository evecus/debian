FROM nginx:alpine

# 安装依赖：git（克隆仓库）、wget（下载URLs）、cronie（定时任务）、tzdata（时区）
RUN apk add --no-cache git wget cronie tzdata ca-certificates

ENV TZ=Asia/Shanghai
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

# 替换 nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 数据持久化目录
VOLUME ["/data"]

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
