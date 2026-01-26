FROM debian:13-slim

# 1. 设置环境变量：防止安装过程弹出交互对话框，并设置时区
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 2. 安装必要工具
# 添加 --no-install-recommends 可以减小体积
RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata \
    openssh-server \
    cron \
    wget \
    curl \
    nano \
    vim \
    iputils-ping \
    net-tools \
    procps \
    ca-certificates \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && mkdir /var/run/sshd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 3. 配置 SSH
RUN sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 4. 启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露端口与定义持久化目录
EXPOSE 22
VOLUME ["/root", "/opt", "/usr/local/bin"]

ENTRYPOINT ["/entrypoint.sh"]
