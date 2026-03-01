# ─── 第一阶段：下载 cloudflared ───────────────────────────────────────────────
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

# ─── 第二阶段：编译 Go fileserver ─────────────────────────────────────────────
FROM golang:alpine AS builder

WORKDIR /build
COPY go.mod .
COPY main.go .
COPY templates/ templates/

RUN go build -ldflags="-s -w" -o fileserver .

# ─── 第三阶段：运行镜像 ───────────────────────────────────────────────────────
FROM alpine:latest

RUN apk add --no-cache git wget cronie tzdata ca-certificates

# 默认时区，可通过 -e TZ=... 覆盖，entrypoint.sh 会在运行时应用
ENV TZ=Asia/Shanghai

COPY --from=fetcher /usr/local/bin/cloudflared /usr/local/bin/cloudflared
COPY --from=builder /build/fileserver /usr/local/bin/fileserver

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/data"]

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
