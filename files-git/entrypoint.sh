#!/bin/sh

DATA_DIR="/data/files"
ENV_CACHE="/data/.env_cache"
NGINX_ROOT="/usr/share/nginx/html"

# ─── 1. 读取并校验环境变量（只在启动时执行一次）───────────────────────────

REPOSITORY="${REPOSITORY:-}"
BRANCH="${BRANCH:-main}"
URLS="${URLS:-}"
PATH_NAME="${PATH_NAME:-}"
TIME="${TIME:-12:00}"
CRON_ENV="${CRON:-}"

# 校验 CRON 表达式（5段，每段合法字符）
is_valid_cron() {
    echo "$1" | grep -qE '^(\*|[0-9,-/]+) (\*|[0-9,-/]+) (\*|[0-9,-/]+) (\*|[0-9,-/]+) (\*|[0-9,-/]+)$'
}

# 校验 TIME 格式 HH:MM
is_valid_time() {
    echo "$1" | grep -qE '^([01][0-9]|2[0-3]):[0-5][0-9]$'
}

# 确定最终 cron 表达式（UTC时间存储）
if is_valid_cron "$CRON_ENV"; then
    FINAL_CRON="$CRON_ENV"
    echo "[init] 使用 CRON 环境变量: $FINAL_CRON"
elif is_valid_time "$TIME"; then
    HOUR=$(echo "$TIME" | cut -d: -f1)
    MINUTE=$(echo "$TIME" | cut -d: -f2)
    # 北京时间转 UTC（减8小时）
    UTC_HOUR=$(( (HOUR - 8 + 24) % 24 ))
    FINAL_CRON="$MINUTE $UTC_HOUR * * *"
    echo "[init] 使用 TIME=$TIME -> cron UTC: $FINAL_CRON"
else
    FINAL_CRON="0 4 * * *"
    echo "[init] TIME 格式无效，使用默认 12:00 北京时间 -> cron: $FINAL_CRON"
fi

# 将运行时参数写入缓存（cron 任务从这里读，不再读环境变量）
mkdir -p "$DATA_DIR"
cat > "$ENV_CACHE" << EOF
REPOSITORY='$REPOSITORY'
BRANCH='$BRANCH'
URLS='$URLS'
PATH_NAME='$PATH_NAME'
FINAL_CRON='$FINAL_CRON'
EOF

echo "[init] 环境变量已缓存到 $ENV_CACHE"

# ─── 2. 核心同步函数 ────────────────────────────────────────────────────────

do_sync() {
    # 从缓存读取参数
    . "$ENV_CACHE"

    echo "[sync] ===== 开始同步 $(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S') ====="

    # 清空数据目录
    rm -rf "${DATA_DIR:?}"/*
    mkdir -p "$DATA_DIR"

    # ── 2a. 拉取仓库 ──
    if [ -n "$REPOSITORY" ]; then
        # 校验 BRANCH 是否存在（git ls-remote 检测）
        echo "[sync] 检测仓库分支: $REPOSITORY @ $BRANCH"
        if git ls-remote --exit-code --heads "$REPOSITORY" "$BRANCH" > /dev/null 2>&1; then
            TMP=$(mktemp -d)
            echo "[sync] 克隆仓库..."
            if git clone --depth=1 --branch "$BRANCH" "$REPOSITORY" "$TMP" 2>&1; then
                find "$TMP" -mindepth 1 -maxdepth 1 \
                    ! -name ".github" \
                    ! -name "README.md" \
                    ! -name ".git" \
                    -exec cp -r {} "$DATA_DIR/" \;
                echo "[sync] 仓库同步完成"
            else
                echo "[sync] 仓库克隆失败，跳过"
            fi
            rm -rf "$TMP"
        else
            echo "[sync] 分支 '$BRANCH' 不存在或仓库地址错误，跳过"
        fi
    else
        echo "[sync] 未设置 REPOSITORY，跳过仓库同步"
    fi

    # ── 2b. 下载 URLs ──
    if [ -n "$URLS" ]; then
        if [ -n "$PATH_NAME" ]; then
            DEST="$DATA_DIR/$PATH_NAME"
        else
            DEST="$DATA_DIR"
        fi
        mkdir -p "$DEST"
        echo "[sync] 下载 URLs 到 $DEST"

        for url in $URLS; do
            filename=$(basename "$url" | cut -d'?' -f1)
            echo "[sync] 下载: $url"
            if wget -q --timeout=15 --tries=2 -O "$DEST/$filename" "$url" 2>&1; then
                echo "[sync] ✓ $filename"
            else
                rm -f "$DEST/$filename"
                echo "[sync] ✗ 跳过: $url"
            fi
        done
    else
        echo "[sync] 未设置 URLS，跳过文件下载"
    fi

    # 软链到 nginx 根目录
    rm -rf "$NGINX_ROOT"
    ln -sf "$DATA_DIR" "$NGINX_ROOT"

    TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S' > /data/.last_update
    echo "[sync] ===== 同步完成 ====="
}

# ─── 3. 立即执行一次同步 ────────────────────────────────────────────────────

do_sync

# ─── 4. 注册 cron 定时任务 ──────────────────────────────────────────────────

# 将 do_sync 逻辑写成独立脚本供 cron 调用
cat > /sync.sh << 'SYNCEOF'
#!/bin/sh
DATA_DIR="/data/files"
ENV_CACHE="/data/.env_cache"
NGINX_ROOT="/usr/share/nginx/html"
. "$ENV_CACHE"

do_sync() {
    echo "[sync] ===== 开始同步 $(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S') ====="
    rm -rf "${DATA_DIR:?}"/*
    mkdir -p "$DATA_DIR"

    if [ -n "$REPOSITORY" ]; then
        echo "[sync] 检测仓库分支: $REPOSITORY @ $BRANCH"
        if git ls-remote --exit-code --heads "$REPOSITORY" "$BRANCH" > /dev/null 2>&1; then
            TMP=$(mktemp -d)
            if git clone --depth=1 --branch "$BRANCH" "$REPOSITORY" "$TMP" 2>&1; then
                find "$TMP" -mindepth 1 -maxdepth 1 \
                    ! -name ".github" ! -name "README.md" ! -name ".git" \
                    -exec cp -r {} "$DATA_DIR/" \;
                echo "[sync] 仓库同步完成"
            else
                echo "[sync] 克隆失败，跳过"
            fi
            rm -rf "$TMP"
        else
            echo "[sync] 分支不存在或仓库地址错误，跳过"
        fi
    fi

    if [ -n "$URLS" ]; then
        if [ -n "$PATH_NAME" ]; then DEST="$DATA_DIR/$PATH_NAME"; else DEST="$DATA_DIR"; fi
        mkdir -p "$DEST"
        for url in $URLS; do
            filename=$(basename "$url" | cut -d'?' -f1)
            if wget -q --timeout=15 --tries=2 -O "$DEST/$filename" "$url"; then
                echo "[sync] ✓ $filename"
            else
                rm -f "$DEST/$filename"
                echo "[sync] ✗ 跳过: $url"
            fi
        done
    fi

    rm -rf "$NGINX_ROOT"
    ln -sf "$DATA_DIR" "$NGINX_ROOT"
    TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S' > /data/.last_update
    echo "[sync] ===== 同步完成 ====="
}

do_sync
SYNCEOF
chmod +x /sync.sh

# 写入 crontab
echo "$FINAL_CRON /bin/sh /sync.sh >> /data/sync.log 2>&1" > /etc/crontabs/root
echo "[init] cron 已注册: $FINAL_CRON"

# 启动 cron 守护
crond

# ─── 5. 启动 Nginx（前台）───────────────────────────────────────────────────

echo "[init] 启动 Nginx..."
exec nginx -g "daemon off;"
