# 高保真 UX 验收与冻结记录

> 日期：2026-03-27  
> 范围：智慧畜牧 App 高保真前端基线（Task 1-8）

---

## 自动化验收门禁

- [x] Dashboard 关键块完整
  - `dashboard-farm-header`
  - `dashboard-quick-fence`
- [x] Map 关键块完整
  - `map-toolbar-draw-fence`
  - `map-layer-fence-toggle`
- [x] Alerts 关键块完整
  - `alert-type-fence-breach`
  - `alert-type-battery-low`
  - `alert-type-signal-lost`
- [x] 围栏场景可演示
  - 模板：`矩形` / `圆形` / `不规则`
  - 分组：`fence-group-chip`
  - 图层：`map-layer-fence-toggle`
- [x] 六类状态不回归
  - `normal/loading/empty/error/forbidden/offline`
- [x] 角色权限不回归
  - `worker` 无后台 tab
  - `owner` 可见围栏编辑与后台入口
  - `ops` 直达后台且无业务底栏

---

## 手工演示验收

- [ ] 使用 `docs/demo/highfi-review-script.md` 完成 10 分钟演示
- [ ] Mock 模式演示通过
- [ ] Live 联调壳模式演示通过（当前允许内部回退 mock datasource）
- [ ] 记录现场反馈

---

## 保留项

- 自然牧场风 C2 视觉方向继续保留
- Dashboard / Map / Alerts 作为高保真标杆页保留
- mock/live 双模式入口与 `APP_MODE` 机制保留

## 修改项

- 如进入下一轮，可继续提升 `DemoShell` 导航条视觉统一度
- 围栏分组与模板可进一步扩成更完整的可选面板

## 新增项

- 后续可补充真正的手工演示结论、参与人和日期
- 进入联调前可新增 `flutter analyze` 输出截图或命令记录

## 冻结项

- 当前高保真前端基线可冻结为 Phase 0 交付版本
- 后续优先转入联调准备与后端主线，不再大改核心视觉结构
