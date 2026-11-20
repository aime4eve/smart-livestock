# 测试用例规格：App·设备管理

> 用例域：IOT ｜ 用例数：44
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-IOT-035 | accepts a bare 16-hex-digit EUI and lowercases it | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/device_eui_test.dart::accepts a bare 16-hex-digit EUI and lowercases it` |
| TC-IOT-036 | trims surrounding whitespace before matching | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/device_eui_test.dart::trims surrounding whitespace before matching` |
| TC-IOT-037 | extracts a bounded EUI from wider payloads | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/device_eui_test.dart::extracts a bounded EUI from wider payloads` |
| TC-IOT-038 | rejects payloads without a bounded 16-hex-digit run | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/device_eui_test.dart::rejects payloads without a bounded 16-hex-digit run` |
| TC-IOT-039 | device dialog uses unwrapped farm API responses | P1 | REQ-HLT-005、REQ-HLT-033、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/devices/device_health_dialog_test.dart::device dialog uses unwrapped farm API responses` |
| TC-IOT-040 | GPS tracker with all telemetry fields | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::GPS tracker with all telemetry fields` |
| TC-IOT-041 | rumen capsule with capsule alias | P1 | REQ-HLT-001、REQ-HLT-002、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::rumen capsule with capsule alias` |
| TC-IOT-042 | ear tag type | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::ear tag type` |
| TC-IOT-043 | unknown deviceType returns null (graceful skip) | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::unknown deviceType returns null (graceful skip)` |
| TC-IOT-044 | missing deviceType returns null | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::missing deviceType returns null` |
| TC-IOT-045 | status alias ACTIVE maps to online | P1 | REQ-RCH-002、REQ-RCH-006、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::status alias ACTIVE maps to online` |
| TC-IOT-046 | unknown status defaults to offline | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::unknown status defaults to offline` |
| TC-IOT-047 | anti-disassembly status non-zero triggers tamper alert | P1 | REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::anti-disassembly status non-zero triggers tamper alert` |
| TC-IOT-048 | GPS alias for deviceType | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::GPS alias for deviceType` |
| TC-IOT-049 | CAPSULE alias for deviceType | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::CAPSULE alias for deviceType` |
| TC-IOT-050 | platformDeviceId as string preserves value | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::platformDeviceId as string preserves value` |
| TC-IOT-051 | large platformDeviceId preserves precision as string | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::large platformDeviceId preserves precision as string` |
| TC-IOT-052 | null platformDeviceId means isPlatformRegistered false | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::null platformDeviceId means isPlatformRegistered false` |
| TC-IOT-053 | case-insensitive type and status | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::case-insensitive type and status` |
| TC-IOT-054 | full license data | P1 | REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IOT-001 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::full license data` |
| TC-IOT-055 | int id converted to string | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::int id converted to string` |
| TC-IOT-056 | missing fields default to empty/active | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::missing fields default to empty/active` |
| TC-IOT-057 | full installation data | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::full installation data` |
| TC-IOT-058 | int ids converted to string | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::int ids converted to string` |
| TC-IOT-059 | lat/lng aliases | P1 | REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::lat/lng aliases` |
| TC-IOT-060 | latitude/longitude full names | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::latitude/longitude full names` |
| TC-IOT-061 | missing coords default to 0.0 | P1 | REQ-RCH-002、REQ-RCH-006、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::missing coords default to 0.0` |
| TC-IOT-062 | int coords converted to double | P1 | REQ-RCH-002、REQ-RCH-006、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::int coords converted to double` |
| TC-IOT-063 | build loads first page with correct defaults | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::build loads first page with correct defaults` |
| TC-IOT-064 | search sets keyword and resets to page 1 | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::search sets keyword and resets to page 1` |
| TC-IOT-065 | goToPage fetches the requested page | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::goToPage fetches the requested page` |
| TC-IOT-066 | goToPage ignores invalid page numbers | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::goToPage ignores invalid page numbers` |
| TC-IOT-067 | refresh reloads current page | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::refresh reloads current page` |
| TC-IOT-068 | farm switch rebuilds controller | P1 | REQ-IDT-001、REQ-IDT-003、REQ-IOT-001、REQ-IOT-002 | `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::farm switch rebuilds controller` |
| TC-IOT-069 | totalPages computed from total / pageSize | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::totalPages computed from total / pageSize` |
| TC-IOT-070 | parses TB preflight payload | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::parses TB preflight payload` |
| TC-IOT-071 | capsule hides GPS actions and shows health action | P1 | REQ-IOT-005、REQ-IOT-006、REQ-HLT-005、REQ-HLT-033 | `Mobile/mobile_app/test/features/devices/highfi_device_tile_test.dart::capsule hides GPS actions and shows health action` |
| TC-IOT-072 | ear tag shows trajectory action | P1 | REQ-RCH-007、REQ-RCH-002、REQ-RCH-006、REQ-IOT-001 | `Mobile/mobile_app/test/features/devices/highfi_device_tile_test.dart::ear tag shows trajectory action` |
| TC-IOT-073 | device type GPS capability | P1 | REQ-IOT-005、REQ-IOT-006、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/features/devices/highfi_device_tile_test.dart::device type GPS capability` |
| TC-IOT-074 | reopening the wizard after a successful provision starts from the input step | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/tb_device_wizard_reopen_test.dart::reopening the wizard after a successful provision starts from the input step` |
| TC-IOT-075 | the confirm step offers a back button returning to the input step | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/tb_device_wizard_reopen_test.dart::the confirm step offers a back button returning to the input step` |
| TC-IOT-076 | the result step offers provisioning another device from a clean input | P1 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/tb_device_wizard_reopen_test.dart::the result step offers provisioning another device from a clean input` |
| TC-IOT-077 | the wizard title row offers a close button that dismisses the sheet | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-IOT-001 | `Mobile/mobile_app/test/features/devices/tb_device_wizard_reopen_test.dart::the wizard title row offers a close button that dismisses the sheet` |
| TC-IOT-078 | captures TB wizard confirm and result states | P2 | REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009 | `Mobile/mobile_app/test/features/devices/tb_device_wizard_visual_test.dart::captures TB wizard confirm and result states` |

## 用例明细（初稿模板）

### TC-IOT-035 accepts a bare 16-hex-digit EUI and lowercases it

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：parseDeviceEui
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/device_eui_test.dart::accepts a bare 16-hex-digit EUI and lowercases it`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-036 trims surrounding whitespace before matching

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/device_eui_test.dart::trims surrounding whitespace before matching`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-037 extracts a bounded EUI from wider payloads

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/device_eui_test.dart::extracts a bounded EUI from wider payloads`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-038 rejects payloads without a bounded 16-hex-digit run

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/device_eui_test.dart::rejects payloads without a bounded 16-hex-digit run`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-039 device dialog uses unwrapped farm API responses

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/device_health_dialog_test.dart::device dialog uses unwrapped farm API responses`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-IDT-001、REQ-IDT-003

### TC-IOT-040 GPS tracker with all telemetry fields

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：DevicesApiRepository._parseDeviceItem
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::GPS tracker with all telemetry fields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-041 rumen capsule with capsule alias

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::rumen capsule with capsule alias`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-001、REQ-HLT-002、REQ-IOT-001、REQ-IOT-002

### TC-IOT-042 ear tag type

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::ear tag type`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-043 unknown deviceType returns null (graceful skip)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::unknown deviceType returns null (graceful skip)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-044 missing deviceType returns null

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::missing deviceType returns null`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-045 status alias ACTIVE maps to online

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::status alias ACTIVE maps to online`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-046 unknown status defaults to offline

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::unknown status defaults to offline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-047 anti-disassembly status non-zero triggers tamper alert

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::anti-disassembly status non-zero triggers tamper alert`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-008、REQ-RCH-009、REQ-RCH-010、REQ-PLT-001

### TC-IOT-048 GPS alias for deviceType

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::GPS alias for deviceType`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-049 CAPSULE alias for deviceType

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::CAPSULE alias for deviceType`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-050 platformDeviceId as string preserves value

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::platformDeviceId as string preserves value`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-051 large platformDeviceId preserves precision as string

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::large platformDeviceId preserves precision as string`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-052 null platformDeviceId means isPlatformRegistered false

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::null platformDeviceId means isPlatformRegistered false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-053 case-insensitive type and status

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::case-insensitive type and status`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-054 full license data

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：parseLicenseForTest
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::full license data`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-006、REQ-CMC-007、REQ-IOT-001

### TC-IOT-055 int id converted to string

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::int id converted to string`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-056 missing fields default to empty/active

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::missing fields default to empty/active`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-057 full installation data

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：parseInstallationForTest
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::full installation data`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-058 int ids converted to string

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::int ids converted to string`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-059 lat/lng aliases

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：parseGpsPointForTest
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::lat/lng aliases`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-060 latitude/longitude full names

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::latitude/longitude full names`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-061 missing coords default to 0.0

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::missing coords default to 0.0`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-062 int coords converted to double

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_api_repository_test.dart::int coords converted to double`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-IOT-001、REQ-IOT-002

### TC-IOT-063 build loads first page with correct defaults

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::build loads first page with correct defaults`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-064 search sets keyword and resets to page 1

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::search sets keyword and resets to page 1`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-065 goToPage fetches the requested page

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::goToPage fetches the requested page`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-066 goToPage ignores invalid page numbers

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::goToPage ignores invalid page numbers`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-067 refresh reloads current page

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::refresh reloads current page`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-068 farm switch rebuilds controller

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::farm switch rebuilds controller`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-IOT-001、REQ-IOT-002

### TC-IOT-069 totalPages computed from total / pageSize

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::totalPages computed from total / pageSize`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-070 parses TB preflight payload

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/devices_controller_test.dart::parses TB preflight payload`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-071 capsule hides GPS actions and shows health action

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/highfi_device_tile_test.dart::capsule hides GPS actions and shows health action`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-HLT-005、REQ-HLT-033

### TC-IOT-072 ear tag shows trajectory action

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/highfi_device_tile_test.dart::ear tag shows trajectory action`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-007、REQ-RCH-002、REQ-RCH-006、REQ-IOT-001

### TC-IOT-073 device type GPS capability

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/highfi_device_tile_test.dart::device type GPS capability`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-005、REQ-IOT-006、REQ-RCH-002、REQ-RCH-006

### TC-IOT-074 reopening the wizard after a successful provision starts from the input step

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/tb_device_wizard_reopen_test.dart::reopening the wizard after a successful provision starts from the input step`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-075 the confirm step offers a back button returning to the input step

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/tb_device_wizard_reopen_test.dart::the confirm step offers a back button returning to the input step`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-076 the result step offers provisioning another device from a clean input

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/tb_device_wizard_reopen_test.dart::the result step offers provisioning another device from a clean input`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

### TC-IOT-077 the wizard title row offers a close button that dismisses the sheet

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/tb_device_wizard_reopen_test.dart::the wizard title row offers a close button that dismisses the sheet`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-IOT-001

### TC-IOT-078 captures TB wizard confirm and result states

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/devices/tb_device_wizard_visual_test.dart::captures TB wizard confirm and result states`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-IOT-008、REQ-IOT-009

