# singargoless

基于 Alpine + [sing-box](https://github.com/SagerNet/sing-box) + [cloudflared](https://github.com/cloudflare/cloudflared) 构建的多协议代理服务端镜像，通过 Cloudflare Argo 隧道实现内网穿透，支持 VLESS+WS 协议，amd64 / arm64 多架构。

## 特性

- 基础镜像：Alpine 3.20（两阶段构建）
- 协议：VLESS + WebSocket，经由 Cloudflare Argo 隧道
- 构建时自动拉取 sing-box 和 cloudflared 最新 Release
- 无需公网 IP，通过 Argo Token 连接 Cloudflare 网络
- 启动后自动检测隧道连通性，成功后输出节点链接
- 支持 amd64 / arm64 多架构

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `UUID` | ✅ | VLESS 用户 UUID |
| `DOMAIN` | ✅ | Argo 隧道绑定的域名（如 `tunnel.example.com`） |
| `TOKEN` | ✅ | Cloudflare Argo 隧道 Token |
| `PORT` | 否 | sing-box 本地监听端口，默认 `8001` |

## 快速启动

```bash
docker run -d \
  -e UUID=your-uuid-here \
  -e DOMAIN=your.tunnel.domain \
  -e TOKEN=your_argo_tunnel_token \
  --name singargoless \
  evecus/singargoless
```

启动后查看节点链接：

```bash
docker logs singargoless
```

## Argo Token 获取方式

登录 [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) → Networks → Tunnels → 创建隧道 → 复制 Token。

## 端口

本镜像无需对外暴露端口，所有流量经由 Cloudflare Argo 隧道转发。
