#!/bin/sh

DATA_DIR="/data/files"
ENV_CACHE="/data/.env_cache"
ENV_HASH_FILE="/data/.env_hash"

# ─── 1. 读取并校验环境变量 ───────────────────────────────────────────────────

REPOSITORY="${REPOSITORY:-}"
BRANCH="${BRANCH:-main}"
URLS="${URLS:-}"
PATH_NAME="${PATH_NAME:-}"
TIME="${TIME:-12:00}"
CRON_ENV="${CRON:-}"

CF="${CF:-}"
TOKEN="${TOKEN:-}"

is_valid_cron() {
    echo "$1" | grep -qE '^(\*|[0-9,-/]+) (\*|[0-9,-/]+) (\*|[0-9,-/]+) (\*|[0-9,-/]+) (\*|[0-9,-/]+)$'
}
is_valid_time() {
    echo "$1" | grep -qE '^([01][0-9]|2[0-3]):[0-5][0-9]$'
}

if is_valid_cron "$CRON_ENV"; then
    FINAL_CRON="$CRON_ENV"
    echo "[init] 使用 CRON 环境变量: $FINAL_CRON"
elif is_valid_time "$TIME"; then
    HOUR=$(echo "$TIME" | cut -d: -f1)
    MINUTE=$(echo "$TIME" | cut -d: -f2)
    UTC_HOUR=$(( (HOUR - 8 + 24) % 24 ))
    FINAL_CRON="$MINUTE $UTC_HOUR * * *"
    echo "[init] 使用 TIME=$TIME -> cron UTC: $FINAL_CRON"
else
    FINAL_CRON="0 4 * * *"
    echo "[init] TIME 格式无效，使用默认 12:00 北京时间 -> cron: $FINAL_CRON"
fi

# ─── 2. 检测环境变量是否变化（只对同步相关变量做哈希）───────────────────────

mkdir -p "$DATA_DIR"

# 用同步相关变量生成指纹（CRON/TIME/CF/TOKEN 变化不触发同步）
CURRENT_HASH=$(printf '%s\n' "$REPOSITORY" "$BRANCH" "$URLS" "$PATH_NAME" | md5sum | cut -d' ' -f1)
OLD_HASH=$(cat "$ENV_HASH_FILE" 2>/dev/null || echo "")

# 将运行时参数写入缓存（cron 从这里读）
cat > "$ENV_CACHE" << EOF
REPOSITORY='$REPOSITORY'
BRANCH='$BRANCH'
URLS='$URLS'
PATH_NAME='$PATH_NAME'
FINAL_CRON='$FINAL_CRON'
EOF

# ─── 3. 按需同步 ─────────────────────────────────────────────────────────────

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

    TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S' > /data/.last_update
    echo "[sync] ===== 同步完成 ====="
}

if [ "$CURRENT_HASH" != "$OLD_HASH" ]; then
    echo "[init] 环境变量已变化，触发同步..."
    do_sync
    echo "$CURRENT_HASH" > "$ENV_HASH_FILE"
else
    echo "[init] 环境变量未变化，跳过同步"
fi

# ─── 4. 注册 cron 定时任务 ───────────────────────────────────────────────────

cat > /sync.sh << 'SYNCEOF'
#!/bin/sh
DATA_DIR="/data/files"
ENV_CACHE="/data/.env_cache"
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

    TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S' > /data/.last_update
    echo "[sync] ===== 同步完成 ====="
}

do_sync
SYNCEOF
chmod +x /sync.sh

echo "$FINAL_CRON /bin/sh /sync.sh >> /data/sync.log 2>&1" > /etc/crontabs/root
echo "[init] cron 已注册: $FINAL_CRON"

crond

# ─── 5. 启动 Cloudflare Argo 隧道（可选）────────────────────────────────────

if [ "$CF" = "true" ] && [ -n "$TOKEN" ]; then
    echo "[init] 启动 Cloudflare Argo 隧道..."
    cloudflared tunnel --no-autoupdate run --token "$TOKEN" > /data/cloudflared.log 2>&1 &
    echo "[init] Argo 隧道已在后台启动"
else
    echo "[init] 未启用 Argo 隧道（CF!=true 或 TOKEN 未设置）"
fi

# ─── 6. 启动 Nginx（前台）───────────────────────────────────────────────────

echo "[init] 启动 Nginx..."
exec nginx -g "daemon off;"
