FROM debian:12-slim

# 安装 SSH、Cron 和常用网络调试工具
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

# 配置 SSH：允许 root 登录及密码认证
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 将启动脚本拷贝至根目录（避免被挂载覆盖）
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露 SSH 默认端口
EXPOSE 22

# 声明持久化挂载点
VOLUME ["/root"]

# 设置入口脚本
ENTRYPOINT ["/entrypoint.sh"]
