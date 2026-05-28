# smart_livestock_demo（Flutter）

智慧畜牧 **Mobile** 端应用。仓库总览与 Mock Server 说明见仓库根目录 [`README.md`](../../README.md)。

## 技术栈

- Flutter · `flutter_riverpod` · `go_router` · `flutter_map` · `fl_chart`
- 运行模式：`APP_MODE=mock`（默认，本地 `DemoSeed`）或 `APP_MODE=live`（HTTP 访问 Mock API，需先启动 `Mobile/backend`）

## 常用命令

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter run --dart-define=APP_MODE=live
```

### Live 联调（含 `flutter run -d chrome`）

1. **先启动 Mock API**（默认 `http://localhost:3001`）：  
   `cd ../backend && node server.js`  
   或使用 `../dev.sh start live chrome` 一键拉起后端 + 应用。
2. **再**执行 `flutter run -d chrome --dart-define=APP_MODE=live`。  
   Web 端默认请求 `http://127.0.0.1:3001/api`，避免浏览器将 `localhost` 解析到 IPv6 导致连不上本机 Node。若仍失败，可显式指定：  
   `--dart-define=API_BASE_URL=http://127.0.0.1:3001/api`
3. Live 模式下 `main` 会预拉取接口；后端未启动时会在控制台出现 `ApiCache init failed`，多数页面会回退到 Mock 数据，体验与真联调不一致。

详细目录结构、测试约定与主题规范见 [`../AGENTS.md`](../AGENTS.md)。
