FROM debian:12-slim

# 安装 SSH、Cron、常用网络工具和基础依赖
RUN apt-get update && apt-get install -y \
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
    && mkdir /var/run/sshd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 配置 SSH：允许 root 登录和密码认证
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 将启动脚本复制到根目录
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
COPY autostart /root/autostart
COPY cron /root/cron

# 暴露端口与定义持久化目录
EXPOSE 22
VOLUME ["/root"]

ENTRYPOINT ["/entrypoint.sh"]
