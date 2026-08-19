# 仿真规则手工配置设计

> 日期：2026-08-18
> 状态：用户已确认
> 基线功能：`docs/superpowers/specs/2026-08-17-datagen-admin-console-design.md`
> 原型：`docs/marketing/datagen-console-prototype.html`

## 1. 目标

将仿真控制台“当前规则”从只读摘要升级为按牧场保存的手工配置。平台管理员与 B2B 管理员沿用现有仿真控制权限；规则修改写入审计，并在下一批调度生效。

## 2. 配置项

| 配置 | 默认值 | 允许范围 | 说明 |
|---|---:|---:|---|
| TRACKER 上报间隔 | 5 分钟 | 1-60 分钟 | 控制追踪器 telemetry/GPS 频率 |
| CAPSULE 上报间隔 | 15 分钟 | 5-120 分钟 | 控制胶囊健康数据频率 |
| 围栏外出触发概率 | 2% | 0-20% | 每次追踪器基线生成时判定 |
| 围栏外出持续时间 | 10-30 分钟 | 5-120 分钟，min <= max | 外出结束后连续走回围栏 |
| 健康异常触发概率 | 0.5% | 0-10% | 每次胶囊基线生成时判定 |
| 发热持续时间 | 4-8 小时 | 2-24 小时，min <= max | 对应现有 FEVER 事件 |
| 消化动力下降持续时间 | 8-12 小时 | 2-24 小时，min <= max | 对应现有 MOTILITY_DROP 事件 |

健康异常保持现有语义：触发后 50/50 选择发热或消化动力下降，两类持续时间不合并。

## 3. 数据与 API

规则字段保存在 `datagen_farm_controls`，与 farm 开关同生命周期：

```text
tracker_interval_seconds
capsule_interval_seconds
fence_excursion_probability
fence_excursion_min_minutes
fence_excursion_max_minutes
health_event_probability
fever_duration_min_minutes
fever_duration_max_minutes
motility_duration_min_minutes
motility_duration_max_minutes
```

新增：

```http
PUT /api/v1/admin/datagen/rules/{farmId}
```

请求与响应字段使用秒/分钟与概率小数；例如 `2%` 传 `0.02`，`0.5%` 传 `0.005`。console 响应新增 `rules`。后端校验所有范围、`min <= max` 与角色权限。

## 4. 生成链路

`ActiveInstallationInfo` 携带对应 farm 的规则快照：

- per-device due time 使用该设备类型的配置间隔；
- 围栏外出概率与持续范围使用该 farm 配置；
- 健康异常触发概率使用该 farm 配置；
- 发热与消化动力下降分别使用各自持续范围；
- 运行中保存规则后清除该 farm 当前 active 设备 due schedule，下一 tick 按新规则生成；
- 不清除运动/健康状态，避免轨迹或正在进行的异常事件跳变。

## 5. UI 与审计

运行状态页签的“当前规则”改为规则表单：

- 数值输入显示业务单位：分钟、小时、百分比；
- 概率输入为百分比，提交时转换为小数；
- 发热与消化动力下降显示两个独立范围；
- 保存按钮仅提交规则，不改变启停状态和设备范围；
- 操作记录新增 `UPDATE_RULES`。
