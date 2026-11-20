# 测试用例规格：App·管理员工具

> 用例域：PLT ｜ 用例数：16
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-PLT-142 | renders rules with type badges, switches and disabled rows | P2 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/admin/device_profile_rules_page_test.dart::renders rules with type badges, switches and disabled rows` |
| TC-PLT-143 | delete requires confirmation and calls the API | P2 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/admin/device_profile_rules_page_test.dart::delete requires confirmation and calls the API` |
| TC-PLT-144 | create form blocks duplicate names locally | P2 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/admin/device_profile_rules_page_test.dart::create form blocks duplicate names locally` |
| TC-PLT-145 | renders the loaded policy as the selected segment | P2 | REQ-CMC-003、REQ-CMC-009 | `Mobile/mobile_app/test/features/admin/feature_gate_page_test.dart::renders the loaded policy as the selected segment` |
| TC-PLT-146 | switching a segment PUTs the policy and toasts success | P2 | REQ-CMC-003、REQ-CMC-009 | `Mobile/mobile_app/test/features/admin/feature_gate_page_test.dart::switching a segment PUTs the policy and toasts success` |
| TC-PLT-147 | a failed PUT rolls the selection back and toasts the failure | P2 | REQ-CMC-003、REQ-CMC-009 | `Mobile/mobile_app/test/features/admin/feature_gate_page_test.dart::a failed PUT rolls the selection back and toasts the failure` |
| TC-PLT-148 | 完整 JSON 解析：统计 + 设备匹配 + 逐行状态 | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::完整 JSON 解析：统计 + 设备匹配 + 逐行状态` |
| TC-PLT-149 | 状态枚举映射：五态 + 未知兜底 unknown | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::状态枚举映射：五态 + 未知兜底 unknown` |
| TC-PLT-150 | 防御性解析：缺字段/类型偏差不抛异常 | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::防御性解析：缺字段/类型偏差不抛异常` |
| TC-PLT-151 | 设备未匹配：error key 保留 | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::设备未匹配：error key 保留` |
| TC-PLT-152 | 数值强转：int 经纬度转 double、num 计数转 int | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::数值强转：int 经纬度转 double、num 计数转 int` |
| TC-PLT-153 | 完整 JSON 解析 | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::完整 JSON 解析` |
| TC-PLT-154 | 防御性解析：空 JSON 全默认值 | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::防御性解析：空 JSON 全默认值` |
| TC-PLT-155 | 选中文件后进入解析预览：统计条/设备卡已匹配/预览表前 8 行 | P2 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_page_test.dart::选中文件后进入解析预览：统计条/设备卡已匹配/预览表前 8 行` |
| TC-PLT-156 | 确认导入进入结果页，「继续导入其他文件」回到上传步 | P2 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_page_test.dart::确认导入进入结果页，「继续导入其他文件」回到上传步` |
| TC-PLT-157 | 设备未匹配：设备卡红态 + 导入按钮禁用且不调 import | P2 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004 | `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_page_test.dart::设备未匹配：设备卡红态 + 导入按钮禁用且不调 import` |

## 用例明细（初稿模板）

### TC-PLT-142 renders rules with type badges, switches and disabled rows

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/device_profile_rules_page_test.dart::renders rules with type badges, switches and disabled rows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-PLT-143 delete requires confirmation and calls the API

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/device_profile_rules_page_test.dart::delete requires confirmation and calls the API`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-PLT-144 create form blocks duplicate names locally

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/device_profile_rules_page_test.dart::create form blocks duplicate names locally`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-PLT-145 renders the loaded policy as the selected segment

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/feature_gate_page_test.dart::renders the loaded policy as the selected segment`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009

### TC-PLT-146 switching a segment PUTs the policy and toasts success

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/feature_gate_page_test.dart::switching a segment PUTs the policy and toasts success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009

### TC-PLT-147 a failed PUT rolls the selection back and toasts the failure

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/feature_gate_page_test.dart::a failed PUT rolls the selection back and toasts the failure`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-003、REQ-CMC-009

### TC-PLT-148 完整 JSON 解析：统计 + 设备匹配 + 逐行状态

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：TelemetryParseResult.fromJson
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::完整 JSON 解析：统计 + 设备匹配 + 逐行状态`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-149 状态枚举映射：五态 + 未知兜底 unknown

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::状态枚举映射：五态 + 未知兜底 unknown`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-150 防御性解析：缺字段/类型偏差不抛异常

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::防御性解析：缺字段/类型偏差不抛异常`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-151 设备未匹配：error key 保留

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::设备未匹配：error key 保留`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-152 数值强转：int 经纬度转 double、num 计数转 int

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::数值强转：int 经纬度转 double、num 计数转 int`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-153 完整 JSON 解析

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：TelemetryImportResult.fromJson
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::完整 JSON 解析`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-154 防御性解析：空 JSON 全默认值

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_models_test.dart::防御性解析：空 JSON 全默认值`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-155 选中文件后进入解析预览：统计条/设备卡已匹配/预览表前 8 行

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_page_test.dart::选中文件后进入解析预览：统计条/设备卡已匹配/预览表前 8 行`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-156 确认导入进入结果页，「继续导入其他文件」回到上传步

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_page_test.dart::确认导入进入结果页，「继续导入其他文件」回到上传步`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

### TC-PLT-157 设备未匹配：设备卡红态 + 导入按钮禁用且不调 import

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/admin/telemetry_import/telemetry_import_page_test.dart::设备未匹配：设备卡红态 + 导入按钮禁用且不调 import`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-003、REQ-IOT-004

