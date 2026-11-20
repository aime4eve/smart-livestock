# 测试用例规格：App·GPS 质量治理

> 用例域：IOT ｜ 用例数：34
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-IOT-001 | 预览展示真实解析行与汇总，ERROR 行默认排除且不可恢复 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/batch_import_preview_test.dart::预览展示真实解析行与汇总，ERROR 行默认排除且不可恢复` |
| TC-IOT-002 | 删除预览行后提交携带 excludeRows（含 ERROR 行） | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/batch_import_preview_test.dart::删除预览行后提交携带 excludeRows（含 ERROR 行）` |
| TC-IOT-003 | 结果页手动注册调 retryRegistration(checkIds=[该行checkId]) | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/batch_import_preview_test.dart::结果页手动注册调 retryRegistration(checkIds=[该行checkId])` |
| TC-IOT-004 | 结果页批量注册调 retryRegistration(全部) | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/batch_import_preview_test.dart::结果页批量注册调 retryRegistration(全部)` |
| TC-IOT-005 | search sends filters to the server and resets to the first page | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/checks_controller_test.dart::search sends filters to the server and resets to the first page` |
| TC-IOT-006 | load more appends the next page and keeps filters | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/checks_controller_test.dart::load more appends the next page and keeps filters` |
| TC-IOT-007 | 选择动态路线后展示多设备动态对比表 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/comparison_tab_test.dart::选择动态路线后展示多设备动态对比表` |
| TC-IOT-008 | parses counts and rows per backend contract | P1 | REQ-IOT-005、REQ-IOT-006、REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/features/admin/gps_quality/gps_quality_models_test.dart::parses counts and rows per backend contract` |
| TC-IOT-009 | tolerates missing optional fields | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/gps_quality_models_test.dart::tolerates missing optional fields` |
| TC-IOT-010 | parses device summaries per backend contract | P1 | REQ-IOT-005、REQ-IOT-006、REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/features/admin/gps_quality/gps_quality_models_test.dart::parses device summaries per backend contract` |
| TC-IOT-011 | 搜索框按 EUI 子串过滤设备分组（大小写不敏感） | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::搜索框按 EUI 子串过滤设备分组（大小写不敏感）` |
| TC-IOT-012 | 搜索无匹配时显示无匹配设备提示 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::搜索无匹配时显示无匹配设备提示` |
| TC-IOT-013 | 状态下拉过滤为待注册时仅显示待注册设备 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::状态下拉过滤为待注册时仅显示待注册设备` |
| TC-IOT-014 | 搜索首页外设备时通过后端 EUI 查询返回 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::搜索首页外设备时通过后端 EUI 查询返回` |
| TC-IOT-015 | 检验记录超过一页时可以加载更多 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::检验记录超过一页时可以加载更多` |
| TC-IOT-016 | 存在待注册检验时显示批量注册按钮，点击调 retryRegistration(全部) | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::存在待注册检验时显示批量注册按钮，点击调 retryRegistration(全部)` |
| TC-IOT-017 | 手动注册按钮调 retryRegistration(checkIds=[该设备待注册检验id]) | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::手动注册按钮调 retryRegistration(checkIds=[该设备待注册检验id])` |
| TC-IOT-018 | 删除设备按钮弹确认框，确认后调 deleteChecksByDevice | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::删除设备按钮弹确认框，确认后调 deleteChecksByDevice` |
| TC-IOT-019 | READY 状态设备也显示删除设备按钮 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::READY 状态设备也显示删除设备按钮` |
| TC-IOT-020 | 时间线段删除图标弹确认框，确认后调 deleteCheck(该检验id) | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::时间线段删除图标弹确认框，确认后调 deleteCheck(该检验id)` |
| TC-IOT-021 | 静态+轨迹泳道：两段均可独立点击选中 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::静态+轨迹泳道：两段均可独立点击选中` |
| TC-IOT-022 | 静态+轨迹泳道：轨迹段删除图标可正常触发 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::静态+轨迹泳道：轨迹段删除图标可正常触发` |
| TC-IOT-023 | renders route points and passes without error | P1 | REQ-IOT-005、REQ-IOT-006、REQ-PLT-001、REQ-PLT-002 | `Mobile/mobile_app/test/features/admin/gps_quality/route_match_chart_test.dart::renders route points and passes without error` |
| TC-IOT-024 | renders empty data without error | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/route_match_chart_test.dart::renders empty data without error` |
| TC-IOT-025 | renders single point (zero-range bounds) without error | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/route_match_chart_test.dart::renders single point (zero-range bounds) without error` |
| TC-IOT-026 | 默认选中点数最多的位置并隐藏位置列 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::默认选中点数最多的位置并隐藏位置列` |
| TC-IOT-027 | 全部位置显示位置列且搜索自动切换到全部位置 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::全部位置显示位置列且搜索自动切换到全部位置` |
| TC-IOT-028 | 坐标保留七位小数 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::坐标保留七位小数` |
| TC-IOT-029 | 点位编号按自然数字排序 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::点位编号按自然数字排序` |
| TC-IOT-030 | 纬度表头支持升降序切换 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::纬度表头支持升降序切换` |
| TC-IOT-031 | 删除当前唯一位置点后自动切回全部位置 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::删除当前唯一位置点后自动切回全部位置` |
| TC-IOT-032 | 搜索无匹配时显示专用空态和关键节点 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::搜索无匹配时显示专用空态和关键节点` |
| TC-IOT-033 | 窄屏显示横向位置导航和表格 | P1 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::窄屏显示横向位置导航和表格` |
| TC-IOT-034 | capture RTK panel visual states | P2 | REQ-IOT-005、REQ-IOT-006 | `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_visual_capture_test.dart::capture RTK panel visual states` |

## 用例明细（初稿模板）

### TC-IOT-001 预览展示真实解析行与汇总，ERROR 行默认排除且不可恢复

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/batch_import_preview_test.dart::预览展示真实解析行与汇总，ERROR 行默认排除且不可恢复`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-002 删除预览行后提交携带 excludeRows（含 ERROR 行）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/batch_import_preview_test.dart::删除预览行后提交携带 excludeRows（含 ERROR 行）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-003 结果页手动注册调 retryRegistration(checkIds=[该行checkId])

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/batch_import_preview_test.dart::结果页手动注册调 retryRegistration(checkIds=[该行checkId])`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-004 结果页批量注册调 retryRegistration(全部)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/batch_import_preview_test.dart::结果页批量注册调 retryRegistration(全部)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-005 search sends filters to the server and resets to the first page

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/checks_controller_test.dart::search sends filters to the server and resets to the first page`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-006 load more appends the next page and keeps filters

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/checks_controller_test.dart::load more appends the next page and keeps filters`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-007 选择动态路线后展示多设备动态对比表

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/comparison_tab_test.dart::选择动态路线后展示多设备动态对比表`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-008 parses counts and rows per backend contract

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：BatchParseResult.fromJson
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/gps_quality_models_test.dart::parses counts and rows per backend contract`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-CMC-004、REQ-CMC-005

### TC-IOT-009 tolerates missing optional fields

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/gps_quality_models_test.dart::tolerates missing optional fields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-010 parses device summaries per backend contract

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DynamicComparisonResult.fromJson
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/gps_quality_models_test.dart::parses device summaries per backend contract`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-CMC-004、REQ-CMC-005

### TC-IOT-011 搜索框按 EUI 子串过滤设备分组（大小写不敏感）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::搜索框按 EUI 子串过滤设备分组（大小写不敏感）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-012 搜索无匹配时显示无匹配设备提示

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::搜索无匹配时显示无匹配设备提示`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-013 状态下拉过滤为待注册时仅显示待注册设备

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::状态下拉过滤为待注册时仅显示待注册设备`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-014 搜索首页外设备时通过后端 EUI 查询返回

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::搜索首页外设备时通过后端 EUI 查询返回`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-015 检验记录超过一页时可以加载更多

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::检验记录超过一页时可以加载更多`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-016 存在待注册检验时显示批量注册按钮，点击调 retryRegistration(全部)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::存在待注册检验时显示批量注册按钮，点击调 retryRegistration(全部)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-017 手动注册按钮调 retryRegistration(checkIds=[该设备待注册检验id])

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::手动注册按钮调 retryRegistration(checkIds=[该设备待注册检验id])`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-018 删除设备按钮弹确认框，确认后调 deleteChecksByDevice

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::删除设备按钮弹确认框，确认后调 deleteChecksByDevice`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-003、REQ-IOT-004

### TC-IOT-019 READY 状态设备也显示删除设备按钮

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::READY 状态设备也显示删除设备按钮`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-020 时间线段删除图标弹确认框，确认后调 deleteCheck(该检验id)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::时间线段删除图标弹确认框，确认后调 deleteCheck(该检验id)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-021 静态+轨迹泳道：两段均可独立点击选中

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::静态+轨迹泳道：两段均可独立点击选中`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-022 静态+轨迹泳道：轨迹段删除图标可正常触发

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/quality_check_list_test.dart::静态+轨迹泳道：轨迹段删除图标可正常触发`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-023 renders route points and passes without error

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/route_match_chart_test.dart::renders route points and passes without error`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-PLT-001、REQ-PLT-002

### TC-IOT-024 renders empty data without error

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/route_match_chart_test.dart::renders empty data without error`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-025 renders single point (zero-range bounds) without error

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/route_match_chart_test.dart::renders single point (zero-range bounds) without error`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-026 默认选中点数最多的位置并隐藏位置列

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::默认选中点数最多的位置并隐藏位置列`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-027 全部位置显示位置列且搜索自动切换到全部位置

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::全部位置显示位置列且搜索自动切换到全部位置`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-028 坐标保留七位小数

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::坐标保留七位小数`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-029 点位编号按自然数字排序

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::点位编号按自然数字排序`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-030 纬度表头支持升降序切换

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::纬度表头支持升降序切换`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-031 删除当前唯一位置点后自动切回全部位置

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::删除当前唯一位置点后自动切回全部位置`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-032 搜索无匹配时显示专用空态和关键节点

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::搜索无匹配时显示专用空态和关键节点`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-033 窄屏显示横向位置导航和表格

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_test.dart::窄屏显示横向位置导航和表格`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

### TC-IOT-034 capture RTK panel visual states

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/gps_quality/truth_reference_tab_visual_capture_test.dart::capture RTK panel visual states`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006

