# files-git

一个基于 Nginx 的轻量文件服务容器，自动从 GitHub 仓库或 URL 同步文件，通过浏览器 SPA 界面提供文件浏览与预览，同时支持 `wget`/`curl` 直接下载原始文件。提供两个版本：内置 Cloudflare Argo 隧道（`argo`）和不含隧道的精简版（`no`）。

---

## 特性

- **文件浏览**：暗色主题 SPA，目录导航、面包屑、文件列表
- **文件预览**：文本文件行号显示、500KB 以上提示下载、二进制文件自动触发下载
- **多仓库同步**：支持同时同步多个 GitHub 仓库，单仓库放根目录，多仓库自动建子目录
- **定时同步**：支持 `TIME`（本地时间）或 `CRON` 表达式，时区统一按 `TZ` 解释
- **同步状态显示**：同步进行中网页显示半透明等待覆盖层，完成后自动刷新
- **Cloudflare Argo 隧道**：`argo` 版内置 `cloudflared`，无需公网 IP 即可暴露服务

---

## 镜像版本

| 标签 | 说明 |
|------|------|
| `evecus/files-git:argo` | 内置 cloudflared，支持 CF 隧道 |
| `evecus/files-git:no` | 精简版，无 cloudflared |

---

## 快速开始

```bash
# argo 版（支持 Cloudflare 隧道）
docker run -d \
  -p 8080:8080 \
  -e REPOSITORIES="github用户名/仓库名/分支 github用户名/仓库名/分支" \
  -v /host/data:/data \
  --name files-git \
  evecus/files-git:argo

# 精简版
docker run -d \
  -p 8080:8080 \
  -e REPOSITORIES="github用户名/仓库名/分支 github用户名/仓库名/分支" \
  -v /host/data:/data \
  --name files-git \
  evecus/files-git:no
```

访问 `http://localhost:8080` 即可查看文件列表。

---

## 环境变量

| 变量 | 默认值 | 说明 | 仅 argo 版 |
|------|--------|------|-----------|
| `TZ` | `Asia/Shanghai` | 时区，影响容器系统时间、`TIME` 和 `CRON` 的解释 | |
| `REPOSITORIES` | 空 | 要同步的 GitHub 仓库，空格分隔，格式见下方 | |
| `URLS` | 空 | 要下载的文件直链，空格分隔 | |
| `PATH_NAME` | 空 | `URLS` 下载到的子目录，不填放根目录 | |
| `TIME` | `12:00` | 定时同步时间，按 `TZ` 时区解释，格式 `HH:MM` | |
| `CRON` | 空 | 5 段 cron 表达式，按 `TZ` 时区解释，优先级高于 `TIME` | |
| `CF` | 空 | 设为 `true` 时启动 Cloudflare Argo 隧道 | ✓ |
| `TOKEN` | 空 | Cloudflare Tunnel token | ✓ |

> 所有变量均可不填，容器会以默认值正常启动，显示空文件列表。

---

## REPOSITORIES 格式

```
用户名/仓库名
用户名/仓库名/分支
```

多个仓库用空格分隔：

```bash
# 单仓库，分支默认 main，文件放根目录
-e REPOSITORIES="github用户名/仓库名"

# 单仓库，指定分支
-e REPOSITORIES="github用户名/仓库名/分支"

# 多仓库，每个仓库放到 仓库名/分支/ 子目录
-e REPOSITORIES="github用户名/仓库名/分支1 github用户名/仓库名/分支2"
```

**目录结构示例（多仓库）：**

```
/data/files/
├── rules_set/
│   └── main/
│       ├── mihomo/
│       └── sing-box/
└── tv/
    └── main/
        └── tv.json
```

---

## 同步逻辑

| 情况 | 行为 |
|------|------|
| 首次启动 | 强制同步 |
| 重启，`REPOSITORIES`/`URLS`/`PATH_NAME` 未变 | 跳过同步 |
| 重启，以上任一变量有变化 | 触发同步 |
| 修改 `TIME`/`CRON`/`TZ`/`CF`/`TOKEN` 后重启 | 跳过同步（不参与 hash） |
| 到达 cron 设定时间 | 无条件全量同步 |

手动触发同步：

```bash
docker exec <容器名> /bin/sh /sync.sh
```

---

## 数据目录

挂载 `-v /host/data:/data` 后目录结构：

```
/data/
├── files/          # 同步的文件，Nginx 对外提供服务
├── .env_hash       # 环境变量指纹，用于判断是否需要重新同步
├── .env_cache      # 运行时参数缓存，供 cron 任务读取
├── .syncing        # 同步进行中时存在，完成后删除
├── .last_update    # 最后同步完成时间
├── sync.log        # cron 定时同步日志
└── cloudflared.log # Cloudflare 隧道日志（argo 版启用时）
```

> 不挂载 `-v` 也可运行，但容器重启后同步的文件会丢失。

---

## 进程结构

```
# argo 版
PID 1  nginx          ← 主进程，容器存活锚点
PID x  crond          ← 后台，定时触发同步
PID y  cloudflared    ← 后台，可选

# no 版
PID 1  nginx          ← 主进程
PID x  crond          ← 后台，定时触发同步
```

---

## Nginx 路由说明

| 路径 | 说明 |
|------|------|
| `/<文件路径>` | 原始文件内容（`wget`/`curl` 直接用） |
| `/__api__/<路径>` | 目录 JSON 列表，供前端渲染 |
| `/__raw__/<路径>` | 强制 `text/plain` 返回，供前端文本预览 |
| `/__last_update__` | 返回最后同步时间文本 |
| `/__syncing__` | 同步中文件存在返回内容，否则 404 |
| `/healthz` | 健康检查，返回 `ok` |

---

## 构建镜像

```bash
# argo 版
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t evecus/files-git:argo \
  --push .

# no 版
docker buildx build \
  -f Dockerfile_no \
  --platform linux/amd64,linux/arm64 \
  -t evecus/files-git:no \
  --push .
```
