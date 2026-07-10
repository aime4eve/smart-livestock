# 牲畜/设备/安装管理前端实施计划

> **执行方式说明：** 本计划按 Task 逐个执行。每个 Task 内的步骤用 `- [ ]` 复选框标记进度。

**目标：** 在 Flutter 移动端实现牲畜管理列表、设备注册/编辑表单、双向设备安装，并修复 DeviceType 枚举与后端不一致的预存 bug。

**架构：** BottomSheet 表单 + Riverpod Controller。复用现有 Repository 接口和 API 调用。所有文案走 i18n（arb 中英双语）。

**技术栈：** Flutter + flutter_riverpod + go_router + AppLocalizations

**设计文档：** `docs/superpowers/specs/2026-07-01-livestock-device-frontend-design.md`

**Flutter 命令：**
- 编译验证：`cd Mobile/mobile_app && flutter analyze --no-pub 2>&1 | tail -10`
- 生成 l10n：`cd Mobile/mobile_app && flutter gen-l10n 2>&1`
- 构建 web：`cd Mobile/mobile_app && ./build_web.sh 2>&1 | tail -5`
- 沙箱内 flutter 命令统一加 `HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true`

**路径约定：** 所有 Dart 文件路径相对于 `Mobile/mobile_app/lib/`

---

### Task 1：DeviceType 枚举修复 + i18n key 新增

**文件：**
- 修改：`core/models/core_models.dart`
- 修改：`features/devices/data/devices_api_repository.dart`
- 修改：`features/pages/livestock_detail_page.dart`
- 修改：`core/l10n/enum_labels.dart`
- 修改：`l10n/app_zh.arb`
- 修改：`l10n/app_en.arb`

- [ ] **步骤 1：修改 `core_models.dart` 的 DeviceType 枚举**

将：
```dart
enum DeviceType { gps, rumenCapsule, accelerometer }
```
改为：
```dart
enum DeviceType { gps, rumenCapsule, earTag }
```

- [ ] **步骤 2：修改 `devices_api_repository.dart` 的映射逻辑**

在 `_parseDeviceItem` 方法中，将类型映射改为：
```dart
final type = switch (typeStr.toUpperCase()) {
  'TRACKER' || 'GPS' => DeviceType.gps,
  'CAPSULE' || 'RUMEN_CAPSULE' => DeviceType.rumenCapsule,
  'EAR_TAG' || 'EAR_TAG' => DeviceType.earTag,
  _ => throw FormatException('deviceType: $typeStr'),
};
```

- [ ] **步骤 3：修改 `livestock_detail_page.dart` 的 icon 映射**

在 `_DeviceListCard` 的 icon switch 中，将 `DeviceType.accelerometer => Icons.speed` 改为：
```dart
DeviceType.earTag => Icons.tag,
```

- [ ] **步骤 4：修改 `enum_labels.dart`**

将 DeviceType 扩展改为：
```dart
extension DeviceTypeL10n on DeviceType {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case DeviceType.gps:
        return l10n.deviceTypeGps;
      case DeviceType.rumenCapsule:
        return l10n.deviceTypeRumenCapsule;
      case DeviceType.earTag:
        return l10n.deviceTypeEarTag;
    }
  }
}
```

- [ ] **步骤 5：修改 `app_zh.arb`**

移除 `deviceTypeAccelerometer` 及其 `@` 元数据。
新增（放在 `deviceTypeRumenCapsule` 后面）：
```json
"deviceTypeEarTag": "耳标",
"@deviceTypeEarTag": {},
```

同时在文件末尾 `}` 前新增所有牲畜管理、设备管理、安装相关的 key（见下方完整列表）。

- [ ] **步骤 6：修改 `app_en.arb`**

移除 `deviceTypeAccelerometer`。
新增：
```json
"deviceTypeEarTag": "Ear Tag",
"@deviceTypeEarTag": {},
```

同时新增与 app_zh.arb 对齐的英文 key。

**完整新增 i18n key 列表（两份 arb 同步）：**

```
livestockListTitle: 牲畜管理 / Livestock Management
livestockAddNew: 新增牲畜 / Add Livestock
livestockEdit: 编辑牲畜 / Edit Livestock
livestockFormFieldCode: 编号 / Code
livestockFormFieldBreed: 品种 / Breed
livestockFormFieldGender: 性别 / Gender
livestockFormFieldBirthDate: 出生日期 / Birth Date
livestockFormFieldWeight: 体重 / Weight
livestockCreateSuccess: 牲畜创建成功 / Livestock created successfully
livestockUpdateSuccess: 牲畜更新成功 / Livestock updated successfully
livestockBreedAngus: 安格斯 / Angus
livestockBreedWagyu: 和牛 / Wagyu
livestockBreedSimmental: 西门塔尔 / Simmental
livestockBreedLimousin: 利木赞 / Limousin
livestockBreedOther: 其他 / Other
livestockGenderMale: 公 / Male
livestockGenderFemale: 母 / Female
deviceRegisterTitle: 注册设备 / Register Device
deviceEditTitle: 编辑设备 / Edit Device
deviceFormFieldCode: 设备编号 / Device Code
deviceFormFieldDevEui: LoRa EUI（选填） / LoRa EUI (optional)
deviceRegisterSuccess: 设备注册成功 / Device registered successfully
deviceUpdateSuccess: 设备更新成功 / Device updated successfully
installBindDevice: 绑定设备 / Bind Device
installSelectDevice: 选择设备 / Select Device
installNoAvailableDevices: 没有可用设备 / No available devices
installSuccess: 安装成功 / Installed successfully
```

- [ ] **步骤 7：生成 l10n**

运行：`cd Mobile/mobile_app && flutter gen-l10n 2>&1`
预期：生成文件无报错

- [ ] **步骤 8：编译验证**

运行：`cd Mobile/mobile_app && HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze --no-pub 2>&1 | tail -10`
预期：无 error（warning 可接受）

- [ ] **步骤 9：提交**

```bash
git add Mobile/mobile_app/
git commit -m "fix+feat(i18n): DeviceType 枚举对齐后端(earTag替换accelerometer) + 新增牲畜/设备/安装管理 i18n key"
```

---

### Task 2：牲畜列表页 + 路由

**文件：**
- 修改：`app/app_route.dart`
- 修改：`app/app_router.dart`
- 修改：`features/pages/mine_page.dart`
- 新增：`features/pages/livestock_list_page.dart`

- [ ] **步骤 1：新增路由枚举**

在 `app_route.dart` 的 `livestockDetail` 行后面添加：
```dart
livestockList('/livestock', 'livestock-list', '牲畜管理'),
```

- [ ] **步骤 2：注册路由**

在 `app_router.dart` 中找到 livestockDetail 路由配置，在其后添加：
```dart
GoRoute(
  path: AppRoute.livestockList.path,
  name: AppRoute.livestockList.routeName,
  builder: (context, state) => const LivestockListPage(),
),
```
需要 import `LivestockListPage`。

- [ ] **步骤 3：在 mine_page.dart 新增牲畜管理入口**

在 `_buildProfileSection` 方法中，找到"个人设备与工具"区域的"设备管理" `HighfiCard`，在其上方插入：
```dart
HighfiCard(
  child: ListTile(
    key: const Key('mine-livestock-mgmt'),
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.pets),
    title: Text(l10n.livestockListTitle),
    subtitle: Text(l10n.livestockListTitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.go(AppRoute.livestockList.path),
  ),
),
const SizedBox(height: AppSpacing.md),
```
subtitle 暂时也用 `livestockListTitle`，后续可加专门的描述 key。

- [ ] **步骤 4：创建 `livestock_list_page.dart`**

创建 `features/pages/livestock_list_page.dart`，实现：
- `ConsumerWidget`
- watch `livestockListControllerProvider` 获取列表数据
- FAB 点击 -> showModalBottomSheet 弹出 `LivestockFormSheet`（Task 3 创建，先用 placeholder SnackBar）
- 列表项：编号 + 品种 + 健康状态 chip
- 列表项 onTap -> 跳转 `/livestock/:id`
- 列表项 trailing 编辑按钮 -> showModalBottomSheet 弹出 `LivestockFormSheet`
- 加载中 / 错误 / 空状态处理

基础结构（FAB 和编辑先放 SnackBar placeholder，Task 3 接入表单后替换）：
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_card.dart';
import 'package:hkt_livestock_agentic/features/highfi/widgets/highfi_status_chip.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class LivestockListPage extends ConsumerWidget {
  const LivestockListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(livestockListControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.livestockListTitle)),
      floatingActionButton: FloatingActionButton(
        key: const Key('livestock-add-fab'),
        onPressed: () {
          // Task 3 替换为 LivestockFormSheet
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('TODO: form')));
        },
        child: const Icon(Icons.add),
      ),
      body: asyncData.when(
        data: (data) => data.items.isEmpty
            ? Center(child: Text(l10n.devicesNoDevices))
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: data.items.length,
                itemBuilder: (ctx, i) {
                  final item = data.items[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: HighfiCard(
                      child: ListTile(
                        key: Key('livestock-${item.id}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        title: Text(item.earTag, style: Theme.of(ctx).textTheme.titleMedium),
                        subtitle: Text(item.breed),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HighfiStatusChip(
                              label: item.health.localizedLabel(l10n),
                              color: item.health == LivestockHealth.abnormal
                                  ? AppColors.danger
                                  : item.health == LivestockHealth.watch
                                      ? AppColors.warning
                                      : AppColors.success,
                              icon: item.health == LivestockHealth.abnormal
                                  ? Icons.warning_amber_rounded
                                  : item.health == LivestockHealth.watch
                                      ? Icons.visibility_outlined
                                      : Icons.check_circle_outline,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () {
                                // Task 3 替换为 LivestockFormSheet(edit)
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('TODO: edit')));
                              },
                            ),
                          ],
                        ),
                        onTap: () => context.go('/livestock/${item.id}'),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
      ),
    );
  }
}
```

- [ ] **步骤 5：编译验证**

运行：`cd Mobile/mobile_app && HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze --no-pub 2>&1 | tail -10`
预期：无 error

- [ ] **步骤 6：提交**

```bash
git add Mobile/mobile_app/
git commit -m "feat(frontend): 牲畜列表页 + 路由 + 我的页入口"
```

---

### Task 3：牲畜创建/编辑表单 BottomSheet

**文件：**
- 新增：`features/livestock/presentation/widgets/livestock_form_sheet.dart`
- 修改：`features/pages/livestock_list_page.dart` — FAB 和编辑接入表单

- [ ] **步骤 1：创建 `livestock_form_sheet.dart`**

创建一个 StatefulWidget `LivestockFormSheet`，接受可选的 `LivestockSummary`（编辑模式预填）。

表单字段：
- 编号 TextField（controller 初始值为编辑模式的 earTag）
- 品种 DropdownButton（选项列表，编辑模式预选）
- 性别 SegmentedButton<String>（MALE / FEMALE）
- 出生日期 — 点按弹出 DatePicker
- 体重 TextField + 后缀 kg
- 底部 取消 / 确认 按钮

确认时构造 body Map，调用 `ref.read(livestockRepositoryProvider).create(body)` 或 `.update(id, body)`。
成功后 `Navigator.pop` 返回，调用方刷新 controller。
失败时 SnackBar 显示错误（如编号重复）。

需要 import：
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/features/livestock/domain/livestock_repository.dart';
import 'package:hkt_livestock_agentic/features/livestock/presentation/livestock_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
```

通过 `showModalBottomSheet` 调用：
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => LivestockFormSheet(
    existing: existingItem, // null for create
  ),
).then((_) => ref.read(livestockListControllerProvider.notifier).refresh());
```

- [ ] **步骤 2：修改 `livestock_list_page.dart` 接入表单**

FAB onPressed 改为：
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => const LivestockFormSheet(),
).then((_) => ref.read(livestockListControllerProvider.notifier).refresh());
```

编辑按钮 onPressed 改为：
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => LivestockFormSheet(existing: item),
).then((_) => ref.read(livestockListControllerProvider.notifier).refresh());
```

- [ ] **步骤 3：编译验证**

运行：`cd Mobile/mobile_app && HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze --no-pub 2>&1 | tail -10`
预期：无 error

- [ ] **步骤 4：提交**

```bash
git add Mobile/mobile_app/
git commit -m "feat(frontend): 牲畜创建/编辑 BottomSheet 表单"
```

---

### Task 4：设备注册/编辑表单 BottomSheet

**文件：**
- 新增：`features/devices/presentation/widgets/device_form_sheet.dart`
- 修改：`features/pages/devices_page.dart` — FAB 和编辑接入表单

- [ ] **步骤 1：创建 `device_form_sheet.dart`**

创建一个 StatefulWidget `DeviceFormSheet`，接受可选的 `DeviceItem`（编辑模式预填）。

表单字段：
- 编号 TextField
- 类型 SegmentedButton<DeviceType>（gps / rumenCapsule / earTag）
  - 编辑模式时类型 disabled（只读）
- devEui TextField（选填）
- 底部 取消 / 确认 按钮

确认时构造 body Map：
```dart
{'deviceCode': ..., 'deviceType': _typeToApi(type), 'devEui': ...}
```
类型映射函数：
```dart
String _typeToApi(DeviceType t) => switch (t) {
  DeviceType.gps => 'TRACKER',
  DeviceType.rumenCapsule => 'CAPSULE',
  DeviceType.earTag => 'EAR_TAG',
};
```

创建调 `ref.read(devicesRepositoryProvider).create(body)`，编辑调 `.update(id, body)`。

- [ ] **步骤 2：修改 `devices_page.dart` 接入表单**

FAB onPressed 从 demo SnackBar 改为：
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => const DeviceFormSheet(),
).then((_) => controller.refresh());
```

在 `HighfiDeviceTile` 下方或列表项 trailing 加编辑入口：
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => DeviceFormSheet(existing: device),
).then((_) => controller.refresh());
```

- [ ] **步骤 3：编译验证**

运行：`cd Mobile/mobile_app && HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze --no-pub 2>&1 | tail -10`
预期：无 error

- [ ] **步骤 4：提交**

```bash
git add Mobile/mobile_app/
git commit -m "feat(frontend): 设备注册/编辑 BottomSheet 表单"
```

---

### Task 5：设备安装双向接入

**文件：**
- 修改：`features/pages/devices_page.dart` — 安装弹窗加载真实牲畜列表
- 修改：`features/pages/livestock_detail_page.dart` — 牲畜详情加"绑定设备"按钮

- [ ] **步骤 1：修改 `devices_page.dart` 的 `_showInstallDialog`**

将 `const options = <_LivestockOption>[];` 改为异步加载：

在 `DevicesPage` 中注入 `LivestockRepository`，在 `_showInstallDialog` 中：
```dart
final livestockRepo = ref.read(livestockRepositoryProvider);
List<_LivestockOption> options = [];
try {
  final livestockData = await livestockRepo.loadAll();
  options = livestockData.items.map((l) => _LivestockOption(
    id: l.id,
    label: l.earTag,
    subtitle: l.breed,
  )).toList();
} catch (_) {}
```

需要将 `_showInstallDialog` 改为 `async`，import `livestock_controller.dart` 和 `livestock_repository.dart`。

_InstallDialog 的 `options` 参数传入异步加载的列表。

- [ ] **步骤 2：修改 `livestock_detail_page.dart` 加"绑定设备"按钮**

在 `_DeviceListCard` 的 Column 末尾（for 循环之后）添加：
```dart
const SizedBox(height: AppSpacing.md),
OutlinedButton.icon(
  key: const Key('livestock-bind-device'),
  onPressed: () => _showBindDeviceSheet(context, ref, detail),
  icon: const Icon(Icons.link),
  label: Text(l10n.installBindDevice),
),
```

新增 `_showBindDeviceSheet` 方法（在 `LivestockDetailPage` 或 `_DeviceListCard` 中）：
```dart
void _showBindDeviceSheet(BuildContext context, WidgetRef ref, LivestockDetail detail) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _BindDeviceSheet(livestockId: detail.livestockId),
  ).then((_) => ref.read(livestockDetailControllerProvider(detail.earTag).notifier).refresh());
}
```

`_BindDeviceSheet` 是一个 StatefulWidget，加载设备列表，过滤出可安装的（INVENTORY 或 ACTIVE 状态），用户选择后 POST `/installations`。

- [ ] **步骤 3：编译验证**

运行：`cd Mobile/mobile_app && HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze --no-pub 2>&1 | tail -10`
预期：无 error

- [ ] **步骤 4：提交**

```bash
git add Mobile/mobile_app/
git commit -m "feat(frontend): 设备安装双向接入 — 设备页选牲畜 + 牲畜详情选设备"
```

---

### Task 6：全量编译 + l10n 验证

**文件：** 无（仅验证）

- [ ] **步骤 1：生成 l10n**

运行：`cd Mobile/mobile_app && flutter gen-l10n 2>&1`
预期：无报错，所有新增 key 可用

- [ ] **步骤 2：全量 analyze**

运行：`cd Mobile/mobile_app && HOME=/private/tmp FLUTTER_SUPPRESS_ANALYTICS=true flutter analyze --no-pub 2>&1 | tail -20`
预期：无 error（warning 可接受）

- [ ] **步骤 3：构建 web 验证**

运行：`cd Mobile/mobile_app && ./build_web.sh 2>&1 | tail -5`
预期：构建成功

- [ ] **步骤 4：如有修复，提交**

```bash
git add Mobile/mobile_app/
git commit -m "fix: post-verification fixes"
```
