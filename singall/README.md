# singall

基于 Alpine + [sing-box](https://github.com/SagerNet/sing-box) + [cloudflared](https://github.com/cloudflare/cloudflared) 构建的全协议代理服务端镜像，单容器同时支持 Hysteria2、TUIC、VLESS+Argo、VMess+Argo、VLESS Reality 五种协议，按需启用，启动即输出所有节点链接。

## 特性

- 基础镜像：Alpine（两阶段构建）
- 一键部署，按 `SELECTS` 环境变量灵活组合启用协议
- 支持协议：Hysteria2 / TUIC v5 / VLESS+WS+Argo / VMess+WS+Argo / VLESS Reality
- 自动生成自签名证书（供 Hy2 / TUIC / Reality 使用）
- 支持 amd64 / arm64 多架构

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SELECTS` | 空（仅启动 Hysteria2） | 逗号分隔的协议名，可选值见下表 |
| `UUID` | 随机生成 | VLESS / VMess / TUIC 用户 UUID |
| `PASSWORD` | 随机生成 | Hysteria2 / TUIC 认证密码 |
| `DOMAIN` | — | Argo 协议必填，Cloudflare 隧道绑定域名 |
| `TOKEN` | — | Argo 协议必填，Cloudflare Argo 隧道 Token |
| `PORT` | 随机 | 通用端口（TUIC / VLESS Argo / VMess Argo / Reality） |
| `HPORT` | 随机 | Hysteria2 专用端口（优先级高于 PORT） |
| `LPORT` | `1080` | VLESS+Argo 本地监听端口 |
| `MPORT` | `8001` | VMess+Argo 本地监听端口 |

### SELECTS 可选值

| 值 | 协议 |
|----|------|
| `hysteria2` | Hysteria2（默认，SELECTS 为空时自动启用） |
| `tuic` | TUIC v5 |
| `vless` | VLESS + WebSocket + Argo 隧道 |
| `vmess` | VMess + WebSocket + Argo 隧道 |
| `reality` | VLESS + Reality |

多协议示例：`SELECTS=hysteria2,tuic,vless`

## 快速启动

**仅 Hysteria2（最简）：**
```bash
docker run -d \
  -p 52233:52233/udp \
  -e PASSWORD=your_password \
  --name singall \
  evecus/singall
```

**多协议（含 Argo）：**
```bash
docker run -d \
  -p 52233:52233/udp \
  -e SELECTS=hysteria2,vless,vmess \
  -e UUID=your-uuid \
  -e PASSWORD=your_password \
  -e DOMAIN=your.tunnel.domain \
  -e TOKEN=your_argo_token \
  --name singall \
  evecus/singall
```

启动后查看所有节点链接：

```bash
docker logs singall
```

## 端口

Argo 协议无需暴露端口，其余协议按实际设置的端口映射即可。

| 协议 | 默认端口 | 传输层 |
|------|----------|--------|
| Hysteria2 | 随机（可用 `HPORT` 指定） | UDP |
| TUIC | 随机（可用 `PORT` 指定） | UDP |
| VLESS Reality | 随机（可用 `PORT` 指定） | TCP |
| VLESS/VMess Argo | 无需暴露 | — |
