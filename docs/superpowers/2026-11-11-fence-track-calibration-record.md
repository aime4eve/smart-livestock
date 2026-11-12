# 真机校准记录：从设备轨迹生成围栏草图（2026-11-11）

> 依据：spec §9.1（`docs/superpowers/specs/2026-11-11-fence-from-device-track-spec.md`）

## 结论：校准顺延（数据前置条件不满足）

dev 环境盘点 SQL（按设备 × source 统计近 30 天 `gps_logs`，2026-11-11 执行）：

| source | 点数 | 占比 | 说明 |
|---|---|---|---|
| DATAGEN | 331,810 | 98.1% | 合成随机游走，**禁用为校准依据**（AGENTS.md AI 仿真条款） |
| THINGSBOARD | 6,373 | 1.9% | 真实通道 |

真实（THINGSBOARD）设备明细：

| 设备 | 点数 | 覆盖 | 天数 |
|---|---|---|---|
| TB-175-00956906001264be | 5,439 | 10-13 ~ 11-11 | 21 天 |
| HUB-00956906001267d6 | 893 | 10-13 ~ 10-19 | 5 天（网关） |
| HUB-00956906001264ef | 41 | 10-19 ~ 10-20 | 2 天（网关） |

spec §9.1 门槛为「≥2 牧场 ≥3 台在册追踪器 ≥14 天」，dev 当前仅 **1 台真实追踪器** 达标，不满足校准前置条件。

## 顺延安排

- 参数组暂用初值（`TrackDraftParams.animalTrack()`：accuracyThresholdM=40、lMaxBaseM=40、roamingQuantile=0.95，见 `Mobile/mobile_app/lib/features/fence/domain/track_draft_params.dart`），端到端功能验证已用 DATAGEN 数据完成（验证的是功能链路，非参数效果）。
- 校准触发条件：任一环境真实追踪器数据满足门槛后，执行 spec §9.1 四条验收（面积偏差 ≤15%、顶点 ≤100、VM/JS 输出一致、被裁点无连续成片真实活动段）。
- 校准只需改 `track_draft_params.dart` 一处参数值，不改管线结构。

## 功能端到端验证记录（dev，2026-11-11）

- 全链路：新增围栏 →「从设备轨迹生成」→ 选 2 台设备（DEV-GPS-011/012）→ 近 14 天 → 预览（7,802 原始点 → stride 2 → 3,705 有效 + 195 漫游剔除 → 凹包 29 顶点、32.7 亩）→ 载入围栏表单（建议名「轨迹围栏 11-11」、多边形）→ 保存（fence id=17）→ 详情双挂载点来源卡回显（ranch 详情卡 + 围栏管理列表卡）。
- API 冒烟：candidates（39 台 + fenceQuota）、source（升序、stride=2、0.26s）、400 校验三分支、POST /fences 带 metadata 往返（已清理冒烟围栏）。
- 迁移：dev 存量库启动即过 + Testcontainers 全新库集成测试全绿（remote-integration-test.sh）。
- 端到端抓出并修复 2 个集成断链：① 后端 RanchOverviewDto.FenceData 漏传 metadata；② ranch 页 signalFences 信号几何映射丢 metadata（两处详情数据源之一）。
