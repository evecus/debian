FROM --platform=$TARGETPLATFORM ubuntu:latest

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

# 安装依赖
RUN apt-get update && apt-get install -y \
    curl wget ca-certificates tzdata cron \
    && rm -rf /var/lib/apt/lists/*

# 设置上海时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/Shanghai" > /etc/timezone

# 安装 CF CLI
RUN if [ "$TARGETARCH" = "amd64" ]; then ARCH="x86-64"; else ARCH="arm64"; fi && \
    LATEST_TAG=$(curl -s https://api.github.com/repos/cloudfoundry/cli/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    LATEST_VERSION=${LATEST_TAG#v} && \
    wget -O /tmp/cf.deb "https://github.com/cloudfoundry/cli/releases/download/${LATEST_TAG}/cf8-cli-installer_${LATEST_VERSION}_${ARCH}.deb" && \
    dpkg -i /tmp/cf.deb && rm /tmp/cf.deb

COPY sapkeeplive/sap-keep.sh /usr/local/bin/sap-keep.sh
RUN chmod +x /usr/local/bin/sap-keep.sh

# 初始化日志
RUN touch /var/log/cron.log

# 这里的 CMD 逻辑非常关键：它会在启动时解析 TIME 变量并创建 Cron 任务
CMD ["sh", "-c", "\
    printenv > /etc/environment && \
    MINUTE=$(echo ${TIME:-08:30} | cut -d':' -f2) && \
    HOUR=$(echo ${TIME:-08:30} | cut -d':' -f1) && \
    echo \"$MINUTE $HOUR * * * . /etc/environment; /bin/bash /usr/local/bin/sap-keep.sh >> /var/log/cron.log 2>&1\" > /etc/cron.d/sap-cron && \
    chmod 0644 /etc/cron.d/sap-cron && \
    crontab /etc/cron.d/sap-cron && \
    echo \"Cron task set for $HOUR:$MINUTE\" && \
    cron && \
    tail -f /var/log/cron.log"]
