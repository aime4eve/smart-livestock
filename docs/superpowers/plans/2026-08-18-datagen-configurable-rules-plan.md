# 仿真规则手工配置实施计划

> 日期：2026-08-18
> spec：`docs/superpowers/specs/2026-08-18-datagen-configurable-rules-design.md`

## Task 1 — 数据模型

- [ ] 新增 Flyway 迁移：`datagen_farm_controls` 追加 10 个规则字段并回填默认值。
- [ ] 每列添加 CHECK；持续范围所在行满足 `min <= max`。
- [ ] 领域模型、JPA entity、mapper 同步字段。
- [ ] 新建 `DatagenFarmRules` 值对象，保留当前默认值。

## Task 2 — 控制台 API 与审计

- [ ] 新增 `DatagenRulesDto`，console 响应携带 `rules`。
- [ ] 新增 `PUT /admin/datagen/rules/{farmId}`。
- [ ] 复用 PLATFORM_ADMIN/B2B_ADMIN 权限与 farm 租户校验。
- [ ] 后端校验所有范围和 `min <= max`。
- [ ] 保存规则写 `UPDATE_RULES` 审计。
- [ ] 运行中保存后清除 active 设备 due schedule。

## Task 3 — 生成引擎

- [ ] `ActiveInstallationInfo` 携带 farm rules；兼容构造器使用默认规则。
- [ ] `DeviceQueryPortImpl` 从 control 填充规则。
- [ ] TRACKER/CAPSULE due 间隔改为动态规则。
- [ ] 围栏外出概率与持续范围改为动态规则。
- [ ] 健康异常触发概率改为动态规则。
- [ ] 发热与消化动力下降分别使用独立持续范围，语义保持 50/50。

## Task 4 — Flutter

- [ ] domain model 增加 rules 与 fromJson。
- [ ] repository 增加 updateRules。
- [ ] controller 增加 rules 保存状态与刷新。
- [ ] 运行状态页签改为可编辑表单。
- [ ] 概率 UI 使用百分比，小时/分钟单位转换为 API 字段。
- [ ] 操作记录支持 `UPDATE_RULES`。
- [ ] 中英文 ARB 同步，删除误导性的统一健康持续文案。
- [ ] model/controller/widget 测试覆盖解析、保存和表单展示。

## Task 5 — 验证与交付

- [ ] 后端 datagen 测试与编译。
- [ ] Flutter gen-l10n、datagen 测试、analyze、release web。
- [ ] test/dev 部署后验证迁移、默认值、规则保存、审计与下一批生成节奏。
- [ ] API contract 更新新 endpoint 与 rules 字段。
- [ ] 仅提交本任务文件并推送。
