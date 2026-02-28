# frps

基于 Alpine 构建的 [frp](https://github.com/fatedier/frp) 服务端（frps）镜像，自动获取最新版本，支持多架构（amd64 / arm64），体积极小。

## 特性

- 基础镜像：Alpine（两阶段构建，最终镜像仅含 frps 二进制）
- 构建时自动拉取 frp 最新 Release
- 支持通过环境变量 `token` 覆盖认证令牌
- 内置 Web 管理面板（7500 端口）
- 支持 amd64 / arm64 多架构

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `token` | 见 frps.toml | 客户端连接认证令牌，设置后自动写入配置 |

## 快速启动

```bash
docker run -d \
  -p 8008:8008 \
  -p 7500:7500 \
  -e token=your_secret_token \
  --name frps \
  evecus/frps
```

## 默认配置（frps.toml）

| 项目 | 值 |
|------|----|
| 绑定端口 | `8008` |
| Web 面板端口 | `7500` |
| Web 面板账号 | `admin` / `admin` |
| 认证方式 | token |

如需自定义更多配置，可挂载自己的配置文件：

```bash
docker run -d \
  -p 8008:8008 \
  -p 7500:7500 \
  -v /host/frps.toml:/app/frps.toml \
  --name frps \
  evecus/frps
```

## 端口

| 端口 | 协议 | 说明 |
|------|------|------|
| `8008` | TCP | frp 客户端连接端口 |
| `7500` | TCP | Web 管理面板 |
