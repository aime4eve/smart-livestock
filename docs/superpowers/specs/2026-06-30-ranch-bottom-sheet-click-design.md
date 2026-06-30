# 牧场底部面板点击交互优化

## 问题

`HealthBottomSheet` 底部面板当前点击手柄区循环切换吸附层级（peek→half→full→peek），语义模糊。PC 鼠标用户无法通过拖拽操作面板，循环切换也缺乏方向感。

## 目标

- **手机端**：拖拽手势照旧 + 点击手柄区有明确方向提示
- **PC 端**：鼠标点击手柄区即可完成三级切换，不需拖拽

## 方案

### 点击改为「向上展开」

当前 `_cycleSnap`：peek → half → full → peek（循环）

改为：

```
peek  → 点击 → half
half  → 点击 → full
full  → 点击 → peek（收起到底）
```

### 手柄区加动态 chevron 图标

在 peek bar 右侧加一个 `Icon`，根据当前 `_snap` 状态显示不同方向和语义：

| snap | 图标 | 含义 |
|------|------|------|
| peek | `Icons.keyboard_arrow_up` | 点击展开到半屏 |
| half | `Icons.keyboard_arrow_up` | 点击展开到全屏 |
| full | `Icons.keyboard_arrow_down` | 点击收起到 peek |

### 拖拽逻辑不变

`_onVerticalDragStart` / `_onVerticalDragEnd` 保持原样。上下滑超过 40px 切换层级的逻辑不修改。

## 涉及文件

仅一个文件：`Mobile/mobile_app/lib/features/ranch/presentation/widgets/health_bottom_sheet.dart`

### 改动点

1. `_cycleSnap` 方法（第 50-54 行）—— 循环改为单向展开
2. `_buildPeekBar` 方法（第 149 行起）—— Row 的 children 末尾追加 chevron 图标

## 验收标准

- [ ] peek 状态点击手柄区 → 面板展开到 half
- [ ] half 状态点击手柄区 → 面板展开到 full
- [ ] full 状态点击手柄区 → 面板收起到 peek
- [ ] 手机端上下拖拽面板照常工作，吸附阈值 40px 不变
- [ ] peek/half 状态手柄区右侧显示 ▲ 图标，full 显示 ▼ 图标
- [ ] `flutter analyze` 通过
- [ ] 相关 widget 测试通过
