# docker

一组自动化构建并发布到 Docker Hub 的镜像集合，包含通用容器环境、代理服务端和工具镜像。所有镜像通过 GitHub Actions 自动检测上游版本更新并触发多架构（amd64 / arm64）构建。

---

## 镜像列表

| 镜像 | 基础系统 | 用途 | 触发方式 |
|------|----------|------|----------|
| [alpine](./alpine/) | Alpine latest | 通用容器环境，内置 SSH / Cron | 手动 |
| [debian12](./debian12/) | Debian 12 Slim | 通用容器环境，内置 SSH / Cron | 手动 |
| [ubuntu](./ubuntu/) | Ubuntu 24.04 | 通用容器环境，内置 SSH / Cron | 手动 |
| [frps](./frps/) | Alpine | frp 服务端（frps），自动跟随最新版 | 定时 / 手动 |
| [singhy](./singhy/) | Alpine | sing-box Hysteria2 代理服务端 | 定时 / 手动 |
| [singargoless](./singargoless/) | Alpine 3.20 | sing-box VLESS+WS + Cloudflare Argo 隧道 | 定时 / 手动 |
| [singall](./singall/) | Alpine | sing-box 全协议合集（Hy2 / TUIC / VLESS / VMess / Reality） | 定时 / 手动 |
| [sapkeeplive](./sapkeeplive/) | Ubuntu | SAP BTP CF 应用定时保活 | 手动 |
| [cloudflared-web](./cloudflared-web/) | Alpine | Cloudflare Tunnel Web 管理界面 | 定时 / 手动 |

---

## 快速上手

### 通用环境（以 alpine 为例）

```bash
docker run -d \
  -p 22:22 \
  -e PASSWORD=yourpassword \
  -v /host/root:/root \
  --name alpine-env \
  evecus/alpine
```

### Hysteria2 代理（singhy）

```bash
docker run -d \
  -p 52233:52233/udp \
  -e PASSWORD=your_strong_password \
  --name singhy \
  evecus/singhy

docker logs singhy   # 查看节点链接
```

### 全协议代理（singall）

```bash
docker run -d \
  -p 52233:52233/udp \
  -e SELECTS=hysteria2,vless \
  -e UUID=your-uuid \
  -e PASSWORD=your_password \
  -e DOMAIN=your.tunnel.domain \
  -e TOKEN=your_argo_token \
  --name singall \
  evecus/singall
```

---

## GitHub Actions 自动构建

所有 Workflow 均位于 [`.github/workflows/`](./.github/workflows/)，使用 Docker Buildx 实现 `linux/amd64` 和 `linux/arm64` 多架构构建。

**版本检测策略：**

- `frps` / `singhy` / `singall` / `singargoless`：定时检测上游 GitHub Release，版本变化时自动触发构建，跳过无变化的重复构建
- `cloudflared-web`：每 5 天定时检查 cloudflared 版本并构建
- `alpine` / `debian12` / `ubuntu` / `sapkeeplive`：仅支持手动触发（`workflow_dispatch`）

**所需 GitHub Secrets：**

| Secret | 说明 |
|--------|------|
| `DOCKERHUB_USERNAME` | Docker Hub 用户名 |
| `DOCKERHUB_TOKEN` | Docker Hub Access Token（非登录密码） |

在仓库 Settings → Secrets and variables → Actions 中配置。

---

## 目录结构

```
.
├── alpine/               # Alpine 通用环境
├── debian12/             # Debian 12 通用环境
├── ubuntu/               # Ubuntu 24.04 通用环境
├── frps/                 # frp 服务端
├── singhy/               # Hysteria2 代理
├── singargoless/         # VLESS+Argo 代理
├── singall/              # 全协议代理
├── sapkeeplive/          # SAP BTP 保活
├── cloudflared-web/      # Cloudflare Tunnel 管理界面
└── .github/
    └── workflows/        # GitHub Actions 自动构建配置
```

---

## 注意事项

- 代理类镜像中默认密码 / UUID 仅供测试，**生产环境务必通过环境变量覆盖**。
- `sapkeeplive` 的 SAP BTP 账号密码通过环境变量明文传入，请勿将含密码的 `docker run` 命令提交至公开仓库。
- 所有涉及 Cloudflare Argo 的镜像需要有效的隧道 Token，请在 [Cloudflare Zero Trust](https://one.dash.cloudflare.com/) 控制台获取。
