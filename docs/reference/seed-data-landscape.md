# 种子数据全景图

> 基于 Flyway 迁移 V4–V17，展示完整种子数据关系、表级统计和旅程可测性。

---

## 关系拓扑

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Tenant 1「Demo牧场」                          │
│                     (SAMPLE phase, direct billing)                  │
│                                                                     │
│  ┌──────────────────────────┐    ┌──────────────────────────┐      │
│  │     Farm 1「主牧场」       │    │     Farm 2「南山分场」      │      │
│  │  (28.2458, 112.8519)     │    │  (28.2000, 112.9000)     │      │
│  │  500 公顷                 │    │  300 公顷                 │      │
│  │                           │    │                           │      │
│  │  🐄 牲畜 50 头             │    │  🐄 牲畜 10 头             │      │
│  │     HEALTHY × 46          │    │     HEALTHY × 8           │      │
│  │     WARNING × 1           │    │     WARNING × 1           │      │
│  │     CRITICAL × 3          │    │     CRITICAL × 1          │      │
│  │                           │    │                           │      │
│  │  🔲 围栏 4 个              │    │  🔲 围栏 2 个              │      │
│  │     1. 放牧A区 (25头)      │    │     1. 放牧C区             │      │
│  │     2. 放牧B区 (18头)      │    │     2. 饮水区              │      │
│  │     3. 夜间休息区 (4头)     │    │                           │      │
│  │     4. 隔离区 (3头)        │    │                           │      │
│  │                           │    │                           │      │
│  │  🚨 告警 18 条             │    │  🚨 告警 5 条              │      │
│  │     PENDING × 4           │    │     PENDING × 2           │      │
│  │     ACKNOWLEDGED × 2      │    │     ACKNOWLEDGED × 1      │      │
│  │     HANDLED × 7           │    │     HANDLED × 1           │      │
│  │     ARCHIVED × 5          │    │     ARCHIVED × 1          │      │
│  │                           │    │                           │      │
│  │  📡 设备 100 台 (tenant级)  │    │  (无独立设备)              │      │
│  │     GPS 追踪器 × 50        │    │                           │      │
│  │     瘤胃胶囊 × 30          │    │                           │      │
│  │     加速度计 × 20          │    │                           │      │
│  │                           │    │                           │      │
│  │  🔗 安装记录               │    │                           │      │
│  │     GPS ~32台 → 牲畜       │    │                           │      │
│  │     胶囊 12台 → 牲畜       │    │                           │      │
│  │                           │    │                           │      │
│  │  📍 GPS 轨迹 ~768 条       │    │                           │      │
│  └──────────────────────────┘    └──────────────────────────┘      │
│                                                                     │
│  💳 订阅: premium / active / monthly / 2027-01-01 到期               │
│  📄 合同: CTR-2026-DEMO-001 / direct / premium / active             │
│  💰 分润: 3 期 (2月 settled / 3月 confirmed / 4月 confirmed)         │
│  🔑 API Key: Demo API Key / ACTIVE / 2027-12-31 到期                │
│  🏷️ Feature Gates: 4 tiers × 7 features (28 条)                     │
└─────────────────────────────────────────────────────────────────────┘

                          用户分配
 ┌────────────────┬─────────────┬──────────────┬──────────────┐
 │    用户         │   角色       │  Farm 1      │  Farm 2      │
 ├────────────────┼─────────────┼──────────────┼──────────────┤
 │ 张牧场          │ OWNER       │ ✅ OWNER     │ ✅ OWNER     │
 │ 13800138000     │             │              │              │
 ├────────────────┼─────────────┼──────────────┼──────────────┤
 │ 李牧工          │ WORKER      │ ✅ WORKER    │ —            │
 │ 13800138001     │             │              │              │
 ├────────────────┼─────────────┼──────────────┼──────────────┤
 │ B端管理员        │ B2B_ADMIN   │ — (tenant级) │ — (tenant级) │
 │ 13900139000     │             │              │              │
 ├────────────────┼─────────────┼──────────────┼──────────────┤
 │ 平台管理员        │ PLATFORM    │ —            │ —            │
 │ 13800000000     │ _ADMIN      │ (无租户归属)  │              │
 └────────────────┴─────────────┴──────────────┴──────────────┘
 所有用户密码: 123
```

---

## 表级统计

| 表 | 行数 | 迁移来源 |
|----|------|---------|
| tenants | 1 | V4 |
| farms | 2 | V4 + V16 |
| users | 4 | V4 + V16 |
| user_farm_assignments | 3 | V4 + V16 |
| api_keys | 1 | V4 |
| livestock | 60 | V9 (50) + V17 (10) |
| fences | 6 | V9 (4) + V17 (2) |
| alerts | 23 | V9 (18) + V17 (5) |
| devices | 100 | V10 |
| device_licenses | 100 | V10 |
| installations | ~44 | V10 |
| gps_logs | ~768 | V10 |
| subscriptions | 1 | V6 → V11 升级 premium |
| contracts | 1 | V11 |
| revenue_periods | 3 | V11 |
| feature_gates | 28 | V6 |
| notifications | 0 | — |

---

## 旅程可测性矩阵

| 旅程 | 可跑通？ | 依赖数据 |
|------|:-------:|---------|
| platform_admin 登录 → 创建租户 → 查看租户详情 → 新增用户 | ✅ | user + tenant |
| b2b_admin 登录 → B端概览 → 牧场列表(2个) → 合同信息 → 对账(3期) → 牧工管理 | ✅ | 全部 Commerce + 2 farms |
| owner 登录 → 数智孪生(50头) → 围栏管理(4个) → 告警流转(全状态) → 设备管理(100台) → 后台/订阅 | ✅ | Farm 1 全量数据 |
| owner 切换到 Farm 2 → 10头牲畜 → 2个围栏 → 5条告警 | ✅ | Farm 2 数据 |
| owner 切换回 Farm 1 → 数据恢复 | ✅ | 两牧场数据差异 |
| worker 登录 → 查看告警 → 确认 PENDING → 无法处理/归档 | ✅ | worker + PENDING 告警 |
| worker 仅看到 Farm 1 数据，无法切换到 Farm 2 | ✅ | worker 仅分配 Farm 1 |
| GPS 越界 → 自动告警 | ✅ | GpsAlertFlowTest 已覆盖 |
| 订阅 premium → 功能全部解锁 | ✅ | V11 升级到 premium |
| API Key 认证 → Open API 访问 | ✅ | V4 seed key |

---

## 种子数据登录凭据

| 角色 | 手机号 | 密码 | 关联 |
|------|--------|------|------|
| platform_admin（平台管理员） | 13800000000 | 123 | 平台级管理，无租户归属 |
| b2b_admin（B端管理员） | 13900139000 | 123 | B端管理员，关联 Demo 租户 |
| owner（牧场主） | 13800138000 | 123 | Demo 租户 owner，关联主牧场 + 南山分场 |
| worker（牧工） | 13800138001 | 123 | Demo 租户 worker，仅关联主牧场 |

---

## 迁移文件索引

| 迁移 | 内容 | 限界上下文 |
|------|------|-----------|
| V1 | 建表: tenants, farms, users, user_farm_assignments, api_keys | Identity |
| V2 | 建表: livestock, fences, alerts | Ranch |
| V3 | 建表: devices, device_licenses, installations, gps_logs | IoT |
| V4 | 种子: platform_admin + demo tenant + owner + 主牧场 + API key | Identity |
| V5 | 修复: 所有用户密码统一为 BCrypt('123') | Identity |
| V6 | 建表 + 种子: subscriptions, contracts, revenue_periods, feature_gates, notifications | Commerce |
| V7 | 修复: subscription trial period | Commerce |
| V8 | 修复: password hash 前缀 $2a$ → $2b$ | Identity |
| V9 | 种子: 50 牲畜 + 4 围栏 + 18 告警 (Farm 1) | Ranch |
| V10 | 种子: 100 设备 + 100 license + ~44 安装 + ~768 GPS 轨迹 | IoT |
| V11 | 种子: 升级 premium 订阅 + 合同 + 3 期分润 | Commerce |
| V12 | 占位: Twin/Health (Phase 2b) | — |
| V13 | 建表: tile 相关表 + fence version 字段 | Ranch |
| V15 | 清理: drop username 列 | Identity |
| V16 | 种子: b2b_admin + worker 用户 + 南山分场 (Farm 2) + 用户分配 | Identity |
| V17 | 种子: Farm 2 数据 (10 牲畜 + 2 围栏 + 5 告警) | Ranch |
