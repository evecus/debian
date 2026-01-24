FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    ca-certificates \
    && mkdir /var/run/sshd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 将脚本放入 /usr/local/bin 方便管理
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22
VOLUME ["/root", "/usr/local/bin"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
