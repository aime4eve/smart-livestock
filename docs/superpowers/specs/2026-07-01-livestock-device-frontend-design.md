# 牲畜/设备/安装管理前端设计

**日期**: 2026-07-01
**状态**: 已确认
**范围**: Flutter 移动端（`Mobile/mobile_app/`），owner 角色功能

## 背景

后端 API 已全部就绪（全字段创建/更新、全局唯一性校验、安装校验链、删除守卫），但前端缺少对应的交互界面：
- 牲畜管理没有创建/编辑入口
- 设备管理页 FAB 只弹 demo 提示
- 安装弹窗的牲畜列表硬编码为空数组
- 牲畜详情页设备卡片没有"绑定设备"操作

## 确认的设计决策

| 决策 | 选择 |
|------|------|
| 牲畜管理入口位置 | "我的"页，与设备管理并列 |
| 表单交互形态 | BottomSheet（列表页内弹出） |
| 设备安装起点 | 路线 C（设备页 + 牲畜详情页双向入口） |
| 设备类型 | EAR_TAG / TRACKER / CAPSULE（与后端对齐） |

## 页面结构与导航

### 新增路由

- `AppRoute.livestockList('/livestock', 'livestock-list', '牲畜管理')` — 牲畜列表页

### 修改的页面

**"我的"页（mine_page.dart）**
- 在"个人设备与工具"区域，"设备管理"入口上方新增"牲畜管理"入口（`Icons.pets`）

**牲畜列表页（新文件 `livestock_list_page.dart`）**
- 标题 + FAB（+）-> 弹出 BottomSheet 创建表单
- 列表项：编号、品种、健康状态 chip
- 点击列表项 -> 进入详情页 `/livestock/:id`
- 列表项右侧操作（编辑）-> 弹出 BottomSheet 编辑表单

**设备列表页（devices_page.dart，已有）**
- FAB 替换为 BottomSheet 注册表单（替代 demo 提示）
- 列表项支持编辑 -> BottomSheet 编辑表单
- "安装"按钮 -> 安装对话框加载真实牲畜列表

**牲畜详情页（livestock_detail_page.dart，已有）**
- `_DeviceListCard` 下方新增"绑定设备"按钮 -> BottomSheet 选择可用设备

## 表单设计

### 牲畜创建/编辑 BottomSheet（LivestockFormSheet）

| 字段 | 控件 | 说明 |
|------|------|------|
| 编号 | TextField | 必填，livestockCode |
| 品种 | DropdownButton | 安格斯/和牛/西门塔尔/利木赞/其他 |
| 性别 | SegmentedButton | MALE / FEMALE |
| 出生日期 | DatePicker | 弹出日期选择器 |
| 体重 | TextField + 后缀 kg | 数字输入 |

编辑模式预填已有值。后端校验失败（如编号重复）时 SnackBar 显示错误信息。

### 设备注册/编辑 BottomSheet（DeviceFormSheet）

| 字段 | 控件 | 说明 |
|------|------|------|
| 编号 | TextField | 必填，deviceCode |
| 类型 | SegmentedButton | GPS追踪器 / 瘤胃胶囊 / 耳标 |
| devEui | TextField | 选填，LoRa EUI |

编辑模式时类型只读不可改（后端 deviceType 不可变）。

### 设备安装

**从设备页安装（复用现有 _InstallDialog）：**
- `_LivestockOption` 从硬编码空数组改为 `await livestockRepository.loadAll()` 异步加载
- 选择牲畜后 POST `/installations`

**从牲畜详情安装（新增 BottomSheet）：**
- 加载 ACTIVE 且未被安装的设备列表
- 选择设备后 POST `/installations`

## DeviceType 修复（预存 bug）

后端实际枚举为 `EAR_TAG / TRACKER / CAPSULE`，但前端 model 和映射仍是旧值。

| 文件 | 改动 |
|------|------|
| `core_models.dart` | `DeviceType` enum 改为 `{ gps, rumenCapsule, earTag }`，移除 `accelerometer` |
| `devices_api_repository.dart` | 映射对齐：`TRACKER/GPS` -> gps，`CAPSULE` -> rumenCapsule，`EAR_TAG` -> earTag |
| `livestock_detail_page.dart` | icon 映射移除 accelerometer，新增 earTag |
| `enum_labels.dart` | 新增 earTag case，移除 accelerometer case |
| `app_zh.arb` / `app_en.arb` | 新增 `deviceTypeEarTag`，移除 `deviceTypeAccelerometer` |

## i18n 新增 key

所有新增 key 在 `app_zh.arb` 和 `app_en.arb` 同步维护。

**牲畜管理：**
- `livestockListTitle` / `livestockAddNew` / `livestockEdit`
- `livestockFormFieldCode` / `livestockFormFieldBreed` / `livestockFormFieldGender`
- `livestockFormFieldBirthDate` / `livestockFormFieldWeight`
- `livestockCreateSuccess` / `livestockUpdateSuccess`
- `livestockBreedAngus` / `livestockBreedWagyu` / `livestockBreedSimmental` / `livestockBreedLimousin` / `livestockBreedOther`
- `livestockGenderMale` / `livestockGenderFemale`

**设备管理：**
- `deviceRegisterTitle` / `deviceEditTitle`
- `deviceFormFieldCode` / `deviceFormFieldDevEui`
- `deviceRegisterSuccess` / `deviceUpdateSuccess`
- `deviceTypeEarTag`（新增）

**安装：**
- `installBindDevice` / `installSelectDevice` / `installNoAvailableDevices` / `installSuccess`

## 数据层

无新增 Repository 接口。现有 `LivestockRepository.create/update/delete` 和 `DevicesRepository.create/update/activate/decommission` 已就绪。
安装直接调 `ApiClient.instance.farmPost('/installations', ...)`，与现有代码一致。

## 文件变更清单

**新增文件（3）：**
- `features/pages/livestock_list_page.dart` — 牲畜列表页
- `features/livestock/presentation/widgets/livestock_form_sheet.dart` — 牲畜表单 BottomSheet
- `features/devices/presentation/widgets/device_form_sheet.dart` — 设备表单 BottomSheet

**修改文件（~10）：**
- `app/app_route.dart` — 新增 livestockList 路由
- `app/app_router.dart` — 注册新路由
- `features/pages/mine_page.dart` — 新增牲畜管理入口
- `features/pages/devices_page.dart` — FAB 改为注册表单 + 编辑入口 + 安装弹窗接真实数据
- `features/pages/livestock_detail_page.dart` — 设备卡片加"绑定设备"按钮 + DeviceType icon 修复
- `core/models/core_models.dart` — DeviceType enum 修复
- `features/devices/data/devices_api_repository.dart` — DeviceType 映射修复
- `core/l10n/enum_labels.dart` — DeviceType 标签修复
- `l10n/app_zh.arb` — 新增 key + 移除 accelerometer
- `l10n/app_en.arb` — 新增 key + 移除 accelerometer
- `l10n/gen/app_localizations.dart` 等生成文件 — `flutter gen-l10n` 重新生成

## 范围外
- 设备卸载 UI（后端已就绪，但前端列表项暂不加快捷卸载按钮）
- 牲畜删除 UI（后端已有删除守卫，前端暂不暴露删除操作）
- Mock Server 数据对齐（前端已移除 Mock 模式）
