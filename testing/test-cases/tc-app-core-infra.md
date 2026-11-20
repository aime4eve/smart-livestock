# 测试用例规格：App·基础设施与通用组件

> 用例域：PLT ｜ 用例数：139
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-PLT-001 | DemoApp 使用 MaterialApp.router 承载声明式路由 | P1 | — | `Mobile/mobile_app/test/app_architecture_test.dart::DemoApp 使用 MaterialApp.router 承载声明式路由` |
| TC-PLT-002 | DemoApp 需要 ProviderScope 祖先节点 | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/app_architecture_test.dart::DemoApp 需要 ProviderScope 祖先节点` |
| TC-PLT-003 | 后端响应使用 vertices 而非 coordinates | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端响应使用 vertices 而非 coordinates` |
| TC-PLT-004 | fenceItemFromJson 正确解析 vertices → LatLng | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004 | `Mobile/mobile_app/test/contract/api_contract_test.dart::fenceItemFromJson 正确解析 vertices → LatLng` |
| TC-PLT-005 | fenceItemFromJson 解析所有字段 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004 | `Mobile/mobile_app/test/contract/api_contract_test.dart::fenceItemFromJson 解析所有字段` |
| TC-PLT-006 | fenceItemsFromApiMaps 批量解析 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004 | `Mobile/mobile_app/test/contract/api_contract_test.dart::fenceItemsFromApiMaps 批量解析` |
| TC-PLT-007 | vertices 格式: [{lat, lng}, ...] 而非 [[lng, lat], ...] | P1 | REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::vertices 格式: [{lat, lng}, ...] 而非 [[lng, lat], ...]` |
| TC-PLT-008 | fence detail 解析 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004 | `Mobile/mobile_app/test/contract/api_contract_test.dart::fence detail 解析` |
| TC-PLT-009 | 后端响应包含 id, livestockCode, breed, healthStatus | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端响应包含 id, livestockCode, breed, healthStatus` |
| TC-PLT-010 | 后端使用 livestockCode 而非 earTag | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端使用 livestockCode 而非 earTag` |
| TC-PLT-011 | 后端坐标字段为 lastLatitude / lastLongitude | P1 | REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端坐标字段为 lastLatitude / lastLongitude` |
| TC-PLT-012 | healthStatus 值为大写枚举 | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::healthStatus 值为大写枚举` |
| TC-PLT-013 | 后端响应包含 type, status, severity, message | P1 | REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端响应包含 type, status, severity, message` |
| TC-PLT-014 | status 值为 PENDING/ACKNOWLEDGED/HANDLED/ARCHIVED | P1 | REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::status 值为 PENDING/ACKNOWLEDGED/HANDLED/ARCHIVED` |
| TC-PLT-015 | severity 值为 CRITICAL/WARNING/INFO | P1 | REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::severity 值为 CRITICAL/WARNING/INFO` |
| TC-PLT-016 | id 和 livestockId 为 int 类型（非 String） | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/contract/api_contract_test.dart::id 和 livestockId 为 int 类型（非 String）` |
| TC-PLT-017 | 后端使用扁平字段（非 metrics 数组） | P1 | REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端使用扁平字段（非 metrics 数组）` |
| TC-PLT-018 | healthSummary 包含 healthy/warning/critical | P1 | REQ-HLT-003、REQ-HLT-005、REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::healthSummary 包含 healthy/warning/critical` |
| TC-PLT-019 | 后端响应包含 id, name, phone, role, tenantId | P1 | REQ-CMC-004、REQ-CMC-005、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端响应包含 id, name, phone, role, tenantId` |
| TC-PLT-020 | role 值为大写枚举 | P1 | REQ-CMC-004、REQ-CMC-005、REQ-IDT-004 | `Mobile/mobile_app/test/contract/api_contract_test.dart::role 值为大写枚举` |
| TC-PLT-021 | id 和 tenantId 为 int 类型 | P1 | REQ-CMC-004、REQ-CMC-005、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/contract/api_contract_test.dart::id 和 tenantId 为 int 类型` |
| TC-PLT-022 | 后端响应包含分页 envelope | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端响应包含分页 envelope` |
| TC-PLT-023 | farm 对象包含 id, name, latitude, longitude | P1 | REQ-CMC-004、REQ-CMC-005、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/contract/api_contract_test.dart::farm 对象包含 id, name, latitude, longitude` |
| TC-PLT-024 | SubscriptionStatus.fromJson 解析真实后端响应 | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::SubscriptionStatus.fromJson 解析真实后端响应` |
| TC-PLT-025 | 后端 subscription 响应的实际字段 | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端 subscription 响应的实际字段` |
| TC-PLT-026 | 后端 subscription/plans 返回 data 为 List（非分页） | P1 | REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端 subscription/plans 返回 data 为 List（非分页）` |
| TC-PLT-027 | 后端设备响应包含基础字段 | P1 | REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端设备响应包含基础字段` |
| TC-PLT-028 | 后端使用分页 envelope | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004 | `Mobile/mobile_app/test/contract/api_contract_test.dart::后端使用分页 envelope` |
| TC-PLT-029 | ranch-overview envelope \u7ed3\u6784 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004 | `Mobile/mobile_app/test/contract/api_contract_test.dart::ranch-overview envelope \u7ed3\u6784` |
| TC-PLT-030 | overallStats \u7c7b\u578b\u6b63\u786e | P1 | REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::overallStats \u7c7b\u578b\u6b63\u786e` |
| TC-PLT-031 | fences \u683c\u5f0f | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004 | `Mobile/mobile_app/test/contract/api_contract_test.dart::fences \u683c\u5f0f` |
| TC-PLT-032 | livestockMarkers \u683c\u5f0f | P1 | REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/contract/api_contract_test.dart::livestockMarkers \u683c\u5f0f` |
| TC-PLT-033 | alerts \u683c\u5f0f | P1 | REQ-RCH-006、REQ-RCH-007、REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::alerts \u683c\u5f0f` |
| TC-PLT-034 | 所有 fixture 包含 {code, message, data} | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004 | `Mobile/mobile_app/test/contract/api_contract_test.dart::所有 fixture 包含 {code, message, data}` |
| TC-PLT-035 | 列表 fixture 使用 {items, total, page, pageSize} 分页 | P1 | REQ-CMC-004、REQ-CMC-005 | `Mobile/mobile_app/test/contract/api_contract_test.dart::列表 fixture 使用 {items, total, page, pageSize} 分页` |
| TC-PLT-036 | farmGet(farmId) 全局为 null 时使用 farmId，不抛 StateError | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/core/api/api_client_farm_id_param_test.dart::farmGet(farmId) 全局为 null 时使用 farmId，不抛 StateError` |
| TC-PLT-037 | farmGet 无 farmId 且全局 null 时抛 StateError("No active farm") | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/core/api/api_client_farm_id_param_test.dart::farmGet 无 farmId 且全局 null 时抛 StateError("No active farm")` |
| TC-PLT-038 | farmGet(farmId) 不修改全局 _activeFarmId | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/core/api/api_client_farm_id_param_test.dart::farmGet(farmId) 不修改全局 _activeFarmId` |
| TC-PLT-039 | farmPost body + farmId 共存，不污染全局 | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/core/api/api_client_farm_id_param_test.dart::farmPost body + farmId 共存，不污染全局` |
| TC-PLT-040 | AuthException is rethrown when code is not AUTH_INVALID_TOKEN | P1 | REQ-IDT-002 | `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::AuthException is rethrown when code is not AUTH_INVALID_TOKEN` |
| TC-PLT-041 | AuthException carries statusCode and code | P1 | REQ-IDT-002 | `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::AuthException carries statusCode and code` |
| TC-PLT-042 | Refresh fields are initially idle | P1 | — | `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::Refresh fields are initially idle` |
| TC-PLT-043 | farmGet throws StateError when no active farm | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::farmGet throws StateError when no active farm` |
| TC-PLT-044 | farmPost throws StateError when no active farm | P1 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::farmPost throws StateError when no active farm` |
| TC-PLT-045 | expiresInSeconds returns negative for expired payload | P1 | REQ-IDT-002 | `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::expiresInSeconds returns negative for expired payload` |
| TC-PLT-046 | expiresInSeconds returns positive for future payload | P1 | — | `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::expiresInSeconds returns positive for future payload` |
| TC-PLT-047 | root token/user 存取与 clearRoot 只清 root | P1 | REQ-IDT-002 | `Mobile/mobile_app/test/core/api/jwt_storage_root_test.dart::root token/user 存取与 clearRoot 只清 root` |
| TC-PLT-048 | logout clear() 清全部五类 key（含 root 与最近切换） | P1 | REQ-IDT-002 | `Mobile/mobile_app/test/core/api/jwt_storage_root_test.dart::logout clear() 清全部五类 key（含 root 与最近切换）` |
| TC-PLT-049 | recent contexts 损坏数据安全回退为空 | P1 | REQ-IDT-002、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/core/api/jwt_storage_root_test.dart::recent contexts 损坏数据安全回退为空` |
| TC-PLT-050 | v1 存量库升级：shape 列补齐 + 版本推进 v2 + 存量行缺省 polygon | P1 | REQ-NFR-001、REQ-NFR-002 | `Mobile/mobile_app/test/core/database/app_database_shape_migration_test.dart::v1 存量库升级：shape 列补齐 + 版本推进 v2 + 存量行缺省 polygon` |
| TC-PLT-051 | 全新库直接建 v2：shape 列在位且 ALTER 守卫不重复执行 | P1 | REQ-NFR-001、REQ-NFR-002 | `Mobile/mobile_app/test/core/database/app_database_shape_migration_test.dart::全新库直接建 v2：shape 列在位且 ALTER 守卫不重复执行` |
| TC-PLT-052 | round-trip wgs84→gcj02→wgs84 偏差 < 0.5m | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/coord_transform_test.dart::round-trip wgs84→gcj02→wgs84 偏差 < 0.5m` |
| TC-PLT-053 | 海外坐标不变 | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/coord_transform_test.dart::海外坐标不变` |
| TC-PLT-054 | 迭代收敛精度 < 0.1m | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/coord_transform_test.dart::迭代收敛精度 < 0.1m` |
| TC-PLT-055 | 批量逆转换 | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/coord_transform_test.dart::批量逆转换` |
| TC-PLT-056 | no fences → farm registered coordinates | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001 | `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::no fences → farm registered coordinates` |
| TC-PLT-057 | fences win over farm coordinates (vertex average of first fence) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001 | `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::fences win over farm coordinates (vertex average of first fence)` |
| TC-PLT-058 | empty fence ring is skipped, next fence used | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001 | `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::empty fence ring is skipped, next fence used` |
| TC-PLT-059 | no fences and no farm coordinates → null (keep default) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001 | `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::no fences and no farm coordinates → null (keep default)` |
| TC-PLT-060 | shouldTransform converts farm coordinates to GCJ-02 | P1 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::shouldTransform converts farm coordinates to GCJ-02` |
| TC-PLT-061 | Changsha demo farm with fences keeps centering inside its area | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001 | `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::Changsha demo farm with fences keeps centering inside its area` |
| TC-PLT-062 | China time zone → single 高德 source with GCJ-02 transform | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_factory_test.dart::China time zone → single 高德 source with GCJ-02 transform` |
| TC-PLT-063 | non-China time zone → single OSM source, no transform | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_factory_test.dart::non-China time zone → single OSM source, no transform` |
| TC-PLT-064 | tile-source resolve failure never blocks provider creation | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_factory_test.dart::tile-source resolve failure never blocks provider creation` |
| TC-PLT-065 | offline probe falls back to server tiles when online unreachable | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_factory_test.dart::offline probe falls back to server tiles when online unreachable` |
| TC-PLT-066 | OSM online → shouldTransformCoordinates false | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::OSM online → shouldTransformCoordinates false` |
| TC-PLT-067 | 高德 online → shouldTransformCoordinates true | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::高德 online → shouldTransformCoordinates true` |
| TC-PLT-068 | 高德 online but offline (server tiles) → transform false | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::高德 online but offline (server tiles) → transform false` |
| TC-PLT-069 | activeSourceName reflects the configured online source | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::activeSourceName reflects the configured online source` |
| TC-PLT-070 | getImage online → NetworkImage from configured source | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::getImage online → NetworkImage from configured source` |
| TC-PLT-071 | getImage offline + serverTileUrl → tileserver NetworkImage | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::getImage offline + serverTileUrl → tileserver NetworkImage` |
| TC-PLT-072 | 高德在线 + 无本地瓦片：需要变换（原全局 flag 语义，真高德区域） | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::高德在线 + 无本地瓦片：需要变换（原全局 flag 语义，真高德区域）` |
| TC-PLT-073 | 高德在线 + 本地 mbtiles 覆盖该点：不变换（离线瓦片是 WGS-84） | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::高德在线 + 本地 mbtiles 覆盖该点：不变换（离线瓦片是 WGS-84）` |
| TC-PLT-074 | 高德在线 + 本地 mbtiles 只覆盖远处：仍需变换 | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::高德在线 + 本地 mbtiles 只覆盖远处：仍需变换` |
| TC-PLT-075 | 高德在线 + mbtiles 覆盖但该 zoom 超出文件范围：需变换（在线接管） | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::高德在线 + mbtiles 覆盖但该 zoom 超出文件范围：需变换（在线接管）` |
| TC-PLT-076 | 离线回落（server tileserver = WGS-84）：永不变换 | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::离线回落（server tileserver = WGS-84）：永不变换` |
| TC-PLT-077 | 非中国时区（OSM = WGS-84）：永不变换 | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::非中国时区（OSM = WGS-84）：永不变换` |
| TC-PLT-078 | 无锚点回落：全局 flag 语义保留（ranch_page 混合范式） | P1 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::无锚点回落：全局 flag 语义保留（ranch_page 混合范式）` |
| TC-PLT-079 | $role 编辑围栏 ${RolePermission.canEditFence(role)} | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 编辑围栏 ${RolePermission.canEditFence(role)}` |
| TC-PLT-080 | $role 添加围栏 ${RolePermission.canAddFence(role)} | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 添加围栏 ${RolePermission.canAddFence(role)}` |
| TC-PLT-081 | $role 删除围栏 ${RolePermission.canDeleteFence(role)} | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 删除围栏 ${RolePermission.canDeleteFence(role)}` |
| TC-PLT-082 | $role 确认告警 $canAck | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 确认告警 $canAck` |
| TC-PLT-083 | $role 处理告警 ${canHandleRoles.contains(role)} | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 处理告警 ${canHandleRoles.contains(role)}` |
| TC-PLT-084 | $role 归档告警 ${role == UserRole.owner} | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 归档告警 ${role == UserRole.owner}` |
| TC-PLT-085 | $role 批量告警 ${canHandleRoles.contains(role)} | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 批量告警 ${canHandleRoles.contains(role)}` |
| TC-PLT-086 | $role 管理租户 $canManage | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 管理租户 $canManage` |
| TC-PLT-087 | $role 创建租户 $canManage | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 创建租户 $canManage` |
| TC-PLT-088 | $role 编辑租户 $canManage | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 编辑租户 $canManage` |
| TC-PLT-089 | $role 删除租户 $canManage | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 删除租户 $canManage` |
| TC-PLT-090 | $role 切换租户状态 $canManage | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 切换租户状态 $canManage` |
| TC-PLT-091 | $role 调整License $canManage | P1 | REQ-CMC-008、REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 调整License $canManage` |
| TC-PLT-092 | $role 管理订阅 ${role == UserRole.owner} | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 管理订阅 ${role == UserRole.owner}` |
| TC-PLT-093 | $role 创建牧场 $canCreate | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 创建牧场 $canCreate` |
| TC-PLT-094 | $role 查看B端看板 ${role == UserRole.b2bAdmin} | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 查看B端看板 ${role == UserRole.b2bAdmin}` |
| TC-PLT-095 | $role 查看合同 ${role == UserRole.b2bAdmin} | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 查看合同 ${role == UserRole.b2bAdmin}` |
| TC-PLT-096 | $role 管理旗下牧工 ${role == UserRole.b2bAdmin} | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 管理旗下牧工 ${role == UserRole.b2bAdmin}` |
| TC-PLT-097 | $role 管理合同 ${role == UserRole.platformAdmin} | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 管理合同 ${role == UserRole.platformAdmin}` |
| TC-PLT-098 | $role 查看对账 $canViewRevenue | P1 | REQ-CMC-004、REQ-CMC-005、REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 查看对账 $canViewRevenue` |
| TC-PLT-099 | $role 计算分润 ${role == UserRole.platformAdmin} | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 计算分润 ${role == UserRole.platformAdmin}` |
| TC-PLT-100 | $role 管理订阅服务 ${role == UserRole.platformAdmin} | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 管理订阅服务 ${role == UserRole.platformAdmin}` |
| TC-PLT-101 | $role 审批API授权 $canReview | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 审批API授权 $canReview` |
| TC-PLT-102 | $role 繁育操作 ${role == UserRole.owner} | P1 | REQ-IDT-004 | `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 繁育操作 ${role == UserRole.owner}` |
| TC-PLT-103 | parses livestock signal with nested rumen metrics | P1 | REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002 | `Mobile/mobile_app/test/core/sync/signal_models_test.dart::parses livestock signal with nested rumen metrics` |
| TC-PLT-104 | missing presence signal defaults to normal | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `Mobile/mobile_app/test/core/sync/signal_models_test.dart::missing presence signal defaults to normal` |
| TC-PLT-105 | missing metrics remain missing instead of becoming zero | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `Mobile/mobile_app/test/core/sync/signal_models_test.dart::missing metrics remain missing instead of becoming zero` |
| TC-PLT-106 | parses position updates | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `Mobile/mobile_app/test/core/sync/signal_models_test.dart::parses position updates` |
| TC-PLT-107 | unsubscribe removes only the matching transport mode | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `Mobile/mobile_app/test/core/sync/signal_sync_controller_test.dart::unsubscribe removes only the matching transport mode` |
| TC-PLT-108 | cursor-too-old resets cursor and performs full resync | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `Mobile/mobile_app/test/core/sync/signal_sync_controller_test.dart::cursor-too-old resets cursor and performs full resync` |
| TC-PLT-109 | livestock refresh publishes status cursor to listeners | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001 | `Mobile/mobile_app/test/core/sync/signal_sync_controller_test.dart::livestock refresh publishes status cursor to listeners` |
| TC-PLT-110 | connected SSE stops polling and events refresh once | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `Mobile/mobile_app/test/core/sync/signal_sync_controller_test.dart::connected SSE stops polling and events refresh once` |
| TC-PLT-111 | SSE failure falls back to three-second polling | P1 | REQ-PLT-001、REQ-PLT-002、REQ-PLT-005 | `Mobile/mobile_app/test/core/sync/signal_sync_controller_test.dart::SSE failure falls back to three-second polling` |
| TC-PLT-112 | Asia/Shanghai and other UTC+8 China ids → true | P1 | — | `Mobile/mobile_app/test/core/timezone/time_zone_controller_test.dart::Asia/Shanghai and other UTC+8 China ids → true` |
| TC-PLT-113 | non-China ids → false | P1 | — | `Mobile/mobile_app/test/core/timezone/time_zone_controller_test.dart::non-China ids → false` |
| TC-PLT-114 | null id (follow system) uses UTC+8 offset heuristic | P1 | — | `Mobile/mobile_app/test/core/timezone/time_zone_controller_test.dart::null id (follow system) uses UTC+8 offset heuristic` |
| TC-PLT-115 | setTimeZone persists and updates state | P1 | — | `Mobile/mobile_app/test/core/timezone/time_zone_controller_test.dart::setTimeZone persists and updates state` |
| TC-PLT-116 | restore reads persisted value | P1 | — | `Mobile/mobile_app/test/core/timezone/time_zone_controller_test.dart::restore reads persisted value` |
| TC-PLT-117 | owner 登录返回 JWT 和用户信息 | P0 | REQ-IDT-002 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::owner 登录返回 JWT 和用户信息` |
| TC-PLT-118 | 错误密码登录失败 | P0 | — | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::错误密码登录失败` |
| TC-PLT-119 | 无 token 访问受保护端点返回 401 | P0 | REQ-IDT-002 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::无 token 访问受保护端点返回 401` |
| TC-PLT-120 | GET /me 返回当前用户 | P0 | — | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /me 返回当前用户` |
| TC-PLT-121 | GET /farms/{id}/dashboard/summary 返回指标 | P0 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms/{id}/dashboard/summary 返回指标` |
| TC-PLT-122 | GET /farms/{id}/fences 返回围栏列表 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms/{id}/fences 返回围栏列表` |
| TC-PLT-123 | 围栏 color 字段兼容 String 和 null | P0 | — | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::围栏 color 字段兼容 String 和 null` |
| TC-PLT-124 | GET /farms/{id}/alerts 返回告警列表 | P0 | REQ-RCH-006、REQ-RCH-007、REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms/{id}/alerts 返回告警列表` |
| TC-PLT-125 | 告警 status 为合法枚举值 | P0 | — | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::告警 status 为合法枚举值` |
| TC-PLT-126 | GET /farms/{id}/livestock 返回牲畜列表 | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms/{id}/livestock 返回牲畜列表` |
| TC-PLT-127 | GET /subscription 返回当前订阅 | P0 | REQ-CMC-001、REQ-CMC-002 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /subscription 返回当前订阅` |
| TC-PLT-128 | GET /farms 返回牧场列表（含坐标） | P0 | REQ-IDT-001、REQ-IDT-003 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms 返回牧场列表（含坐标）` |
| TC-PLT-129 | GET /farms/{id}/ranch-overview \u8fd4\u56de\u805a\u5408\u6570\u636e | P0 | REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms/{id}/ranch-overview \u8fd4\u56de\u805a\u5408\u6570\u636e` |
| TC-PLT-130 | fences \u5305\u542b\u56f4\u680f\u5750\u6807 | P0 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::fences \u5305\u542b\u56f4\u680f\u5750\u6807` |
| TC-PLT-131 | livestockMarkers \u6709\u5065\u5eb7\u72b6\u6001 | P0 | REQ-RCH-001、REQ-RCH-002 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::livestockMarkers \u6709\u5065\u5eb7\u72b6\u6001` |
| TC-PLT-132 | alerts \u4e0d\u542b ARCHIVED | P0 | REQ-RCH-006、REQ-RCH-007 | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::alerts \u4e0d\u542b ARCHIVED` |
| TC-PLT-133 | owner 不能访问 admin 端点 | P0 | — | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::owner 不能访问 admin 端点` |
| TC-PLT-134 | worker 登录后不能访问订阅 | P0 | — | `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::worker 登录后不能访问订阅` |
| TC-PLT-164 | DemoApp applies the high-fidelity theme tokens | P1 | REQ-IDT-002 | `Mobile/mobile_app/test/theme/highfi_theme_test.dart::DemoApp applies the high-fidelity theme tokens` |
| TC-PLT-165 | worker 登录后不显示 nav-admin | P2 | — | `Mobile/mobile_app/test/widget_smoke_test.dart::worker 登录后不显示 nav-admin` |
| TC-PLT-166 | 导航栏不含旧地图项 | P2 | — | `Mobile/mobile_app/test/widget_smoke_test.dart::导航栏不含旧地图项` |
| TC-PLT-167 | owner 导航栏包含牧场和我的两个 Tab | P2 | — | `Mobile/mobile_app/test/widget_smoke_test.dart::owner 导航栏包含牧场和我的两个 Tab` |
| TC-PLT-168 | demo app boot smoke test | P2 | — | `Mobile/mobile_app/test/widget_test.dart::demo app boot smoke test` |

## 用例明细（初稿模板）

### TC-PLT-001 DemoApp 使用 MaterialApp.router 承载声明式路由

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app_architecture_test.dart::DemoApp 使用 MaterialApp.router 承载声明式路由`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-002 DemoApp 需要 ProviderScope 祖先节点

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/app_architecture_test.dart::DemoApp 需要 ProviderScope 祖先节点`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-PLT-003 后端响应使用 vertices 而非 coordinates

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端响应使用 vertices 而非 coordinates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-PLT-004 fenceItemFromJson 正确解析 vertices → LatLng

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::fenceItemFromJson 正确解析 vertices → LatLng`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004

### TC-PLT-005 fenceItemFromJson 解析所有字段

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::fenceItemFromJson 解析所有字段`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004

### TC-PLT-006 fenceItemsFromApiMaps 批量解析

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::fenceItemsFromApiMaps 批量解析`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004

### TC-PLT-007 vertices 格式: [{lat, lng}, ...] 而非 [[lng, lat], ...]

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::vertices 格式: [{lat, lng}, ...] 而非 [[lng, lat], ...]`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005

### TC-PLT-008 fence detail 解析

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::fence detail 解析`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004

### TC-PLT-009 后端响应包含 id, livestockCode, breed, healthStatus

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端响应包含 id, livestockCode, breed, healthStatus`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-004、REQ-CMC-005

### TC-PLT-010 后端使用 livestockCode 而非 earTag

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端使用 livestockCode 而非 earTag`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-PLT-011 后端坐标字段为 lastLatitude / lastLongitude

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端坐标字段为 lastLatitude / lastLongitude`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005

### TC-PLT-012 healthStatus 值为大写枚举

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::healthStatus 值为大写枚举`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-004、REQ-CMC-005

### TC-PLT-013 后端响应包含 type, status, severity, message

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端响应包含 type, status, severity, message`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005

### TC-PLT-014 status 值为 PENDING/ACKNOWLEDGED/HANDLED/ARCHIVED

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::status 值为 PENDING/ACKNOWLEDGED/HANDLED/ARCHIVED`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005

### TC-PLT-015 severity 值为 CRITICAL/WARNING/INFO

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::severity 值为 CRITICAL/WARNING/INFO`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005

### TC-PLT-016 id 和 livestockId 为 int 类型（非 String）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::id 和 livestockId 为 int 类型（非 String）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-PLT-017 后端使用扁平字段（非 metrics 数组）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端使用扁平字段（非 metrics 数组）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005

### TC-PLT-018 healthSummary 包含 healthy/warning/critical

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::healthSummary 包含 healthy/warning/critical`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-HLT-003、REQ-HLT-005、REQ-CMC-004、REQ-CMC-005

### TC-PLT-019 后端响应包含 id, name, phone, role, tenantId

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端响应包含 id, name, phone, role, tenantId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-IDT-001、REQ-IDT-003

### TC-PLT-020 role 值为大写枚举

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::role 值为大写枚举`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-IDT-004

### TC-PLT-021 id 和 tenantId 为 int 类型

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::id 和 tenantId 为 int 类型`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-IDT-001、REQ-IDT-003

### TC-PLT-022 后端响应包含分页 envelope

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端响应包含分页 envelope`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004

### TC-PLT-023 farm 对象包含 id, name, latitude, longitude

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::farm 对象包含 id, name, latitude, longitude`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-IDT-001、REQ-IDT-003

### TC-PLT-024 SubscriptionStatus.fromJson 解析真实后端响应

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：API 合约 — 订阅
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::SubscriptionStatus.fromJson 解析真实后端响应`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-005

### TC-PLT-025 后端 subscription 响应的实际字段

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端 subscription 响应的实际字段`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-005

### TC-PLT-026 后端 subscription/plans 返回 data 为 List（非分页）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端 subscription/plans 返回 data 为 List（非分页）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002、REQ-CMC-004、REQ-CMC-005

### TC-PLT-027 后端设备响应包含基础字段

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端设备响应包含基础字段`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005

### TC-PLT-028 后端使用分页 envelope

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::后端使用分页 envelope`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004

### TC-PLT-029 ranch-overview envelope \u7ed3\u6784

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::ranch-overview envelope \u7ed3\u6784`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004

### TC-PLT-030 overallStats \u7c7b\u578b\u6b63\u786e

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::overallStats \u7c7b\u578b\u6b63\u786e`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005

### TC-PLT-031 fences \u683c\u5f0f

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::fences \u683c\u5f0f`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004

### TC-PLT-032 livestockMarkers \u683c\u5f0f

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::livestockMarkers \u683c\u5f0f`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-RCH-001、REQ-RCH-002

### TC-PLT-033 alerts \u683c\u5f0f

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::alerts \u683c\u5f0f`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-CMC-004、REQ-CMC-005

### TC-PLT-034 所有 fixture 包含 {code, message, data}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：API 合约 — 通用 envelope
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::所有 fixture 包含 {code, message, data}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-CMC-004

### TC-PLT-035 列表 fixture 使用 {items, total, page, pageSize} 分页

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/contract/api_contract_test.dart::列表 fixture 使用 {items, total, page, pageSize} 分页`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005

### TC-PLT-036 farmGet(farmId) 全局为 null 时使用 farmId，不抛 StateError

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/api_client_farm_id_param_test.dart::farmGet(farmId) 全局为 null 时使用 farmId，不抛 StateError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-PLT-037 farmGet 无 farmId 且全局 null 时抛 StateError("No active farm")

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/api_client_farm_id_param_test.dart::farmGet 无 farmId 且全局 null 时抛 StateError("No active farm")`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-PLT-038 farmGet(farmId) 不修改全局 _activeFarmId

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/api_client_farm_id_param_test.dart::farmGet(farmId) 不修改全局 _activeFarmId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-PLT-039 farmPost body + farmId 共存，不污染全局

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/api_client_farm_id_param_test.dart::farmPost body + farmId 共存，不污染全局`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-PLT-040 AuthException is rethrown when code is not AUTH_INVALID_TOKEN

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::AuthException is rethrown when code is not AUTH_INVALID_TOKEN`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002

### TC-PLT-041 AuthException carries statusCode and code

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::AuthException carries statusCode and code`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002

### TC-PLT-042 Refresh fields are initially idle

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::Refresh fields are initially idle`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-043 farmGet throws StateError when no active farm

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::farmGet throws StateError when no active farm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-PLT-044 farmPost throws StateError when no active farm

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::farmPost throws StateError when no active farm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-PLT-045 expiresInSeconds returns negative for expired payload

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：JwtDecoder
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::expiresInSeconds returns negative for expired payload`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002

### TC-PLT-046 expiresInSeconds returns positive for future payload

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/api_client_refresh_test.dart::expiresInSeconds returns positive for future payload`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-047 root token/user 存取与 clearRoot 只清 root

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：超管双 token 与最近切换存储（2026-10-19 §4.2）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/jwt_storage_root_test.dart::root token/user 存取与 clearRoot 只清 root`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002

### TC-PLT-048 logout clear() 清全部五类 key（含 root 与最近切换）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/jwt_storage_root_test.dart::logout clear() 清全部五类 key（含 root 与最近切换）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002

### TC-PLT-049 recent contexts 损坏数据安全回退为空

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/api/jwt_storage_root_test.dart::recent contexts 损坏数据安全回退为空`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002、REQ-IDT-001、REQ-IDT-003

### TC-PLT-050 v1 存量库升级：shape 列补齐 + 版本推进 v2 + 存量行缺省 polygon

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/database/app_database_shape_migration_test.dart::v1 存量库升级：shape 列补齐 + 版本推进 v2 + 存量行缺省 polygon`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-NFR-001、REQ-NFR-002

### TC-PLT-051 全新库直接建 v2：shape 列在位且 ALTER 守卫不重复执行

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/database/app_database_shape_migration_test.dart::全新库直接建 v2：shape 列在位且 ALTER 守卫不重复执行`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-NFR-001、REQ-NFR-002

### TC-PLT-052 round-trip wgs84→gcj02→wgs84 偏差 < 0.5m

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：gcj02ToWgs84
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/coord_transform_test.dart::round-trip wgs84→gcj02→wgs84 偏差 < 0.5m`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-053 海外坐标不变

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/coord_transform_test.dart::海外坐标不变`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-054 迭代收敛精度 < 0.1m

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/coord_transform_test.dart::迭代收敛精度 < 0.1m`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-055 批量逆转换

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：gcj02ToWgs84All
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/coord_transform_test.dart::批量逆转换`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-056 no fences → farm registered coordinates

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：resolveFarmMapCenter
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::no fences → farm registered coordinates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001

### TC-PLT-057 fences win over farm coordinates (vertex average of first fence)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::fences win over farm coordinates (vertex average of first fence)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001

### TC-PLT-058 empty fence ring is skipped, next fence used

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::empty fence ring is skipped, next fence used`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001

### TC-PLT-059 no fences and no farm coordinates → null (keep default)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::no fences and no farm coordinates → null (keep default)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001

### TC-PLT-060 shouldTransform converts farm coordinates to GCJ-02

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::shouldTransform converts farm coordinates to GCJ-02`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-061 Changsha demo farm with fences keeps centering inside its area

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/farm_map_center_test.dart::Changsha demo farm with fences keeps centering inside its area`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001

### TC-PLT-062 China time zone → single 高德 source with GCJ-02 transform

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：buildSmartTileProvider — tile source by client time zone
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_factory_test.dart::China time zone → single 高德 source with GCJ-02 transform`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-063 non-China time zone → single OSM source, no transform

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_factory_test.dart::non-China time zone → single OSM source, no transform`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-064 tile-source resolve failure never blocks provider creation

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_factory_test.dart::tile-source resolve failure never blocks provider creation`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-065 offline probe falls back to server tiles when online unreachable

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_factory_test.dart::offline probe falls back to server tiles when online unreachable`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-066 OSM online → shouldTransformCoordinates false

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：SmartTileProvider
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::OSM online → shouldTransformCoordinates false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-067 高德 online → shouldTransformCoordinates true

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::高德 online → shouldTransformCoordinates true`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-068 高德 online but offline (server tiles) → transform false

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::高德 online but offline (server tiles) → transform false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-069 activeSourceName reflects the configured online source

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::activeSourceName reflects the configured online source`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-070 getImage online → NetworkImage from configured source

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::getImage online → NetworkImage from configured source`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-071 getImage offline + serverTileUrl → tileserver NetworkImage

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_test.dart::getImage offline + serverTileUrl → tileserver NetworkImage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-072 高德在线 + 无本地瓦片：需要变换（原全局 flag 语义，真高德区域）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::高德在线 + 无本地瓦片：需要变换（原全局 flag 语义，真高德区域）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-073 高德在线 + 本地 mbtiles 覆盖该点：不变换（离线瓦片是 WGS-84）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::高德在线 + 本地 mbtiles 覆盖该点：不变换（离线瓦片是 WGS-84）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-074 高德在线 + 本地 mbtiles 只覆盖远处：仍需变换

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::高德在线 + 本地 mbtiles 只覆盖远处：仍需变换`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-075 高德在线 + mbtiles 覆盖但该 zoom 超出文件范围：需变换（在线接管）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::高德在线 + mbtiles 覆盖但该 zoom 超出文件范围：需变换（在线接管）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-076 离线回落（server tileserver = WGS-84）：永不变换

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::离线回落（server tileserver = WGS-84）：永不变换`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-077 非中国时区（OSM = WGS-84）：永不变换

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::非中国时区（OSM = WGS-84）：永不变换`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-078 无锚点回落：全局 flag 语义保留（ranch_page 混合范式）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/map/smart_tile_provider_transform_decision_test.dart::无锚点回落：全局 flag 语义保留（ranch_page 混合范式）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-079 $role 编辑围栏 ${RolePermission.canEditFence(role)}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：围栏权限
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 编辑围栏 ${RolePermission.canEditFence(role)}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-004

### TC-PLT-080 $role 添加围栏 ${RolePermission.canAddFence(role)}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 添加围栏 ${RolePermission.canAddFence(role)}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-004

### TC-PLT-081 $role 删除围栏 ${RolePermission.canDeleteFence(role)}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 删除围栏 ${RolePermission.canDeleteFence(role)}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-004

### TC-PLT-082 $role 确认告警 $canAck

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：告警权限
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 确认告警 $canAck`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-083 $role 处理告警 ${canHandleRoles.contains(role)}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 处理告警 ${canHandleRoles.contains(role)}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-084 $role 归档告警 ${role == UserRole.owner}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 归档告警 ${role == UserRole.owner}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-085 $role 批量告警 ${canHandleRoles.contains(role)}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 批量告警 ${canHandleRoles.contains(role)}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-086 $role 管理租户 $canManage

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：租户权限
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 管理租户 $canManage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-087 $role 创建租户 $canManage

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 创建租户 $canManage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-088 $role 编辑租户 $canManage

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 编辑租户 $canManage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-089 $role 删除租户 $canManage

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 删除租户 $canManage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-090 $role 切换租户状态 $canManage

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 切换租户状态 $canManage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-091 $role 调整License $canManage

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 调整License $canManage`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-008、REQ-IDT-004

### TC-PLT-092 $role 管理订阅 ${role == UserRole.owner}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：订阅权限
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 管理订阅 ${role == UserRole.owner}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-093 $role 创建牧场 $canCreate

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：牧场权限
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 创建牧场 $canCreate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-094 $role 查看B端看板 ${role == UserRole.b2bAdmin}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：B端权限
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 查看B端看板 ${role == UserRole.b2bAdmin}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-095 $role 查看合同 ${role == UserRole.b2bAdmin}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 查看合同 ${role == UserRole.b2bAdmin}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-096 $role 管理旗下牧工 ${role == UserRole.b2bAdmin}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 管理旗下牧工 ${role == UserRole.b2bAdmin}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-097 $role 管理合同 ${role == UserRole.platformAdmin}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：平台权限
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 管理合同 ${role == UserRole.platformAdmin}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-098 $role 查看对账 $canViewRevenue

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 查看对账 $canViewRevenue`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-004、REQ-CMC-005、REQ-IDT-004

### TC-PLT-099 $role 计算分润 ${role == UserRole.platformAdmin}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 计算分润 ${role == UserRole.platformAdmin}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-100 $role 管理订阅服务 ${role == UserRole.platformAdmin}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 管理订阅服务 ${role == UserRole.platformAdmin}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-101 $role 审批API授权 $canReview

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：API授权权限
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 审批API授权 $canReview`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-102 $role 繁育操作 ${role == UserRole.owner}

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：数智孪生权限
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/permissions/role_permission_test.dart::$role 繁育操作 ${role == UserRole.owner}`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-004

### TC-PLT-103 parses livestock signal with nested rumen metrics

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/sync/signal_models_test.dart::parses livestock signal with nested rumen metrics`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IOT-001、REQ-IOT-002、REQ-HLT-001、REQ-HLT-002

### TC-PLT-104 missing presence signal defaults to normal

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/sync/signal_models_test.dart::missing presence signal defaults to normal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-PLT-105 missing metrics remain missing instead of becoming zero

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/sync/signal_models_test.dart::missing metrics remain missing instead of becoming zero`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-PLT-106 parses position updates

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/sync/signal_models_test.dart::parses position updates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-PLT-107 unsubscribe removes only the matching transport mode

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/sync/signal_sync_controller_test.dart::unsubscribe removes only the matching transport mode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-PLT-108 cursor-too-old resets cursor and performs full resync

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/sync/signal_sync_controller_test.dart::cursor-too-old resets cursor and performs full resync`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-PLT-109 livestock refresh publishes status cursor to listeners

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/sync/signal_sync_controller_test.dart::livestock refresh publishes status cursor to listeners`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005、REQ-RCH-001

### TC-PLT-110 connected SSE stops polling and events refresh once

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/sync/signal_sync_controller_test.dart::connected SSE stops polling and events refresh once`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-PLT-111 SSE failure falls back to three-second polling

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/sync/signal_sync_controller_test.dart::SSE failure falls back to three-second polling`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-PLT-001、REQ-PLT-002、REQ-PLT-005

### TC-PLT-112 Asia/Shanghai and other UTC+8 China ids → true

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：isChinaTimeZone
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/timezone/time_zone_controller_test.dart::Asia/Shanghai and other UTC+8 China ids → true`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-113 non-China ids → false

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/timezone/time_zone_controller_test.dart::non-China ids → false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-114 null id (follow system) uses UTC+8 offset heuristic

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/timezone/time_zone_controller_test.dart::null id (follow system) uses UTC+8 offset heuristic`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-115 setTimeZone persists and updates state

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：TimeZoneController
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/timezone/time_zone_controller_test.dart::setTimeZone persists and updates state`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-116 restore reads persisted value

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/core/timezone/time_zone_controller_test.dart::restore reads persisted value`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-117 owner 登录返回 JWT 和用户信息

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 所属分组：e2e — 认证
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::owner 登录返回 JWT 和用户信息`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002

### TC-PLT-118 错误密码登录失败

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::错误密码登录失败`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-119 无 token 访问受保护端点返回 401

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::无 token 访问受保护端点返回 401`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002

### TC-PLT-120 GET /me 返回当前用户

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 所属分组：e2e — 个人信息
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /me 返回当前用户`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-121 GET /farms/{id}/dashboard/summary 返回指标

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 所属分组：e2e — 看板
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms/{id}/dashboard/summary 返回指标`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-PLT-122 GET /farms/{id}/fences 返回围栏列表

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 所属分组：e2e — 围栏
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms/{id}/fences 返回围栏列表`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-IDT-001

### TC-PLT-123 围栏 color 字段兼容 String 和 null

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::围栏 color 字段兼容 String 和 null`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-124 GET /farms/{id}/alerts 返回告警列表

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 所属分组：e2e — 告警
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms/{id}/alerts 返回告警列表`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007、REQ-IDT-001、REQ-IDT-003

### TC-PLT-125 告警 status 为合法枚举值

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::告警 status 为合法枚举值`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-126 GET /farms/{id}/livestock 返回牲畜列表

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 所属分组：e2e — 牲畜
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms/{id}/livestock 返回牲畜列表`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-127 GET /subscription 返回当前订阅

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 所属分组：e2e — 订阅
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /subscription 返回当前订阅`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-CMC-001、REQ-CMC-002

### TC-PLT-128 GET /farms 返回牧场列表（含坐标）

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 所属分组：e2e — 牧场
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms 返回牧场列表（含坐标）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003

### TC-PLT-129 GET /farms/{id}/ranch-overview \u8fd4\u56de\u805a\u5408\u6570\u636e

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 所属分组：e2e \u2014 \u7267\u573a\u603b\u89c8
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::GET /farms/{id}/ranch-overview \u8fd4\u56de\u805a\u5408\u6570\u636e`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-001、REQ-IDT-003、REQ-RCH-001、REQ-RCH-002

### TC-PLT-130 fences \u5305\u542b\u56f4\u680f\u5750\u6807

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::fences \u5305\u542b\u56f4\u680f\u5750\u6807`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005

### TC-PLT-131 livestockMarkers \u6709\u5065\u5eb7\u72b6\u6001

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::livestockMarkers \u6709\u5065\u5eb7\u72b6\u6001`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-001、REQ-RCH-002

### TC-PLT-132 alerts \u4e0d\u542b ARCHIVED

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::alerts \u4e0d\u542b ARCHIVED`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-006、REQ-RCH-007

### TC-PLT-133 owner 不能访问 admin 端点

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 所属分组：e2e — 权限边界
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::owner 不能访问 admin 端点`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-134 worker 登录后不能访问订阅

- 优先级：P0
- 前置条件：后端 dev 环境可用；种子账号可登录
- 步骤：运行来源测试 `Mobile/mobile_app/test/e2e/backend_e2e_test.dart::worker 登录后不能访问订阅`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-164 DemoApp applies the high-fidelity theme tokens

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/theme/highfi_theme_test.dart::DemoApp applies the high-fidelity theme tokens`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-IDT-002

### TC-PLT-165 worker 登录后不显示 nav-admin

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/widget_smoke_test.dart::worker 登录后不显示 nav-admin`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-166 导航栏不含旧地图项

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/widget_smoke_test.dart::导航栏不含旧地图项`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-167 owner 导航栏包含牧场和我的两个 Tab

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/widget_smoke_test.dart::owner 导航栏包含牧场和我的两个 Tab`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

### TC-PLT-168 demo app boot smoke test

- 优先级：P2
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/widget_test.dart::demo app boot smoke test`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：—（待人工映射）

