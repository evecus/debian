# debian12

基于 `debian:12-slim` 构建的通用容器环境，内置 SSH、Cron、常用命令行工具，支持通过挂载卷持久化配置和自动加载启动任务。相比 Ubuntu 镜像体积更小，适合对镜像尺寸有要求同时又需要 Debian/glibc 生态的场景。

## 特性

- 基础镜像：Debian 12 Slim
- 开放 SSH（22 端口），支持 root 密码登录
- 内置 Cron 定时任务守护
- 支持通过 `/root/auto/cron` 自动加载定时任务
- 支持通过 `/root/auto/systemd` 自动后台启动自定义进程
- 时区：Asia/Shanghai

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PASSWORD` | `root` | root 用户 SSH 登录密码 |

## 快速启动

```bash
docker run -d \
  -p 22:22 \
  -e PASSWORD=yourpassword \
  --name debian12-env \
  evecus/debian12
```

## 持久化与自动任务

```bash
docker run -d \
  -p 22:22 \
  -e PASSWORD=yourpassword \
  -v /host/root:/root \
  -v /host/opt:/opt \
  -v /host/bin:/usr/local/bin \
  --name debian12-env \
  evecus/debian12
```

容器启动时会自动读取：

- `/root/auto/cron` — 标准 crontab 格式，自动加载为定时任务
- `/root/auto/systemd` — 每行一条 shell 命令，以后台进程方式启动

**cron 示例（`/root/auto/cron`）：**
```
0 3 * * * /usr/local/bin/backup.sh >> /root/backup.log 2>&1
```

**systemd 示例（`/root/auto/systemd`）：**
```
/usr/local/bin/myapp --port 8080
```

## 端口

| 端口 | 协议 | 说明 |
|------|------|------|
| `22` | TCP | SSH |
