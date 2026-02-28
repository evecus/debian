# files-git

自动从 GitHub 仓库和/或指定 URL 拉取文件，通过 Nginx 提供只读文件浏览服务。浏览器可预览，`wget`/`curl` 直接可用，同一链接兼顾两者。

## 特性

- 基础镜像：`nginx:alpine`，镜像极小，内存占用低，多请求高并发
- 容器启动时立即同步一次，之后按定时任务重新全量同步
- 定时任务使用启动时读取的环境变量，运行中修改环境变量需重启容器生效
- 支持 amd64 / arm64 多架构

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `REPOSITORY` | 否 | GitHub 仓库地址，如 `https://github.com/user/repo` |
| `BRANCH` | 否 | 分支名，默认 `main`；填错则跳过仓库同步 |
| `URLS` | 否 | 空格分隔的 raw 文件链接，单个失败自动跳过 |
| `PATH_NAME` | 否 | URLS 下载到的子目录名；不填则放根目录 |
| `TIME` | 否 | 定时同步时间，北京时间 `HH:MM` 格式，默认 `12:00` |
| `CRON` | 否 | 标准 5 段 cron 表达式（UTC），优先级高于 `TIME` |

## 行为说明

- `REPOSITORY` + `BRANCH` 有效 → 克隆仓库，自动排除 `.github` 和 `README.md`
- `REPOSITORY` 有、`BRANCH` 填错 → 跳过仓库
- `URLS` 有、`PATH_NAME` 有 → 下载到 `/PATH_NAME/` 子目录
- `URLS` 有、`PATH_NAME` 无 → 下载到根目录
- 所有变量均可不填，容器正常启动，显示空目录

## 快速启动

```bash
docker run -d \
  -p 8080:8080 \
  -e REPOSITORY=https://github.com/用户名/仓库名 \
  -e BRANCH=main \
  -e URLS="https://example.com/file1.yaml https://example.com/file2.list" \
  -e PATH_NAME=extra \
  -e TIME=12:00 \
  -v /host/data:/data \
  --name files-git \
  evecus/files-git
```

## 文件访问

```bash
# wget 直接下载（原始内容）
wget http://your-server:8080/sing-box/rules.yaml

# curl
curl http://your-server:8080/mihomo/direct.list

# 浏览器访问目录列表
http://your-server:8080/
```

## 查看同步日志

```bash
docker exec rules-browser cat /data/sync.log
```

## 端口

| 端口 | 说明 |
|------|------|
| `8080` | Nginx 文件浏览 / 下载 |
