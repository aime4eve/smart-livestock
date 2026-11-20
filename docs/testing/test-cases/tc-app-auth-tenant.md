# 测试用例规格：App·登录认证与租户切换

> 用例域：IDT ｜ 用例数：41
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-IDT-001 | owner 无牧场时显示联系管理员引导 | P2 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/app/main_shell_empty_farm_test.dart::owner 无牧场时显示联系管理员引导` |
| TC-IDT-002 | worker 无 admin Tab | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::worker 无 admin Tab` |
| TC-IDT-003 | worker 导航栏只有 2 个 Tab（牧场 + 我的） | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::worker 导航栏只有 2 个 Tab（牧场 + 我的）` |
| TC-IDT-004 | platform_admin 无 App 底部导航 | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::platform_admin 无 App 底部导航` |
| TC-IDT-005 | b2b_admin 无 App 底部导航 | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::b2b_admin 无 App 底部导航` |
| TC-IDT-006 | b2b_admin 可打开设备配置管理页（2026-10-22 修复回归） | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::b2b_admin 可打开设备配置管理页（2026-10-22 修复回归）` |
| TC-IDT-007 | owner 有牧场 Tab | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::owner 有牧场 Tab` |
| TC-IDT-008 | owner 导航栏包含 2 个 Tab（牧场 + 我的） | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::owner 导航栏包含 2 个 Tab（牧场 + 我的）` |
| TC-IDT-009 | 根会话被锁进选择器页（无牧场底部导航） | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::根会话被锁进选择器页（无牧场底部导航）` |
| TC-IDT-010 | OWNER 上下文会话按上下文角色进牧场页 | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::OWNER 上下文会话按上下文角色进牧场页` |
| TC-IDT-011 | PLATFORM_ADMIN 上下文会话进平台管理台 | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::PLATFORM_ADMIN 上下文会话进平台管理台` |
| TC-IDT-012 | 根会话改密锁优先于选择器 | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::根会话改密锁优先于选择器` |
| TC-IDT-013 | OWNER 上下文会话在选择器页被送回牧场页（2026-10-20 修复回归） | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/app/route_guard_test.dart::OWNER 上下文会话在选择器页被送回牧场页（2026-10-20 修复回归）` |
| TC-IDT-014 | logout 应 invalidate farmSwitcher，使残留牧场状态被重置 | P1 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/app/session_logout_farm_state_test.dart::logout 应 invalidate farmSwitcher，使残留牧场状态被重置` |
| TC-IDT-015 | FenceController 在 activeFarmId 恢复后应自愈，不永久卡 loading | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/app/session_logout_farm_state_test.dart::FenceController 在 activeFarmId 恢复后应自愈，不永久卡 loading` |
| TC-IDT-016 | farm* 的 farmId 参数不污染全局 activeFarmId（b2b 跨农场防回归） | P1 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/app/session_logout_farm_state_test.dart::farm* 的 farmId 参数不污染全局 activeFarmId（b2b 跨农场防回归）` |
| TC-IDT-017 | 普通会话不渲染横幅（挂载透明） | P2 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/auth/acting_as_banner_test.dart::普通会话不渲染横幅（挂载透明）` |
| TC-IDT-018 | OWNER 上下文渲染双行横幅（含审计副行与租户名） | P2 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/auth/acting_as_banner_test.dart::OWNER 上下文渲染双行横幅（含审计副行与租户名）` |
| TC-IDT-019 | 平台上下文横幅不显示租户名 | P2 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/auth/acting_as_banner_test.dart::平台上下文横幅不显示租户名` |
| TC-IDT-020 | 根 token 过期时切换按钮提示重登（不弹 sheet） | P2 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/auth/acting_as_banner_test.dart::根 token 过期时切换按钮提示重登（不弹 sheet）` |
| TC-IDT-021 | 四张角色卡与登录者卡渲染 | P2 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::四张角色卡与登录者卡渲染` |
| TC-IDT-022 | 平台级角色直接弹确认 sheet | P2 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::平台级角色直接弹确认 sheet` |
| TC-IDT-023 | 租户型角色进入租户列表，三种租户状态齐全 | P2 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::租户型角色进入租户列表，三种租户状态齐全` |
| TC-IDT-024 | 到期租户不可点击，无确认 sheet | P2 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::到期租户不可点击，无确认 sheet` |
| TC-IDT-025 | 停用租户确认 sheet 带警示与「仍要进入」 | P2 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::停用租户确认 sheet 带警示与「仍要进入」` |
| TC-IDT-026 | 正常租户确认 sheet 主按钮为「进入」 | P2 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::正常租户确认 sheet 主按钮为「进入」` |
| TC-IDT-027 | 租户名搜索过滤列表 | P2 | REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::租户名搜索过滤列表` |
| TC-IDT-028 | weak new password surfaces the strength rule | P2 | REQ-IDT-002、REQ-IDT-006 | `Mobile/mobile_app/test/features/auth/forced_password_change_page_test.dart::weak new password surfaces the strength rule` |
| TC-IDT-029 | mismatched confirmation surfaces the mismatch error | P2 | REQ-IDT-002、REQ-IDT-006 | `Mobile/mobile_app/test/features/auth/forced_password_change_page_test.dart::mismatched confirmation surfaces the mismatch error` |
| TC-IDT-030 | returns the farm matching activeFarmId with its coordinates | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006 | `Mobile/mobile_app/test/features/farm_switcher/farm_switcher_state_test.dart::returns the farm matching activeFarmId with its coordinates` |
| TC-IDT-031 | falls back to first farm when activeFarmId matches nothing | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/farm_switcher/farm_switcher_state_test.dart::falls back to first farm when activeFarmId matches nothing` |
| TC-IDT-032 | returns null when no farms loaded | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/farm_switcher/farm_switcher_state_test.dart::returns null when no farms loaded` |
| TC-IDT-033 | PaginationBar 显示当前页/总页数 | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/tenant/pagination_bar_test.dart::PaginationBar 显示当前页/总页数` |
| TC-IDT-034 | 点击下一页触发 onPageChanged(page+1) | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/tenant/pagination_bar_test.dart::点击下一页触发 onPageChanged(page+1)` |
| TC-IDT-035 | 首页时上一页按钮禁用 | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/tenant/pagination_bar_test.dart::首页时上一页按钮禁用` |
| TC-IDT-036 | 加载并显示租户信息和用户列表 | P2 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::加载并显示租户信息和用户列表` |
| TC-IDT-037 | 加载失败显示错误态和重试按钮 | P2 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::加载失败显示错误态和重试按钮` |
| TC-IDT-038 | 点击新增用户打开 dialog | P2 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::点击新增用户打开 dialog` |
| TC-IDT-039 | 创建用户表单校验必填与标识符至少一项 | P2 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::创建用户表单校验必填与标识符至少一项` |
| TC-IDT-040 | 用户启停按钮显示正确状态 | P2 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::用户启停按钮显示正确状态` |
| TC-IDT-041 | 无用户时显示空状态 | P2 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::无用户时显示空状态` |

## 用例明细（初稿模板）

### TC-IDT-001 owner 无牧场时显示联系管理员引导

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/main_shell_empty_farm_test.dart::owner 无牧场时显示联系管理员引导`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-IDT-002 worker 无 admin Tab

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：路由守卫 — worker
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::worker 无 admin Tab`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-003 worker 导航栏只有 2 个 Tab（牧场 + 我的）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::worker 导航栏只有 2 个 Tab（牧场 + 我的）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-004 platform_admin 无 App 底部导航

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：路由守卫 — platform_admin
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::platform_admin 无 App 底部导航`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-005 b2b_admin 无 App 底部导航

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：路由守卫 — b2b_admin
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::b2b_admin 无 App 底部导航`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-006 b2b_admin 可打开设备配置管理页（2026-10-22 修复回归）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::b2b_admin 可打开设备配置管理页（2026-10-22 修复回归）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-007 owner 有牧场 Tab

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：路由守卫 — owner
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::owner 有牧场 Tab`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-008 owner 导航栏包含 2 个 Tab（牧场 + 我的）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::owner 导航栏包含 2 个 Tab（牧场 + 我的）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-009 根会话被锁进选择器页（无牧场底部导航）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：路由守卫 — super_admin（选角色进入，2026-10-19）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::根会话被锁进选择器页（无牧场底部导航）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-010 OWNER 上下文会话按上下文角色进牧场页

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::OWNER 上下文会话按上下文角色进牧场页`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-011 PLATFORM_ADMIN 上下文会话进平台管理台

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::PLATFORM_ADMIN 上下文会话进平台管理台`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-012 根会话改密锁优先于选择器

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::根会话改密锁优先于选择器`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-013 OWNER 上下文会话在选择器页被送回牧场页（2026-10-20 修复回归）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/route_guard_test.dart::OWNER 上下文会话在选择器页被送回牧场页（2026-10-20 修复回归）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-IDT-014 logout 应 invalidate farmSwitcher，使残留牧场状态被重置

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/session_logout_farm_state_test.dart::logout 应 invalidate farmSwitcher，使残留牧场状态被重置`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-015 FenceController 在 activeFarmId 恢复后应自愈，不永久卡 loading

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/session_logout_farm_state_test.dart::FenceController 在 activeFarmId 恢复后应自愈，不永久卡 loading`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-IDT-016 farm* 的 farmId 参数不污染全局 activeFarmId（b2b 跨农场防回归）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app/session_logout_farm_state_test.dart::farm* 的 farmId 参数不污染全局 activeFarmId（b2b 跨农场防回归）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-017 普通会话不渲染横幅（挂载透明）

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/acting_as_banner_test.dart::普通会话不渲染横幅（挂载透明）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-018 OWNER 上下文渲染双行横幅（含审计副行与租户名）

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/acting_as_banner_test.dart::OWNER 上下文渲染双行横幅（含审计副行与租户名）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-019 平台上下文横幅不显示租户名

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/acting_as_banner_test.dart::平台上下文横幅不显示租户名`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-020 根 token 过期时切换按钮提示重登（不弹 sheet）

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/acting_as_banner_test.dart::根 token 过期时切换按钮提示重登（不弹 sheet）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-021 四张角色卡与登录者卡渲染

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::四张角色卡与登录者卡渲染`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-022 平台级角色直接弹确认 sheet

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::平台级角色直接弹确认 sheet`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-023 租户型角色进入租户列表，三种租户状态齐全

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::租户型角色进入租户列表，三种租户状态齐全`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-024 到期租户不可点击，无确认 sheet

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::到期租户不可点击，无确认 sheet`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-025 停用租户确认 sheet 带警示与「仍要进入」

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::停用租户确认 sheet 带警示与「仍要进入」`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-026 正常租户确认 sheet 主按钮为「进入」

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::正常租户确认 sheet 主按钮为「进入」`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-027 租户名搜索过滤列表

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/context_picker_page_test.dart::租户名搜索过滤列表`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006、REQ-IDT-001、REQ-IDT-003

### TC-IDT-028 weak new password surfaces the strength rule

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/forced_password_change_page_test.dart::weak new password surfaces the strength rule`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006

### TC-IDT-029 mismatched confirmation surfaces the mismatch error

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/auth/forced_password_change_page_test.dart::mismatched confirmation surfaces the mismatch error`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-006

### TC-IDT-030 returns the farm matching activeFarmId with its coordinates

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：FarmSwitcherState.activeFarm
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/farm_switcher/farm_switcher_state_test.dart::returns the farm matching activeFarmId with its coordinates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-002、REQ-RCH-006

### TC-IDT-031 falls back to first farm when activeFarmId matches nothing

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/farm_switcher/farm_switcher_state_test.dart::falls back to first farm when activeFarmId matches nothing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-IDT-032 returns null when no farms loaded

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/farm_switcher/farm_switcher_state_test.dart::returns null when no farms loaded`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-IDT-033 PaginationBar 显示当前页/总页数

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/tenant/pagination_bar_test.dart::PaginationBar 显示当前页/总页数`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-IDT-034 点击下一页触发 onPageChanged(page+1)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/tenant/pagination_bar_test.dart::点击下一页触发 onPageChanged(page+1)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-IDT-035 首页时上一页按钮禁用

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/tenant/pagination_bar_test.dart::首页时上一页按钮禁用`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-IDT-036 加载并显示租户信息和用户列表

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 所属分组：TenantDetailPage
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::加载并显示租户信息和用户列表`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-IDT-037 加载失败显示错误态和重试按钮

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::加载失败显示错误态和重试按钮`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-IDT-038 点击新增用户打开 dialog

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::点击新增用户打开 dialog`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-IDT-039 创建用户表单校验必填与标识符至少一项

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::创建用户表单校验必填与标识符至少一项`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-IDT-040 用户启停按钮显示正确状态

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::用户启停按钮显示正确状态`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-IDT-041 无用户时显示空状态

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/tenant/tenant_detail_page_test.dart::无用户时显示空状态`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

