# ---------- 第一阶段：下载器 ----------
FROM alpine:latest AS fetcher

RUN apk add --no-cache curl tar

ARG TARGETARCH
# 转换架构名称以匹配 frp 的发布命名格式
RUN set -eux; \
    case "$TARGETARCH" in \
      amd64) ARCH=amd64 ;; \
      arm64) ARCH=arm64 ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac; \
    # 获取最新版本号
    VERSION=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/'); \
    # 下载并解压
    curl -Lo /tmp/frp.tar.gz https://github.com/fatedier/frp/releases/download/v${VERSION}/frp_${VERSION}_linux_${ARCH}.tar.gz; \
    tar -xzf /tmp/frp.tar.gz -C /tmp; \
    mv /tmp/frp_${VERSION}_linux_${ARCH}/frps /usr/local/bin/frps

# ---------- 第二阶段：运行镜像 ----------
FROM alpine:3.19

RUN apt-get update && apt-get install -y ca-certificates && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 从下载器阶段拷贝二进制文件
COPY --from=fetcher /usr/local/bin/frps /app/frps
RUN chmod +x /app/frps

# 拷贝你仓库里的配置文件和脚本
COPY frps/frps.toml /app/frps.toml
COPY frps/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8008

ENTRYPOINT ["/entrypoint.sh"]
