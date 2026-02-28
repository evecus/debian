# singhy

基于 Alpine + [sing-box](https://github.com/SagerNet/sing-box) 构建的 Hysteria2 代理服务端镜像，自动生成自签名证书，启动即输出可用节点链接，支持 amd64 / arm64 多架构。

## 特性

- 基础镜像：Alpine（两阶段构建）
- 构建时自动拉取 sing-box 最新 Release
- 协议：Hysteria2（UDP）
- 自动生成自签名 TLS 证书（SNI 伪装为 `www.bing.com`）
- 启动后控制台打印完整 Hysteria2 节点链接，直接复制使用
- 支持 amd64 / arm64 多架构

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PASSWORD` | `jiend329ie2ek2okq` | Hysteria2 认证密码，**强烈建议修改** |

## 快速启动

```bash
docker run -d \
  -p 52233:52233/udp \
  -e PASSWORD=your_strong_password \
  --name singhy \
  evecus/singhy
```

启动后查看控制台日志获取节点链接：

```bash
docker logs singhy
```

输出示例：
```
---------------------------------------------------
🚀 Hysteria2 服务已启动
监听端口: 52233 (UDP)
SNI 伪装: www.bing.com
---------------------------------------------------
Hysteria2 节点链接:
hysteria2://your_password@1.2.3.4:52233?insecure=1&sni=www.bing.com#Hy2-1.2.3.4
---------------------------------------------------
```

## 端口

| 端口 | 协议 | 说明 |
|------|------|------|
| `52233` | UDP | Hysteria2 监听端口 |

## 客户端配置

将日志中输出的 `hysteria2://` 链接导入支持 Hysteria2 的客户端（如 Clash Meta、NekoBox、sing-box 客户端等）即可使用。由于使用自签名证书，客户端需开启 `insecure=1`（链接中已包含）。
