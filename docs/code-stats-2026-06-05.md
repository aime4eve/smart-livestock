# 代码行数统计

统计日期：2026-06-05

## 总览

| 项目 | 源码行数 | 测试行数 | 文件数 | 合计 |
|------|---------|---------|--------|------|
| 前端 Flutter (Mobile/mobile_app) | 27,419 | 3,427 | 325 lib + 49 test | 30,846 |
| 后端 Spring Boot (smart-livestock-server) | 29,950 | 7,994 | 527 main + 53 test | 37,944 |
| **总计** | **57,369** | **11,421** | **954** | **68,790** |

---

## 前端 Flutter 明细（lib/，共 27,419 行）

### 核心/公共层
| 目录 | 行数 |
|------|------|
| lib/ 顶层 | 69 |
| pages | 4,937 |
| b2b_admin | 5,720 |
| admin | 2,634 |
| fence | 1,763 |
| subscription | 1,341 |
| tenant | 1,317 |
| farm_creation | 865 |
| highfi | 488 |
| worker_management | 549 |
| subscription_service_management | 359 |
| offline_fences | 387 |
| offline_tiles | 219 |
| devices | 286 |
| revenue | 285 |
| livestock | 287 |
| stats | 255 |
| mine | 238 |
| alerts | 216 |
| api_authorization | 185 |
| auth | 194 |
| contract_management | 193 |
| farm_switcher | 160 |
| digestive | 80 |
| fever_warning | 80 |
| estrus | 80 |
| dashboard | 99 |
| twin_overview | 48 |
| epidemic | 47 |
| offline_livestock | 27 |

---

## 后端 Spring Boot 明细（src/main/java，共 29,950 行）

### 按限界上下文

| 包名 | 行数 | 说明 |
|------|------|------|
| commerce | 4,757 | 订阅/合同/分润/配额 |
| identity | 4,358 | 租户/用户/牧场/认证 |
| ranch | 3,933 | 牲畜/围栏/告警/地图 |
| iot | 3,226 | 设备/License/安装/GPS |
| health | 2,540 | 温度/蠕动/发情/疫病 |
| shared | 1,707 | 安全/审计/通用 |
| analytics | 1,151 | 统计/分析 |
| platform | 269 | 平台级 |
