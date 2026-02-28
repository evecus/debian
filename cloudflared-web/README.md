# cloudflared-web

基于 Alpine + Go + [cloudflared](https://github.com/cloudflare/cloudflared) 构建的 Cloudflare Tunnel 可视化管理工具，提供一个轻量 Web 界面用于管理和监控 Cloudflare 隧道，支持 amd64 / arm64 多架构。

## 特性

- 基础镜像：Alpine（Go 交叉编译 + 两阶段构建，体积极小）
- 提供 Web UI 管理 Cloudflare Tunnel
- 自动拉取最新版 cloudflared 二进制
- 支持 amd64 / arm64 多架构

## 快速启动

```bash
docker run -d \
  -p 12222:12222 \
  --name cloudflared-web \
  evecus/cloudflared-web
```

访问 `http://your-server-ip:12222` 打开管理界面。

## 端口

| 端口 | 协议 | 说明 |
|------|------|------|
| `12222` | TCP | Web 管理界面 |
