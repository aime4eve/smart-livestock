# 牲畜移动轨迹滑动条实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将牲畜移动轨迹页面从三按钮静态折线改为时间滑动条动态播放，适配 Bottom Sheet 75% 屏高约束，支持范围切换 + 动态采样。

**Architecture:** 纯前端改动。重写 `trajectory_sheet.dart`，后端 API / 数据模型 / 地图基础设施均不变。

**Tech Stack:** Flutter 3.x / flutter_map / flutter_riverpod / Dart Timer

**Spec:** `docs/superpowers/specs/2026-07-14-trajectory-slider-design.md`

**关联工单:** [NIX-11](https://linear.app/nix-agentic/issue/NIX-11/增强移动轨迹操作体验)

---

## File Structure

### trajectory_sheet.dart — 重写

| 区域 | 职责 |
|------|------|
| State 字段 | 范围、数据、播放、地图、采样配置 |
| `_load()` | 根据范围+上报周期计算 sampleSize，调用后端 API |
| `_HeaderRow` | 单行：标题+牲畜摘要+范围选择器+关闭 |
| `_buildMap()` | FlutterMap + 轨迹线 + 脉冲标记（复用现有地图逻辑） |
| `_buildSlider()` | 当前时间 + 滑动条 + 起止标签 |
| `_buildControls()` | 播放/暂停/跳转 + 变速 |
| `_buildStats()` | 三列紧凑统计卡片 |

### app_zh.arb / app_en.arb — 增删 key

| 操作 | Key |
|------|-----|
| 新增 | livestockTrajectoryCurrentTime, livestockTrajectoryRange24h, livestockTrajectoryRange7d, livestockTrajectoryRange30d, livestockTrajectoryRangeCustom, livestockTrajectoryFollow, livestockTrajectoryFitAll, livestockTrajectoryPointUnit, livestockTrajectoryAccuracy, livestockTrajectoryLoading, livestockTrajectoryPlay, livestockTrajectoryPause |
| 删除 | livestockRange24h, livestockRange7d, livestockRange30d |
| 保留 | livestockTrajectoryTitle, livestockTrajectoryPoints, livestockTrajectoryDistance, livestockTrajectoryRange, livestockTrajectoryEmpty, livestockTrajectoryNoGps |

---

## Tasks

### Task 1: i18n key 增删

- [ ] 在 `app_zh.arb` 新增 12 个 key（中文文案）
- [ ] 在 `app_en.arb` 新增对应 12 个 key（英文文案）
- [ ] 从两个 arb 文件删除 livestockRange24h / livestockRange7d / livestockRange30d（含 @ 元数据）
- [ ] 运行 `flutter gen-l10n` 重新生成 app_localizations*.dart
- [ ] **验证:** `flutter gen-l10n` 无错误，生成的 dart 文件包含新 key

### Task 2: 重写 trajectory_sheet.dart — 数据层 + State

- [ ] 定义 `TrajectoryRange` 枚举（h24 / d7 / d30 / custom）
- [ ] 定义采样配置常量：`_gpsReportInterval = Duration(minutes: 30)`，`_maxSliderPoints = 500`
- [ ] 实现 `computeSampleSize(Duration rangeDuration)` 方法：预期点数 ≤ 500 返回 null，否则返回 500
- [ ] 实现 `_load()`：根据当前范围计算 startTime/endTime/sampleSize，调用 `ApiClient.instance.farmGet('/livestock/{id}/gps-logs?...')`
- [ ] 解析响应 items 为内部 `_GpsPoint` 列表（含 lat/lng/recordedAt/accuracy），按 recordedAt 升序排列
- [ ] State 字段：_range, _customRange, _points, _loading, _currentIdx, _playing, _speed, _playTimer, 地图相关复用现有
- [ ] 初始化：默认范围 h24，加载后 currentIdx 定位到最后一个点
- [ ] **验证:** 编译通过，`_load()` 能正确请求数据并解析

### Task 3: 范围选择器（折叠下拉）

- [ ] 实现 `_buildHeaderRow()`：单行布局（标题 + 牲畜摘要 + 范围按钮 + 关闭）
- [ ] 范围按钮使用 `PopupMenuButton` 或自定义下拉，显示当前范围标签
- [ ] 选项：最近24小时 / 最近7天 / 最近30天 / 自定义日期
- [ ] 选择范围后调用 `_load()` 重新加载数据
- [ ] 自定义日期：调用 `showDateRangePicker`，选择后调用 `_load()`
- [ ] 切换范围时暂停播放 + 显示加载指示器
- [ ] **验证:** 切换范围后滑动条重建，数据正确更新

### Task 4: 滑动条 + 当前时间

- [ ] 实现 `_buildSliderSection()`：当前时间（内联小字）+ Slider + 起止标签
- [ ] Slider range = 0 ~ (_points.length - 1)，divisions = _points.length - 1
- [ ] 拖动 onChangeEnd：暂停播放，更新 currentIdx，调用 `_updateDisplay()`
- [ ] 起止标签：24h 显示「时:分」，多天范围显示「月/日 时:分」
- [ ] Slider thumb 自定义样式（绿色边框），filled track 渐变色
- [ ] **验证:** 拖动滑动条时轨迹实时增长/收缩

### Task 5: 播放控制 + 变速

- [ ] 实现 `_buildControls()`：skip start + play/pause + skip end + 速度选择
- [ ] play：启动 Timer，每 tick（300ms / speed，下限 50ms）currentIdx++，调用 `_updateDisplay()`
- [ ] pause：取消 Timer
- [ ] 到达尾点自动 pause；尾点再点 play 回到起点
- [ ] skipStart / skipEnd：暂停 + 跳到首/尾点
- [ ] 变速按钮（1x/2x/4x/8x），播放中变速立即用新速度继续
- [ ] dispose 时取消 Timer
- [ ] **验证:** 播放动画流畅，变速即时生效

### Task 6: 地图渲染（复用 + 适配）

- [ ] 复用现有 FlutterMap + SmartTileProvider 初始化逻辑
- [ ] `_updateDisplay()` 中根据 currentIdx 计算 visible 点子集
- [ ] PolylineLayer：已走轨迹（primary 色）+ 最近 5 点 trail（accent 色）
- [ ] MarkerLayer：起点标记（accent 圆点）+ 当前脉冲标记（primary 脉冲圆）
- [ ] 坐标转换：visible 子集 latLngs 按 `shouldTransformCoordinates()` 做 WGS-84→GCJ-02
- [ ] tile 源切换时重新 fitBounds（复用现有 _lastTransformed 逻辑）
- [ ] 跟随模式（默认开）：播放/拖动时 panTo 当前标记；全览按钮 fitBounds 全部点
- [ ] **验证:** 播放时标记沿轨迹移动，跟随模式地图自动平移

### Task 7: 统计卡片 + 空状态

- [ ] 实现 `_buildStats()`：三列紧凑卡片（轨迹点 currentIdx+1/total、移动距离、活动范围）
- [ ] 统计基于 visible 子集（0 ~ currentIdx），实时随滑动条更新
- [ ] 移动距离：累计 haversine（复用 `totalPathDistance`）
- [ ] 活动范围：外接矩形面积（复用 `_calcArea`）
- [ ] 无 GPS 设备：显示 `livestockTrajectoryNoGps`
- [ ] 有设备无数据：显示 `livestockTrajectoryEmpty`
- [ ] 仅 1 个点：滑动条禁用（max=0），地图居中
- [ ] **验证:** 统计实时更新，空状态正确显示

### Task 8: Bottom Sheet 布局组装 + 编译验证

- [ ] 组装 build()：Column（header + Expanded(map) + slider + controls + stats）
- [ ] 确保整体高度 = `MediaQuery.height * 0.75`
- [ ] 地图区域用 Expanded(flex: 1) 自适应剩余空间
- [ ] 所有 UI 元素紧凑化（padding/字号适配 sheet 空间预算）
- [ ] 运行 `flutter gen-l10n` 确认无缺失 key
- [ ] 运行 `flutter analyze` 确认无新增 warning
- [ ] 运行 `flutter build web` 确认编译通过
- [ ] **验证:** 编译通过，布局在 sheet 内不溢出

---

## 验收标准

- [ ] 移除 24h/7d/30d 三按钮，替换为滑动条
- [ ] 滑动条拖动时轨迹实时增长/收缩，脉冲标记移动
- [ ] 播放按钮可自动播放轨迹动画
- [ ] 支持 1x/2x/4x/8x 变速
- [ ] 范围选择器可切换 24h/7d/30d/自定义
- [ ] 采样上限根据上报周期动态计算
- [ ] 切换范围时显示加载指示器
- [ ] 跟随模式 + 全览按钮正常工作
- [ ] 统计数据随滑动条实时更新
- [ ] 空状态正确显示
- [ ] tile 源切换时坐标转换正常
- [ ] 中英文 i18n 完整同步
- [ ] `flutter analyze` 无新增 warning
- [ ] `flutter build web` 编译通过
- [ ] 布局在 75% 屏高 bottom sheet 内不溢出
