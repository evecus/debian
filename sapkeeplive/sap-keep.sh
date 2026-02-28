#!/bin/bash

# 颜色定义
green() { echo -e "\e[1;32m$1\033[0m"; }
red() { echo -e "\e[1;91m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }

# 自动获取并切换到第一个组织和空间
get_target_info() {
    ORG=$(cf orgs | sed -n '4p')
    SPACE=$(cf spaces | sed -n '4p')
    
    if [ -z "$ORG" ] || [ -z "$SPACE" ]; then
        red "未找到组织或空间信息"
        return 1
    fi
    cf target -o "$ORG" -s "$SPACE" >/dev/null 2>&1
}

# 核心重启函数
process_account() {
    local cur_email=$1
    local cur_pass=$2
    local regions=("US" "SG")
    local apis=("https://api.cf.us10-001.hana.ondemand.com" "https://api.cf.ap21.hana.ondemand.com")

    yellow "========================================"
    green "正在处理账号: $cur_email"
    
    for i in "${!regions[@]}"; do
        local region=${regions[$i]}
        local api=${apis[$i]}

        green "开始登录区域: $region"
        
        # 登录并静默错误
        cf login -a "$api" -u "$cur_email" -p "$cur_pass" >/dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            get_target_info
            # 获取应用列表
            APPS=$(cf apps | awk 'NR>3 {print $1}' | grep -v '^$')
            if [ -z "$APPS" ]; then
                yellow "[$region] 未发现运行中的应用"
            else
                for APP in $APPS; do
                    green "[$region] 正在重启: $APP"
                    cf restart "$APP"
                    sleep 5
                done
            fi
            cf logout
        else
            red "[$region] 登录失败，请检查账号密码"
        fi
    done
}

# --- 主程序逻辑 ---
echo "任务启动时间: $(date)"

# 将空格分隔的字符串转换为数组
read -a EMAIL_ARRAY <<< "$EMAIL"
read -a PASS_ARRAY <<< "$PASSWORD"

# 检查数组长度是否一致
if [ "${#EMAIL_ARRAY[@]}" -ne "${#PASS_ARRAY[@]}" ]; then
    red "错误：邮箱数量 (${#EMAIL_ARRAY[@]}) 与密码数量 (${#PASS_ARRAY[@]}) 不匹配！"
    exit 1
fi

# 循环处理每个账号
for i in "${!EMAIL_ARRAY[@]}"; do
    process_account "${EMAIL_ARRAY[$i]}" "${PASS_ARRAY[$i]}"
done

green "所有账号及区域处理完毕"
