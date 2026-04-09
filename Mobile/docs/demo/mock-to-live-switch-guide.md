# Mock 到 Live 切换说明

## 1. 当前机制
- App 运行模式由 `APP_MODE` 控制，支持：
  - `mock`
  - `live`
- 默认模式：`mock`
- 当前两种模式的语义：
  - `mock`：高保真评审、演示脚本、场景切换都以本地 mock datasource 为准
  - `live`：联调壳模式，保留真实 repository/provider 边界，但当前仍以内置 mock 兜底
- 代码入口：
  - `mobile_app/lib/app/app_mode.dart`
  - `mobile_app/lib/app/app_route.dart`
  - `mobile_app/lib/app/app_router.dart`
  - `mobile_app/lib/app/demo_app.dart`

## 2. 本地运行

### Mock 模式
```bash
cd mobile_app
flutter run
```

### Live 模式
```bash
cd mobile_app
flutter run --dart-define=APP_MODE=live
```

## 3. 当前 live 的行为
- 当前后端尚未开始建设，`live` 模式已经切到独立的 live repository/provider 分支。
- 但 live repository 仍临时回退到 mock 数据，保证前端结构先稳定。
- 后续接入真实后端时，只替换 live repository 内部 datasource，不改页面层与 controller 层。

## 3.1 当前 mock 场景

- 正常
- 围栏越界
- 设备低电
- 信号丢失
- 离线缓存

这些场景用于支撑高保真评审脚本与页面演示，不要求页面层直接读取 mock 配置。

## 4. 切换路径
页面层不直接读取假数据，统一经过：

```text
Page -> Controller -> Repository -> DataSource
```

因此联调时按下面顺序替换：
1. 保持 Page/Controller 不动。
2. 在 `live_*_repository.dart` 中接入 HTTP datasource。
3. 按 `docs/api-contracts/mobile-app-mock-api-contract.md` 对齐请求/响应/错误码。
4. 验证 `mock` 与 `live` 两种模式都可运行。
5. 使用 `docs/demo/highfi-review-script.md` 复核高保真流程在两种模式下都不破。

## 5. 建议替换顺序
1. `/api/me` 与权限模型
2. 看板 summary
3. 地图轨迹与 fallback 策略
4. 告警列表与状态流转
5. 围栏 CRUD
6. 租户后台与 license 调整
7. 我的页资料

## 6. 回退策略
- 若 live 接口不稳定，可临时切回：
```bash
flutter run --dart-define=APP_MODE=mock
```
- 若仅部分接口完成，优先让未完成模块的 live repository 在内部回退到 mock datasource，而不是让页面直接分支判断。
