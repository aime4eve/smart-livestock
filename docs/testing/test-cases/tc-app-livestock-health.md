# 测试用例规格：App·牲畜档案/牧场地图/健康页

> 用例域：RCH ｜ 用例数：51
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-RCH-210 | full summary with all fields | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::full summary with all fields` |
| TC-RCH-211 | int id converted to string | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::int id converted to string` |
| TC-RCH-212 | CRITICAL health maps to abnormal | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::CRITICAL health maps to abnormal` |
| TC-RCH-213 | null healthStatus defaults to healthy | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::null healthStatus defaults to healthy` |
| TC-RCH-214 | lowercase healthStatus still maps correctly | P1 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::lowercase healthStatus still maps correctly` |
| TC-RCH-215 | earTag fallback from earTag when livestockCode absent | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::earTag fallback from earTag when livestockCode absent` |
| TC-RCH-216 | unknown breed maps to Breed.other | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::unknown breed maps to Breed.other` |
| TC-RCH-217 | null breed maps to Breed.other | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::null breed maps to Breed.other` |
| TC-RCH-218 | int fenceId converted to string | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::int fenceId converted to string` |
| TC-RCH-219 | null coords are null | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::null coords are null` |
| TC-RCH-220 | invalid birthDate string produces null DateTime | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::invalid birthDate string produces null DateTime` |
| TC-RCH-221 | full detail with all fields | P1 | REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::full detail with all fields` |
| TC-RCH-222 | weight fallback from weight when weightKg absent | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::weight fallback from weight when weightKg absent` |
| TC-RCH-223 | missing ageMonths defaults to 24 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::missing ageMonths defaults to 24` |
| TC-RCH-224 | missing bodyTemp defaults to 38.5 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::missing bodyTemp defaults to 38.5` |
| TC-RCH-225 | missing activityLevel defaults to 正常 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::missing activityLevel defaults to 正常` |
| TC-RCH-226 | missing ruminationFreq defaults to -- | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::missing ruminationFreq defaults to --` |
| TC-RCH-227 | missing location shows dashes | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::missing location shows dashes` |
| TC-RCH-228 | markedSource parses disease, stamp and contact count | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::markedSource parses disease, stamp and contact count` |
| TC-RCH-229 | absent or malformed markedSource falls back to unmarked | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::absent or malformed markedSource falls back to unmarked` |
| TC-RCH-230 | build loads first page | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::build loads first page` |
| TC-RCH-231 | search sets keyword and resets to page 1 | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::search sets keyword and resets to page 1` |
| TC-RCH-232 | goToPage fetches requested page | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::goToPage fetches requested page` |
| TC-RCH-233 | goToPage ignores out-of-range pages | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::goToPage ignores out-of-range pages` |
| TC-RCH-234 | refresh reloads current page | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::refresh reloads current page` |
| TC-RCH-235 | farm switch triggers rebuild | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::farm switch triggers rebuild` |
| TC-RCH-236 | LivestockDetailController loads by id | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::LivestockDetailController loads by id` |
| TC-RCH-237 | LivestockDetailController refresh reloads detail | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::LivestockDetailController refresh reloads detail` |
| TC-RCH-238 | renders priority badges, +N, and rumen metrics | P1 | REQ-HLT-001、REQ-HLT-002、REQ-PLT-001、REQ-PLT-002 | `Mobile/mobile_app/test/features/livestock/livestock_signal_summary_test.dart::renders priority badges, +N, and rumen metrics` |
| TC-RCH-239 | renders return home as a separate presence badge | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `Mobile/mobile_app/test/features/livestock/livestock_signal_summary_test.dart::renders return home as a separate presence badge` |
| TC-RCH-240 | renders livestock code, risk band colour, window and assessed time | P2 | REQ-HLT-004、REQ-HLT-025、REQ-PLT-001、REQ-PLT-002 | `Mobile/mobile_app/test/features/pages/calving_page_test.dart::renders livestock code, risk band colour, window and assessed time` |
| TC-RCH-241 | empty list renders the calm empty state | P2 | REQ-HLT-004、REQ-HLT-025 | `Mobile/mobile_app/test/features/pages/calving_page_test.dart::empty list renders the calm empty state` |
| TC-RCH-242 | NORMALIZED-V2 全通道:分量+权重渲染、倍数句、LEARNED 基线、标尺指针 | P2 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024 | `Mobile/mobile_app/test/features/pages/estrus_detail_page_test.dart::NORMALIZED-V2 全通道:分量+权重渲染、倍数句、LEARNED 基线、标尺指针` |
| TC-RCH-243 | 胶囊缺距离:距离行未参与态、权重 57%/43%、无 0% 残留 | P2 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024 | `Mobile/mobile_app/test/features/pages/estrus_detail_page_test.dart::胶囊缺距离:距离行未参与态、权重 57%/43%、无 0% 残留` |
| TC-RCH-244 | explanation 全 null:构成/基线/倍数句/标尺隐藏,帮助仍在 | P2 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-CMC-001 | `Mobile/mobile_app/test/features/pages/estrus_detail_page_test.dart::explanation 全 null:构成/基线/倍数句/标尺隐藏,帮助仍在` |
| TC-RCH-245 | livestock detail shows rumen motility trend | P2 | REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/pages/livestock_detail_page_test.dart::livestock detail shows rumen motility trend` |
| TC-RCH-246 | unbind device calls uninstall and shows success | P2 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `Mobile/mobile_app/test/features/pages/livestock_detail_page_test.dart::unbind device calls uninstall and shows success` |
| TC-RCH-247 | bind sheet lists only unbound devices and searches server-side | P2 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `Mobile/mobile_app/test/features/pages/livestock_detail_page_test.dart::bind sheet lists only unbound devices and searches server-side` |
| TC-RCH-248 | bind sheet loads more pages when scrolled to the bottom | P2 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/pages/livestock_detail_page_test.dart::bind sheet loads more pages when scrolled to the bottom` |
| TC-RCH-249 | bind sheet auto-fetches when a full page filters to no scroll area | P2 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012 | `Mobile/mobile_app/test/features/pages/livestock_detail_page_test.dart::bind sheet auto-fetches when a full page filters to no scroll area` |
| TC-RCH-250 | real backend: detail page devices + all four trend sections render | P1 | REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001 | `Mobile/mobile_app/test/features/pages/livestock_detail_real_api_test.dart::real backend: detail page devices + all four trend sections render` |
| TC-RCH-251 | premium: all four trend sections render with local-stack shapes | P2 | REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/features/pages/livestock_health_sections_layout_test.dart::premium: all four trend sections render with local-stack shapes` |
| TC-RCH-252 | basic tier: estrus locked overlay still lays out | P2 | REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-HLT-005 | `Mobile/mobile_app/test/features/pages/livestock_health_sections_layout_test.dart::basic tier: estrus locked overlay still lays out` |
| TC-RCH-253 | updateEvent delegates to the repository then refreshes the list | P1 | REQ-HLT-005、REQ-HLT-033 | `Mobile/mobile_app/test/features/physiology/physiology_controller_test.dart::updateEvent delegates to the repository then refreshes the list` |
| TC-RCH-254 | deleteEvent delegates to the repository then refreshes the list | P1 | REQ-HLT-005、REQ-HLT-033 | `Mobile/mobile_app/test/features/physiology/physiology_controller_test.dart::deleteEvent delegates to the repository then refreshes the list` |
| TC-RCH-255 | updateEvent(note: "") puts an explicit empty note on the wire | P1 | REQ-HLT-005、REQ-HLT-033 | `Mobile/mobile_app/test/features/physiology/physiology_controller_test.dart::updateEvent(note: "") puts an explicit empty note on the wire` |
| TC-RCH-256 | edit / delete actions render on MANUAL rows only | P2 | REQ-HLT-005、REQ-HLT-033 | `Mobile/mobile_app/test/features/physiology/physiology_record_card_test.dart::edit / delete actions render on MANUAL rows only` |
| TC-RCH-257 | edit opens the sheet prefilled and saves via updateEvent | P2 | REQ-HLT-005、REQ-HLT-033 | `Mobile/mobile_app/test/features/physiology/physiology_record_card_test.dart::edit opens the sheet prefilled and saves via updateEvent` |
| TC-RCH-258 | clearing the note sends an explicit empty string (N17) | P2 | REQ-HLT-005、REQ-HLT-033 | `Mobile/mobile_app/test/features/physiology/physiology_record_card_test.dart::clearing the note sends an explicit empty string (N17)` |
| TC-RCH-259 | illness footnote is shown for the illness type only (n-h) | P2 | REQ-HLT-005、REQ-HLT-033 | `Mobile/mobile_app/test/features/physiology/physiology_record_card_test.dart::illness footnote is shown for the illness type only (n-h)` |
| TC-RCH-260 | delete asks for confirmation before touching the repository | P2 | REQ-HLT-005、REQ-HLT-033 | `Mobile/mobile_app/test/features/physiology/physiology_record_card_test.dart::delete asks for confirmation before touching the repository` |

## 用例明细（初稿模板）

### TC-RCH-210 full summary with all fields

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：LivestockApiRepository._livestockSummaryFromMap
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::full summary with all fields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-211 int id converted to string

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::int id converted to string`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-212 CRITICAL health maps to abnormal

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::CRITICAL health maps to abnormal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006

### TC-RCH-213 null healthStatus defaults to healthy

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::null healthStatus defaults to healthy`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-RCH-214 lowercase healthStatus still maps correctly

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::lowercase healthStatus still maps correctly`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-002、REQ-RCH-006

### TC-RCH-215 earTag fallback from earTag when livestockCode absent

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::earTag fallback from earTag when livestockCode absent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-216 unknown breed maps to Breed.other

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::unknown breed maps to Breed.other`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-217 null breed maps to Breed.other

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::null breed maps to Breed.other`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-218 int fenceId converted to string

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::int fenceId converted to string`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-219 null coords are null

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::null coords are null`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-220 invalid birthDate string produces null DateTime

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::invalid birthDate string produces null DateTime`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-221 full detail with all fields

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：LivestockApiRepository._livestockDetailFromMap
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::full detail with all fields`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-002、REQ-RCH-006、REQ-RCH-001、REQ-RCH-012

### TC-RCH-222 weight fallback from weight when weightKg absent

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::weight fallback from weight when weightKg absent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-223 missing ageMonths defaults to 24

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::missing ageMonths defaults to 24`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-224 missing bodyTemp defaults to 38.5

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::missing bodyTemp defaults to 38.5`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-225 missing activityLevel defaults to 正常

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::missing activityLevel defaults to 正常`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-226 missing ruminationFreq defaults to --

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::missing ruminationFreq defaults to --`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-227 missing location shows dashes

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::missing location shows dashes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-228 markedSource parses disease, stamp and contact count

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::markedSource parses disease, stamp and contact count`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-229 absent or malformed markedSource falls back to unmarked

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_api_repository_test.dart::absent or malformed markedSource falls back to unmarked`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-230 build loads first page

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::build loads first page`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-231 search sets keyword and resets to page 1

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::search sets keyword and resets to page 1`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-232 goToPage fetches requested page

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::goToPage fetches requested page`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-233 goToPage ignores out-of-range pages

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::goToPage ignores out-of-range pages`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-234 refresh reloads current page

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::refresh reloads current page`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-235 farm switch triggers rebuild

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::farm switch triggers rebuild`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-RCH-236 LivestockDetailController loads by id

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::LivestockDetailController loads by id`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-237 LivestockDetailController refresh reloads detail

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_controller_test.dart::LivestockDetailController refresh reloads detail`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-238 renders priority badges, +N, and rumen metrics

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_signal_summary_test.dart::renders priority badges, +N, and rumen metrics`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-001、REQ-HLT-002、REQ-PLT-001、REQ-PLT-002

### TC-RCH-239 renders return home as a separate presence badge

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/livestock/livestock_signal_summary_test.dart::renders return home as a separate presence badge`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-RCH-240 renders livestock code, risk band colour, window and assessed time

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/calving_page_test.dart::renders livestock code, risk band colour, window and assessed time`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025、REQ-PLT-001、REQ-PLT-002

### TC-RCH-241 empty list renders the calm empty state

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/calving_page_test.dart::empty list renders the calm empty state`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-004、REQ-HLT-025

### TC-RCH-242 NORMALIZED-V2 全通道:分量+权重渲染、倍数句、LEARNED 基线、标尺指针

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/estrus_detail_page_test.dart::NORMALIZED-V2 全通道:分量+权重渲染、倍数句、LEARNED 基线、标尺指针`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024

### TC-RCH-243 胶囊缺距离:距离行未参与态、权重 57%/43%、无 0% 残留

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/estrus_detail_page_test.dart::胶囊缺距离:距离行未参与态、权重 57%/43%、无 0% 残留`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024

### TC-RCH-244 explanation 全 null:构成/基线/倍数句/标尺隐藏,帮助仍在

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/estrus_detail_page_test.dart::explanation 全 null:构成/基线/倍数句/标尺隐藏,帮助仍在`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-CMC-001

### TC-RCH-245 livestock detail shows rumen motility trend

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/livestock_detail_page_test.dart::livestock detail shows rumen motility trend`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-001、REQ-HLT-002、REQ-RCH-001、REQ-RCH-002

### TC-RCH-246 unbind device calls uninstall and shows success

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/livestock_detail_page_test.dart::unbind device calls uninstall and shows success`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-RCH-247 bind sheet lists only unbound devices and searches server-side

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/livestock_detail_page_test.dart::bind sheet lists only unbound devices and searches server-side`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-RCH-248 bind sheet loads more pages when scrolled to the bottom

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/livestock_detail_page_test.dart::bind sheet loads more pages when scrolled to the bottom`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-249 bind sheet auto-fetches when a full page filters to no scroll area

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/livestock_detail_page_test.dart::bind sheet auto-fetches when a full page filters to no scroll area`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012

### TC-RCH-250 real backend: detail page devices + all four trend sections render

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/livestock_detail_real_api_test.dart::real backend: detail page devices + all four trend sections render`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002、REQ-RCH-012、REQ-IOT-001

### TC-RCH-251 premium: all four trend sections render with local-stack shapes

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/livestock_health_sections_layout_test.dart::premium: all four trend sections render with local-stack shapes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033、REQ-RCH-001、REQ-RCH-002

### TC-RCH-252 basic tier: estrus locked overlay still lays out

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/pages/livestock_health_sections_layout_test.dart::basic tier: estrus locked overlay still lays out`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-022、REQ-HLT-023、REQ-HLT-024、REQ-HLT-005

### TC-RCH-253 updateEvent delegates to the repository then refreshes the list

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：PhysiologyEventListController row-level edit/delete (M7)
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/physiology/physiology_controller_test.dart::updateEvent delegates to the repository then refreshes the list`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033

### TC-RCH-254 deleteEvent delegates to the repository then refreshes the list

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/physiology/physiology_controller_test.dart::deleteEvent delegates to the repository then refreshes the list`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033

### TC-RCH-255 updateEvent(note: "") puts an explicit empty note on the wire

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：PhysiologyApiRepository note clearing (N17)
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/physiology/physiology_controller_test.dart::updateEvent(note: "") puts an explicit empty note on the wire`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033

### TC-RCH-256 edit / delete actions render on MANUAL rows only

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/physiology/physiology_record_card_test.dart::edit / delete actions render on MANUAL rows only`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033

### TC-RCH-257 edit opens the sheet prefilled and saves via updateEvent

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/physiology/physiology_record_card_test.dart::edit opens the sheet prefilled and saves via updateEvent`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033

### TC-RCH-258 clearing the note sends an explicit empty string (N17)

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/physiology/physiology_record_card_test.dart::clearing the note sends an explicit empty string (N17)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033

### TC-RCH-259 illness footnote is shown for the illness type only (n-h)

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/physiology/physiology_record_card_test.dart::illness footnote is shown for the illness type only (n-h)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033

### TC-RCH-260 delete asks for confirmation before touching the repository

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/physiology/physiology_record_card_test.dart::delete asks for confirmation before touching the repository`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-005、REQ-HLT-033

