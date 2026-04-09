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

详细目录结构、测试约定与主题规范见 [`../AGENTS.md`](../AGENTS.md)。
