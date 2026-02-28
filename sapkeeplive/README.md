# sapkeeplive

基于 Ubuntu 构建的 SAP BTP (Cloud Foundry) 应用保活容器，通过定时 Cron 任务定期重启指定账号下的所有 CF 应用，防止因平台休眠策略导致应用停止。支持多账号、多区域（US / SG）批量处理。

## 特性

- 自动按计划时间重启 SAP BTP Cloud Foundry 上的所有应用
- 支持多账号批量处理（空格分隔）
- 覆盖 US（us10）和 SG（ap21）两个区域
- 通过环境变量 `TIME` 灵活设置每日执行时间
- 运行日志持久输出至 `/var/log/cron.log`

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `EMAIL` | ✅ | SAP BTP 账号邮箱，多个账号用空格分隔 |
| `PASSWORD` | ✅ | 对应账号密码，顺序须与 EMAIL 一致，空格分隔 |
| `TIME` | 否 | 每日执行时间，格式 `HH:MM`（UTC+8），默认 `08:30` |

## 快速启动

**单账号：**
```bash
docker run -d \
  -e EMAIL=user@example.com \
  -e PASSWORD=your_password \
  -e TIME=09:00 \
  --name sapkeeplive \
  evecus/sapkeeplive
```

**多账号：**
```bash
docker run -d \
  -e EMAIL="user1@example.com user2@example.com" \
  -e PASSWORD="password1 password2" \
  -e TIME=08:30 \
  --name sapkeeplive \
  evecus/sapkeeplive
```

## 查看日志

```bash
docker logs -f sapkeeplive
# 或查看 cron 执行日志
docker exec sapkeeplive tail -f /var/log/cron.log
```

## 注意事项

- `EMAIL` 与 `PASSWORD` 数量必须一一对应，否则脚本会报错退出。
- `TIME` 使用本地时间（已设置为 Asia/Shanghai），格式为 `HH:MM`，如 `08:30`。
- 容器启动时不会立即执行，而是等待 Cron 到达设定时间后触发。
