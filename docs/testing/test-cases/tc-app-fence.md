# 测试用例规格：App·围栏编辑与轨迹导入

> 用例域：RCH ｜ 用例数：178
> 生成方式：脚本初稿（tools/generate-test-cases.mjs 解析测试源码），前置/步骤/预期为模板口径，需人工校对分级与细化。
> REQ 编号为按文件/用例名关键词的自动映射，人工校对后定稿。

| 编号 | 用例名称 | 优先级 | 对应 REQ（自动映射） | 来源 |
|---|---|---|---|---|
| TC-RCH-049 | dense sawtooth on a square is deleted down to the corners | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::dense sawtooth on a square is deleted down to the corners` |
| TC-RCH-050 | cumulative shrink never exceeds tolPct of the ORIGINAL area  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::cumulative shrink never exceeds tolPct of the ORIGINAL area ` |
| TC-RCH-051 | ring length floor: a triangle is returned unchanged | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::ring length floor: a triangle is returned unchanged` |
| TC-RCH-052 | input ring is not mutated | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::input ring is not mutated` |
| TC-RCH-053 | order is fixed and sawtooth vertices are pruned by the simplified  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::order is fixed and sawtooth vertices are pruned by the simplified ` |
| TC-RCH-054 | cleaning stats are shared verbatim across the three candidates | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::cleaning stats are shared verbatim across the three candidates` |
| TC-RCH-055 | default-params candidates are bit-identical to a single convert() | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::default-params candidates are bit-identical to a single convert()` |
| TC-RCH-056 | tiny square with an interior point: concave candidates fail while  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::tiny square with an interior point: concave candidates fail while ` |
| TC-RCH-057 | all candidates fail on a collinear track (shared diagnostics) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::all candidates fail on a collinear track (shared diagnostics)` |
| TC-RCH-058 | animal-track params: roaming trim stats ride on every candidate | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::animal-track params: roaming trim stats ride on every candidate` |
| TC-RCH-059 | dense cluster: simplified candidate sheds the detour that  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::dense cluster: simplified candidate sheds the detour that ` |
| TC-RCH-060 | quantile boundary keeps exactly floor(n × quantile) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::quantile boundary keeps exactly floor(n × quantile)` |
| TC-RCH-061 | all-equidistant points trim nothing (small-n full keep) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::all-equidistant points trim nothing (small-n full keep)` |
| TC-RCH-062 | kept preserves the original point order | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::kept preserves the original point order` |
| TC-RCH-063 | keeps at least 3 points even at a tiny quantile | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::keeps at least 3 points even at a tiny quantile` |
| TC-RCH-064 | quantile 1.0 keeps everything | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::quantile 1.0 keeps everything` |
| TC-RCH-065 | empty and <3-point inputs pass through unchanged | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::empty and <3-point inputs pass through unchanged` |
| TC-RCH-066 | zh formats areas >= 0.1 mu with 1 decimal | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::zh formats areas >= 0.1 mu with 1 decimal` |
| TC-RCH-067 | zh keeps exactly-0.1-mu areas on the mu scale (no fallback) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::zh keeps exactly-0.1-mu areas on the mu scale (no fallback)` |
| TC-RCH-068 | zh degrades areas < 0.1 mu to raw square meters | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::zh degrades areas < 0.1 mu to raw square meters` |
| TC-RCH-069 | en formats areas >= 0.01 ha with 2 decimals | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::en formats areas >= 0.01 ha with 2 decimals` |
| TC-RCH-070 | en keeps exactly-0.01-ha areas on the ha scale (no fallback) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::en keeps exactly-0.01-ha areas on the ha scale (no fallback)` |
| TC-RCH-071 | en degrades areas < 0.01 ha to raw square meters | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::en degrades areas < 0.01 ha to raw square meters` |
| TC-RCH-072 | non-zh language codes take the hectare branch | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::non-zh language codes take the hectare branch` |
| TC-RCH-073 | startEditing 后设置 selectedFenceId 与 editSession 关键字段 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::startEditing 后设置 selectedFenceId 与 editSession 关键字段` |
| TC-RCH-074 | moveDraftVertex 后进入 editDirty 且不污染 originalPoints | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::moveDraftVertex 后进入 editDirty 且不污染 originalPoints` |
| TC-RCH-075 | insert/remove/translate 与 undo/redo 会更新真实草稿 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::insert/remove/translate 与 undo/redo 会更新真实草稿` |
| TC-RCH-076 | removeDraftVertex 至少保留 3 个点 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::removeDraftVertex 至少保留 3 个点` |
| TC-RCH-077 | select(null) 可清空 selectedFenceId | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::select(null) 可清空 selectedFenceId` |
| TC-RCH-078 | startEditing 无效 fenceId 时保持原状态 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::startEditing 无效 fenceId 时保持原状态` |
| TC-RCH-079 | moveDraftVertex 无 session 时忽略 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::moveDraftVertex 无 session 时忽略` |
| TC-RCH-080 | moveDraftVertex 索引越界时忽略 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::moveDraftVertex 索引越界时忽略` |
| TC-RCH-081 | delete 删除编辑中的 fence 时清理 editSession 与 editMode | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::delete 删除编辑中的 fence 时清理 editSession 与 editMode` |
| TC-RCH-082 | reloadFromRepository 若编辑 fence 消失则清理编辑状态 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::reloadFromRepository 若编辑 fence 消失则清理编辑状态` |
| TC-RCH-083 | 少于三个点的几何无效 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_save_guard_test.dart::少于三个点的几何无效` |
| TC-RCH-084 | 连续重复点的几何无效 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_save_guard_test.dart::连续重复点的几何无效` |
| TC-RCH-085 | 零面积几何无效 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_save_guard_test.dart::零面积几何无效` |
| TC-RCH-086 | 自交几何无效 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_save_guard_test.dart::自交几何无效` |
| TC-RCH-087 | 仅当前编辑会话可应用保存结果 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_controller_save_guard_test.dart::仅当前编辑会话可应用保存结果` |
| TC-RCH-088 | insertVertex inserts point after the given edge start index | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::insertVertex inserts point after the given edge start index` |
| TC-RCH-089 | insertVertex supports insertion on closing edge | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::insertVertex supports insertion on closing edge` |
| TC-RCH-090 | insertVertex throws RangeError for invalid index | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::insertVertex throws RangeError for invalid index` |
| TC-RCH-091 | removeVertex removes point at the given index | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::removeVertex removes point at the given index` |
| TC-RCH-092 | removeVertex no-op when only three points | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::removeVertex no-op when only three points` |
| TC-RCH-093 | removeVertex throws RangeError for invalid index | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::removeVertex throws RangeError for invalid index` |
| TC-RCH-094 | translate translates all points by provided delta | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::translate translates all points by provided delta` |
| TC-RCH-095 | session keeps defensive immutable copies of input lists | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::session keeps defensive immutable copies of input lists` |
| TC-RCH-096 | session hasChanges reflects point edits | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::session hasChanges reflects point edits` |
| TC-RCH-097 | 深链进入编辑表单：fences 延后到达后名称与类型回填，缺省值不顶替（NIX-415） | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_deep_link_init_test.dart::深链进入编辑表单：fences 延后到达后名称与类型回填，缺省值不顶替（NIX-415）` |
| TC-RCH-098 | 深链进入编辑表单：rectangle 围栏数据到达后类型真回显为矩形（NIX-415） | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_deep_link_init_test.dart::深链进入编辑表单：rectangle 围栏数据到达后类型真回显为矩形（NIX-415）` |
| TC-RCH-099 | 正常入口回归：fences 先于表单就绪时首次构建即回填 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_deep_link_init_test.dart::正常入口回归：fences 先于表单就绪时首次构建即回填` |
| TC-RCH-100 | 高德态：模板顶点经屏幕系（GCJ）往返，保存体仍是 WGS-84 模板值 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_screen_space_roundtrip_test.dart::高德态：模板顶点经屏幕系（GCJ）往返，保存体仍是 WGS-84 模板值` |
| TC-RCH-101 | OSM 态（WGS 瓦片）：无变换，保存体恒等于模板值 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_screen_space_roundtrip_test.dart::OSM 态（WGS 瓦片）：无变换，保存体恒等于模板值` |
| TC-RCH-102 | 离线态（server tileserver = WGS）：无变换，保存体恒等于模板值 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_screen_space_roundtrip_test.dart::离线态（server tileserver = WGS）：无变换，保存体恒等于模板值` |
| TC-RCH-103 | 编辑路径：高德态载入 WGS 围栏不触碰直接保存，顶点恒等往返 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_screen_space_roundtrip_test.dart::编辑路径：高德态载入 WGS 围栏不触碰直接保存，顶点恒等往返` |
| TC-RCH-104 | refreshed page (stack bottom): 取消 exits via /fence, no GoError | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::refreshed page (stack bottom): 取消 exits via /fence, no GoError` |
| TC-RCH-105 | refreshed page: appBar back key exits via /fence too | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::refreshed page: appBar back key exits via /fence too` |
| TC-RCH-106 | with history: 取消 pops back home as before | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::with history: 取消 pops back home as before` |
| TC-RCH-107 | drag-ready hit area: markers expose a 56px grab target and  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::drag-ready hit area: markers expose a 56px grab target and ` |
| TC-RCH-108 | move tool (default): tapping a marker never deletes | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::move tool (default): tapping a marker never deletes` |
| TC-RCH-109 | delete tool: tapping a marker deletes that vertex | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::delete tool: tapping a marker deletes that vertex` |
| TC-RCH-110 | edge midpoint dots exist on every edge (tap-to-insert  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::edge midpoint dots exist on every edge (tap-to-insert ` |
| TC-RCH-111 | manual entry keeps the draw toggle visible (hidden only for  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::manual entry keeps the draw toggle visible (hidden only for ` |
| TC-RCH-112 | polygon keeps its minimum of 3 vertices | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::polygon keeps its minimum of 3 vertices` |
| TC-RCH-113 | manual-entry flow itself stays intact (5 vertices load) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::manual-entry flow itself stays intact (5 vertices load)` |
| TC-RCH-114 | Map payload is kept as-is | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::Map payload is kept as-is` |
| TC-RCH-115 | malformed payload degrades to null | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::malformed payload degrades to null` |
| TC-RCH-116 | missing key stays null | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::missing key stays null` |
| TC-RCH-117 | Map kept / malformed and missing degrade to null | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::Map kept / malformed and missing degrade to null` |
| TC-RCH-118 | renders method/device count/range/generatedAt rows | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::renders method/device count/range/generatedAt rows` |
| TC-RCH-119 | unknown method falls back to the raw value | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::unknown method falls back to the raw value` |
| TC-RCH-120 | renders source card when metadata present | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::renders source card when metadata present` |
| TC-RCH-121 | hidden when metadata is null | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::hidden when metadata is null` |
| TC-RCH-122 | list card renders source card when metadata present | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::list card renders source card when metadata present` |
| TC-RCH-123 | list card hides source card when metadata null | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::list card hides source card when metadata null` |
| TC-RCH-124 | 点在线段上投影距离为 0 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在线段上投影距离为 0` |
| TC-RCH-125 | 点到线段端点的距离 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点到线段端点的距离` |
| TC-RCH-126 | 点到线段外延的距离取端点 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点到线段外延的距离取端点` |
| TC-RCH-127 | 点在边界上距离为 0 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在边界上距离为 0` |
| TC-RCH-128 | 点在边界外 30px 距离为 30 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在边界外 30px 距离为 30` |
| TC-RCH-129 | 点在多边形中心到边界距离为 50 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在多边形中心到边界距离为 50` |
| TC-RCH-130 | 少于 2 个点返回 infinity | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::少于 2 个点返回 infinity` |
| TC-RCH-131 | 点在边界上命中 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在边界上命中` |
| TC-RCH-132 | 点在 40px 内命中 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在 40px 内命中` |
| TC-RCH-133 | 点在 40px 外未命中 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在 40px 外未命中` |
| TC-RCH-134 | 少于 2 个点返回 false | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::少于 2 个点返回 false` |
| TC-RCH-135 | 点在围栏内部命中（Tier 1） | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在围栏内部命中（Tier 1）` |
| TC-RCH-136 | 点在边界 40px 内命中（Tier 2） | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在边界 40px 内命中（Tier 2）` |
| TC-RCH-137 | 点在边界 40px 外未命中 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在边界 40px 外未命中` |
| TC-RCH-138 | 空围栏列表返回空 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::空围栏列表返回空` |
| TC-RCH-139 | Tier 1 优先于 Tier 2（内部命中排在边界命中前面） | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::Tier 1 优先于 Tier 2（内部命中排在边界命中前面）` |
| TC-RCH-140 | 同为 Tier 1 按面积升序排列（嵌套围栏） | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::同为 Tier 1 按面积升序排列（嵌套围栏）` |
| TC-RCH-141 | 同为 Tier 2 按边界距离升序排列 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::同为 Tier 2 按边界距离升序排列` |
| TC-RCH-142 | fencePolygonContainsLatLng inside polygon returns true | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_polygon_contains_test.dart::fencePolygonContainsLatLng inside polygon returns true` |
| TC-RCH-143 | fencePolygonContainsLatLng outside polygon returns false | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_polygon_contains_test.dart::fencePolygonContainsLatLng outside polygon returns false` |
| TC-RCH-144 | fencePolygonContainsLatLng fewer than 3 points returns false | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_polygon_contains_test.dart::fencePolygonContainsLatLng fewer than 3 points returns false` |
| TC-RCH-145 | rectangle preset centres on the anchor | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_template_anchor_test.dart::rectangle preset centres on the anchor` |
| TC-RCH-146 | circle preset centred on the anchor | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_template_anchor_test.dart::circle preset centred on the anchor` |
| TC-RCH-147 | defaults keep the legacy demo-centre behaviour | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_template_anchor_test.dart::defaults keep the legacy demo-centre behaviour` |
| TC-RCH-148 | full flow: pick → preview → envelope → apply | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_track_import_dialog_test.dart::full flow: pick → preview → envelope → apply` |
| TC-RCH-149 | generate disabled when cleaned points < 3 | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_track_import_dialog_test.dart::generate disabled when cleaned points < 3` |
| TC-RCH-150 | parse failure shows snackbar and stays on upload step | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/fence_track_import_dialog_test.dart::parse failure shows snackbar and stays on upload step` |
| TC-RCH-151 | real track2 data terminates | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/real_track2_regression_test.dart::real track2 data terminates` |
| TC-RCH-152 | real track4 data terminates and yields result | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/real_track4_regression_test.dart::real track4 data terminates and yields result` |
| TC-RCH-153 | open out-and-back RTK track terminates and yields usable envelope | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/repro_out_and_back_test.dart::open out-and-back RTK track terminates and yields usable envelope` |
| TC-RCH-154 | initial: editing + candidates + default 14d quick range | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::initial: editing + candidates + default 14d quick range` |
| TC-RCH-155 | editing → loading → previewing with preview payload | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::editing → loading → previewing with preview payload` |
| TC-RCH-156 | parameter changes mark an existing preview stale | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::parameter changes mark an existing preview stale` |
| TC-RCH-157 | loading retains the previous preview until the new one lands | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::loading retains the previous preview until the new one lands` |
| TC-RCH-158 | failed(noData) when the source returns zero points | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::failed(noData) when the source returns zero points` |
| TC-RCH-159 | failed(tooFew) when fewer than 3 valid points remain | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::failed(tooFew) when fewer than 3 valid points remain` |
| TC-RCH-160 | failed(degenerate) for a nearly collinear track | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::failed(degenerate) for a nearly collinear track` |
| TC-RCH-161 | failed → editing is the only inbound edge and keeps the criteria | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::failed → editing is the only inbound edge and keeps the criteria` |
| TC-RCH-162 | previewing → editing (调整条件) keeps devices and range | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::previewing → editing (调整条件) keeps devices and range` |
| TC-RCH-163 | quota full blocks device-step proceed and generate | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::quota full blocks device-step proceed and generate` |
| TC-RCH-164 | unlimited quota (limit null) never blocks | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::unlimited quota (limit null) never blocks` |
| TC-RCH-165 | range over 30 days blocks generate | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::range over 30 days blocks generate` |
| TC-RCH-166 | buildCompletion emits vertices + generation metadata | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::buildCompletion emits vertices + generation metadata` |
| TC-RCH-167 | buildCompletion is null before a successful preview | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::buildCompletion is null before a successful preview` |
| TC-RCH-168 | generate success emits trackDraftGenerateSuccess with counts (低2) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::generate success emits trackDraftGenerateSuccess with counts (低2)` |
| TC-RCH-169 | failed generate emits no trackDraftGenerateSuccess (低2) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::failed generate emits no trackDraftGenerateSuccess (低2)` |
| TC-RCH-170 | farm switch mid-generation drops the stale result (低1) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::farm switch mid-generation drops the stale result (低1)` |
| TC-RCH-171 | generate populates three hull candidates, default 凹包·简化 (v2.1) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::generate populates three hull candidates, default 凹包·简化 (v2.1)` |
| TC-RCH-172 | selectHullMethod swaps the preview in place; stale untouched (v2.1) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::selectHullMethod swaps the preview in place; stale untouched (v2.1)` |
| TC-RCH-173 | unavailable hull candidates cannot be selected (v2.1) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::unavailable hull candidates cannot be selected (v2.1)` |
| TC-RCH-174 | all candidates failed → failed(degenerate) with cleaning stats | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::all candidates failed → failed(degenerate) with cleaning stats` |
| TC-RCH-175 | default params (sliders untouched) stay bit-identical to baseline | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::default params (sliders untouched) stay bit-identical to baseline` |
| TC-RCH-176 | updateAdvancedParams maps sliders, marks stale, regenerate consumes | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::updateAdvancedParams maps sliders, marks stale, regenerate consumes` |
| TC-RCH-177 | restore defaults returns the params to the animalTrack bundle | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::restore defaults returns the params to the animalTrack bundle` |
| TC-RCH-178 | entry card visible for owner (canEditFence=true) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::entry card visible for owner (canEditFence=true)` |
| TC-RCH-179 | entry card hidden for worker (canEditFence=false) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::entry card hidden for worker (canEditFence=false)` |
| TC-RCH-180 | offline tap shows hint and does not open the wizard | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::offline tap shows hint and does not open the wizard` |
| TC-RCH-181 | mobile transport failure (SocketException) also triggers the offline  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::mobile transport failure (SocketException) also triggers the offline ` |
| TC-RCH-182 | wizard confirm loads vertices and create save body carries  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::wizard confirm loads vertices and create save body carries ` |
| TC-RCH-183 | edit save body never carries generationMetadata (语义锁) | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::edit save body never carries generationMetadata (语义锁)` |
| TC-RCH-184 | save with 403 QUOTA_EXCEEDED shows the quota copy, not the generic  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::save with 403 QUOTA_EXCEEDED shows the quota copy, not the generic ` |
| TC-RCH-185 | stale device row shows amber warning and 65% opacity | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::stale device row shows amber warning and 65% opacity` |
| TC-RCH-186 | quota full disables the next button and shows the hint | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::quota full disables the next button and shows the hint` |
| TC-RCH-187 | range over 30 days shows warning and disables generate | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::range over 30 days shows warning and disables generate` |
| TC-RCH-188 | full wizard flow: device → range → preview → confirm | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::full wizard flow: device → range → preview → confirm` |
| TC-RCH-189 | failure branch: noData | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::failure branch: noData` |
| TC-RCH-190 | failure branch: tooFew | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::failure branch: tooFew` |
| TC-RCH-191 | failure branch: degenerate + only exit back to editing | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::failure branch: degenerate + only exit back to editing` |
| TC-RCH-192 | wide layout renders the desktop panel with left 360px panel | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::wide layout renders the desktop panel with left 360px panel` |
| TC-RCH-193 | desktop panel shows the generation source card after a preview and  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::desktop panel shows the generation source card after a preview and ` |
| TC-RCH-194 | narrow layout renders the mobile wizard | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::narrow layout renders the mobile wizard` |
| TC-RCH-195 | hull switcher chips render selected/unselected states and the stat  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::hull switcher chips render selected/unselected states and the stat ` |
| TC-RCH-196 | unavailable hull chips are greyed out and reject selection  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::unavailable hull chips are greyed out and reject selection ` |
| TC-RCH-197 | advanced params section collapses by default and expands with three  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::advanced params section collapses by default and expands with three ` |
| TC-RCH-198 | dragging a slider pushes params to the controller and marks the  | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::dragging a slider pushes params to the controller and marks the ` |
| TC-RCH-199 | rectangle walk converges to the walked outline | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::rectangle walk converges to the walked outline` |
| TC-RCH-200 | L-shape keeps the concave corner | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::L-shape keeps the concave corner` |
| TC-RCH-201 | reversed walk direction yields equivalent envelope | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::reversed walk direction yields equivalent envelope` |
| TC-RCH-202 | separated clusters keep the largest inner face | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::separated clusters keep the largest inner face` |
| TC-RCH-203 | collinear points are rejected as degenerate | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::collinear points are rejected as degenerate` |
| TC-RCH-204 | too few points fail with tooFewPoints | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::too few points fail with tooFewPoints` |
| TC-RCH-205 | stationary duplicate cluster is merged away | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::stationary duplicate cluster is merged away` |
| TC-RCH-206 | noisy dense circle respects the vertex cap | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::noisy dense circle respects the vertex cap` |
| TC-RCH-207 | animal-track params keep 30m accuracy points dropped by defaults | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::animal-track params keep 30m accuracy points dropped by defaults` |
| TC-RCH-208 | animal-track params report roaming trim count and trimmed points | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::animal-track params report roaming trim count and trimmed points` |
| TC-RCH-209 | explicit gpxDefault params are equivalent to the default call | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::explicit gpxDefault params are equivalent to the default call` |
| TC-RCH-330 | coordinatesToLatLngPoints maps lng lat pairs to LatLng | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_dto_test.dart::coordinatesToLatLngPoints maps lng lat pairs to LatLng` |
| TC-RCH-331 | livestockCountsByFenceId aggregates fenceId | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_dto_test.dart::livestockCountsByFenceId aggregates fenceId` |
| TC-RCH-332 | fenceItemFromJson builds FenceItem from API map | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_dto_test.dart::fenceItemFromJson builds FenceItem from API map` |
| TC-RCH-333 | fenceItemFromJson maps the shape key to the FenceType enum | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_dto_test.dart::fenceItemFromJson maps the shape key to the FenceType enum` |
| TC-RCH-334 | fenceItemFromJson prefers the API area and falls back to vertices | P1 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_dto_test.dart::fenceItemFromJson prefers the API area and falls back to vertices` |
| TC-RCH-335 | maps a square ring with 12% margins | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::maps a square ring with 12% margins` |
| TC-RCH-336 | clamps extreme flat shapes to the 20% floor | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::clamps extreme flat shapes to the 20% floor` |
| TC-RCH-337 | includes out-of-ring dots in the bounds | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::includes out-of-ring dots in the bounds` |
| TC-RCH-338 | returns null for empty rings | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::returns null for empty rings` |
| TC-RCH-339 | safe dots stay fully opaque | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::safe dots stay fully opaque` |
| TC-RCH-340 | watch and alert dip to the 0.30 floor | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::watch and alert dip to the 0.30 floor` |
| TC-RCH-341 | alert phase is continuous across the master wrap | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::alert phase is continuous across the master wrap` |
| TC-RCH-342 | on-length totals perimeter * on/(on+off) for a closed square | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::on-length totals perimeter * on/(on+off) for a closed square` |
| TC-RCH-343 | long dashes cross vertices as single contours | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::long dashes cross vertices as single contours` |
| TC-RCH-344 | returns empty path for fewer than two points | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::returns empty path for fewer than two points` |
| TC-RCH-345 | rotated polygons keep vertex-crossing dashes connected | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::rotated polygons keep vertex-crossing dashes connected` |
| TC-RCH-346 | repaints on progress, mode, color or grid change | P2 | REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006 | `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::repaints on progress, mode, color or grid change` |

## 用例明细（初稿模板）

### TC-RCH-049 dense sawtooth on a square is deleted down to the corners

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：simplifyByAreaContribution
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::dense sawtooth on a square is deleted down to the corners`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-050 cumulative shrink never exceeds tolPct of the ORIGINAL area 

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::cumulative shrink never exceeds tolPct of the ORIGINAL area `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-051 ring length floor: a triangle is returned unchanged

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::ring length floor: a triangle is returned unchanged`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-052 input ring is not mutated

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::input ring is not mutated`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-053 order is fixed and sawtooth vertices are pruned by the simplified 

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：buildTrackDraftCandidates
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::order is fixed and sawtooth vertices are pruned by the simplified `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-054 cleaning stats are shared verbatim across the three candidates

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::cleaning stats are shared verbatim across the three candidates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-055 default-params candidates are bit-identical to a single convert()

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::default-params candidates are bit-identical to a single convert()`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-056 tiny square with an interior point: concave candidates fail while 

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::tiny square with an interior point: concave candidates fail while `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-057 all candidates fail on a collinear track (shared diagnostics)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::all candidates fail on a collinear track (shared diagnostics)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-058 animal-track params: roaming trim stats ride on every candidate

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::animal-track params: roaming trim stats ride on every candidate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-059 dense cluster: simplified candidate sheds the detour that 

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/envelope_candidates_test.dart::dense cluster: simplified candidate sheds the detour that `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-060 quantile boundary keeps exactly floor(n × quantile)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::quantile boundary keeps exactly floor(n × quantile)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-061 all-equidistant points trim nothing (small-n full keep)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::all-equidistant points trim nothing (small-n full keep)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-062 kept preserves the original point order

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::kept preserves the original point order`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-063 keeps at least 3 points even at a tiny quantile

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::keeps at least 3 points even at a tiny quantile`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-064 quantile 1.0 keeps everything

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::quantile 1.0 keeps everything`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-065 empty and <3-point inputs pass through unchanged

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/roaming_trim_test.dart::empty and <3-point inputs pass through unchanged`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-066 zh formats areas >= 0.1 mu with 1 decimal

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::zh formats areas >= 0.1 mu with 1 decimal`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-067 zh keeps exactly-0.1-mu areas on the mu scale (no fallback)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::zh keeps exactly-0.1-mu areas on the mu scale (no fallback)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-068 zh degrades areas < 0.1 mu to raw square meters

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::zh degrades areas < 0.1 mu to raw square meters`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-069 en formats areas >= 0.01 ha with 2 decimals

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::en formats areas >= 0.01 ha with 2 decimals`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-070 en keeps exactly-0.01-ha areas on the ha scale (no fallback)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::en keeps exactly-0.01-ha areas on the ha scale (no fallback)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-071 en degrades areas < 0.01 ha to raw square meters

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::en degrades areas < 0.01 ha to raw square meters`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-072 non-zh language codes take the hectare branch

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/domain/track_draft_area_test.dart::non-zh language codes take the hectare branch`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-073 startEditing 后设置 selectedFenceId 与 editSession 关键字段

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::startEditing 后设置 selectedFenceId 与 editSession 关键字段`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-074 moveDraftVertex 后进入 editDirty 且不污染 originalPoints

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::moveDraftVertex 后进入 editDirty 且不污染 originalPoints`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-075 insert/remove/translate 与 undo/redo 会更新真实草稿

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::insert/remove/translate 与 undo/redo 会更新真实草稿`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-076 removeDraftVertex 至少保留 3 个点

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::removeDraftVertex 至少保留 3 个点`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-077 select(null) 可清空 selectedFenceId

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::select(null) 可清空 selectedFenceId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-078 startEditing 无效 fenceId 时保持原状态

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::startEditing 无效 fenceId 时保持原状态`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-079 moveDraftVertex 无 session 时忽略

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::moveDraftVertex 无 session 时忽略`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-080 moveDraftVertex 索引越界时忽略

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::moveDraftVertex 索引越界时忽略`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-081 delete 删除编辑中的 fence 时清理 editSession 与 editMode

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::delete 删除编辑中的 fence 时清理 editSession 与 editMode`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-082 reloadFromRepository 若编辑 fence 消失则清理编辑状态

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_edit_session_test.dart::reloadFromRepository 若编辑 fence 消失则清理编辑状态`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-083 少于三个点的几何无效

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_save_guard_test.dart::少于三个点的几何无效`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-084 连续重复点的几何无效

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_save_guard_test.dart::连续重复点的几何无效`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-085 零面积几何无效

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_save_guard_test.dart::零面积几何无效`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-086 自交几何无效

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_save_guard_test.dart::自交几何无效`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-087 仅当前编辑会话可应用保存结果

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_controller_save_guard_test.dart::仅当前编辑会话可应用保存结果`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-088 insertVertex inserts point after the given edge start index

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：FenceEditOperations
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::insertVertex inserts point after the given edge start index`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-089 insertVertex supports insertion on closing edge

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::insertVertex supports insertion on closing edge`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-090 insertVertex throws RangeError for invalid index

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::insertVertex throws RangeError for invalid index`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-091 removeVertex removes point at the given index

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::removeVertex removes point at the given index`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-092 removeVertex no-op when only three points

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::removeVertex no-op when only three points`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-093 removeVertex throws RangeError for invalid index

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::removeVertex throws RangeError for invalid index`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-094 translate translates all points by provided delta

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::translate translates all points by provided delta`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-095 session keeps defensive immutable copies of input lists

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::session keeps defensive immutable copies of input lists`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-096 session hasChanges reflects point edits

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_edit_operations_test.dart::session hasChanges reflects point edits`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-097 深链进入编辑表单：fences 延后到达后名称与类型回填，缺省值不顶替（NIX-415）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_deep_link_init_test.dart::深链进入编辑表单：fences 延后到达后名称与类型回填，缺省值不顶替（NIX-415）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-098 深链进入编辑表单：rectangle 围栏数据到达后类型真回显为矩形（NIX-415）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_deep_link_init_test.dart::深链进入编辑表单：rectangle 围栏数据到达后类型真回显为矩形（NIX-415）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-099 正常入口回归：fences 先于表单就绪时首次构建即回填

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_deep_link_init_test.dart::正常入口回归：fences 先于表单就绪时首次构建即回填`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-100 高德态：模板顶点经屏幕系（GCJ）往返，保存体仍是 WGS-84 模板值

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_screen_space_roundtrip_test.dart::高德态：模板顶点经屏幕系（GCJ）往返，保存体仍是 WGS-84 模板值`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-101 OSM 态（WGS 瓦片）：无变换，保存体恒等于模板值

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_screen_space_roundtrip_test.dart::OSM 态（WGS 瓦片）：无变换，保存体恒等于模板值`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-102 离线态（server tileserver = WGS）：无变换，保存体恒等于模板值

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_screen_space_roundtrip_test.dart::离线态（server tileserver = WGS）：无变换，保存体恒等于模板值`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-103 编辑路径：高德态载入 WGS 围栏不触碰直接保存，顶点恒等往返

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_screen_space_roundtrip_test.dart::编辑路径：高德态载入 WGS 围栏不触碰直接保存，顶点恒等往返`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-104 refreshed page (stack bottom): 取消 exits via /fence, no GoError

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::refreshed page (stack bottom): 取消 exits via /fence, no GoError`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-105 refreshed page: appBar back key exits via /fence too

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::refreshed page: appBar back key exits via /fence too`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-106 with history: 取消 pops back home as before

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::with history: 取消 pops back home as before`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-107 drag-ready hit area: markers expose a 56px grab target and 

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::drag-ready hit area: markers expose a 56px grab target and `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-108 move tool (default): tapping a marker never deletes

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::move tool (default): tapping a marker never deletes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-109 delete tool: tapping a marker deletes that vertex

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::delete tool: tapping a marker deletes that vertex`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-110 edge midpoint dots exist on every edge (tap-to-insert 

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::edge midpoint dots exist on every edge (tap-to-insert `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-111 manual entry keeps the draw toggle visible (hidden only for 

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::manual entry keeps the draw toggle visible (hidden only for `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-112 polygon keeps its minimum of 3 vertices

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::polygon keeps its minimum of 3 vertices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-113 manual-entry flow itself stays intact (5 vertices load)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_form_vertex_exit_test.dart::manual-entry flow itself stays intact (5 vertices load)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-114 Map payload is kept as-is

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：fenceItemFromJson generationMetadata passthrough
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::Map payload is kept as-is`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-115 malformed payload degrades to null

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::malformed payload degrades to null`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-116 missing key stays null

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::missing key stays null`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-117 Map kept / malformed and missing degrade to null

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：RanchFenceData.fromJson generationMetadata passthrough
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::Map kept / malformed and missing degrade to null`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-118 renders method/device count/range/generatedAt rows

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：FenceGenerationSourceCard widget
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::renders method/device count/range/generatedAt rows`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-119 unknown method falls back to the raw value

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::unknown method falls back to the raw value`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-120 renders source card when metadata present

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：mount point: ranch_fence_tab _FenceDetailCard
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::renders source card when metadata present`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-121 hidden when metadata is null

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::hidden when metadata is null`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-122 list card renders source card when metadata present

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::list card renders source card when metadata present`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-123 list card hides source card when metadata null

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_generation_source_card_test.dart::list card hides source card when metadata null`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-124 点在线段上投影距离为 0

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：distanceToSegment
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在线段上投影距离为 0`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-125 点到线段端点的距离

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点到线段端点的距离`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-126 点到线段外延的距离取端点

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点到线段外延的距离取端点`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-127 点在边界上距离为 0

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：nearestDistanceToPolygonBoundary
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在边界上距离为 0`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-128 点在边界外 30px 距离为 30

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在边界外 30px 距离为 30`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-129 点在多边形中心到边界距离为 50

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在多边形中心到边界距离为 50`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-130 少于 2 个点返回 infinity

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::少于 2 个点返回 infinity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-131 点在边界上命中

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：isPointNearPolygonBoundary
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在边界上命中`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-132 点在 40px 内命中

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在 40px 内命中`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-133 点在 40px 外未命中

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在 40px 外未命中`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-134 少于 2 个点返回 false

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::少于 2 个点返回 false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-135 点在围栏内部命中（Tier 1）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：detectFenceHits
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在围栏内部命中（Tier 1）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-136 点在边界 40px 内命中（Tier 2）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在边界 40px 内命中（Tier 2）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-137 点在边界 40px 外未命中

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::点在边界 40px 外未命中`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-138 空围栏列表返回空

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::空围栏列表返回空`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-139 Tier 1 优先于 Tier 2（内部命中排在边界命中前面）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::Tier 1 优先于 Tier 2（内部命中排在边界命中前面）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-140 同为 Tier 1 按面积升序排列（嵌套围栏）

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::同为 Tier 1 按面积升序排列（嵌套围栏）`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-141 同为 Tier 2 按边界距离升序排列

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_hit_detection_test.dart::同为 Tier 2 按边界距离升序排列`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-142 fencePolygonContainsLatLng inside polygon returns true

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_polygon_contains_test.dart::fencePolygonContainsLatLng inside polygon returns true`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-143 fencePolygonContainsLatLng outside polygon returns false

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_polygon_contains_test.dart::fencePolygonContainsLatLng outside polygon returns false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-144 fencePolygonContainsLatLng fewer than 3 points returns false

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_polygon_contains_test.dart::fencePolygonContainsLatLng fewer than 3 points returns false`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-145 rectangle preset centres on the anchor

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：fenceTemplatePresetFor anchoring
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_template_anchor_test.dart::rectangle preset centres on the anchor`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-146 circle preset centred on the anchor

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_template_anchor_test.dart::circle preset centred on the anchor`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-147 defaults keep the legacy demo-centre behaviour

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_template_anchor_test.dart::defaults keep the legacy demo-centre behaviour`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-148 full flow: pick → preview → envelope → apply

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_track_import_dialog_test.dart::full flow: pick → preview → envelope → apply`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-149 generate disabled when cleaned points < 3

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_track_import_dialog_test.dart::generate disabled when cleaned points < 3`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-150 parse failure shows snackbar and stays on upload step

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/fence_track_import_dialog_test.dart::parse failure shows snackbar and stays on upload step`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-151 real track2 data terminates

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/real_track2_regression_test.dart::real track2 data terminates`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-152 real track4 data terminates and yields result

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/real_track4_regression_test.dart::real track4 data terminates and yields result`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-153 open out-and-back RTK track terminates and yields usable envelope

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/repro_out_and_back_test.dart::open out-and-back RTK track terminates and yields usable envelope`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-154 initial: editing + candidates + default 14d quick range

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::initial: editing + candidates + default 14d quick range`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-155 editing → loading → previewing with preview payload

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::editing → loading → previewing with preview payload`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-156 parameter changes mark an existing preview stale

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::parameter changes mark an existing preview stale`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-157 loading retains the previous preview until the new one lands

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::loading retains the previous preview until the new one lands`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-158 failed(noData) when the source returns zero points

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::failed(noData) when the source returns zero points`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-159 failed(tooFew) when fewer than 3 valid points remain

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::failed(tooFew) when fewer than 3 valid points remain`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-160 failed(degenerate) for a nearly collinear track

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::failed(degenerate) for a nearly collinear track`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-161 failed → editing is the only inbound edge and keeps the criteria

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::failed → editing is the only inbound edge and keeps the criteria`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-162 previewing → editing (调整条件) keeps devices and range

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::previewing → editing (调整条件) keeps devices and range`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-163 quota full blocks device-step proceed and generate

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::quota full blocks device-step proceed and generate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-164 unlimited quota (limit null) never blocks

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::unlimited quota (limit null) never blocks`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-165 range over 30 days blocks generate

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::range over 30 days blocks generate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-166 buildCompletion emits vertices + generation metadata

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::buildCompletion emits vertices + generation metadata`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-167 buildCompletion is null before a successful preview

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::buildCompletion is null before a successful preview`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-168 generate success emits trackDraftGenerateSuccess with counts (低2)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::generate success emits trackDraftGenerateSuccess with counts (低2)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-169 failed generate emits no trackDraftGenerateSuccess (低2)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::failed generate emits no trackDraftGenerateSuccess (低2)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-170 farm switch mid-generation drops the stale result (低1)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::farm switch mid-generation drops the stale result (低1)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-171 generate populates three hull candidates, default 凹包·简化 (v2.1)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::generate populates three hull candidates, default 凹包·简化 (v2.1)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-172 selectHullMethod swaps the preview in place; stale untouched (v2.1)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::selectHullMethod swaps the preview in place; stale untouched (v2.1)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-173 unavailable hull candidates cannot be selected (v2.1)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::unavailable hull candidates cannot be selected (v2.1)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-174 all candidates failed → failed(degenerate) with cleaning stats

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::all candidates failed → failed(degenerate) with cleaning stats`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-175 default params (sliders untouched) stay bit-identical to baseline

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::default params (sliders untouched) stay bit-identical to baseline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-176 updateAdvancedParams maps sliders, marks stale, regenerate consumes

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::updateAdvancedParams maps sliders, marks stale, regenerate consumes`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-177 restore defaults returns the params to the animalTrack bundle

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_controller_test.dart::restore defaults returns the params to the animalTrack bundle`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-178 entry card visible for owner (canEditFence=true)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::entry card visible for owner (canEditFence=true)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-179 entry card hidden for worker (canEditFence=false)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::entry card hidden for worker (canEditFence=false)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-180 offline tap shows hint and does not open the wizard

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::offline tap shows hint and does not open the wizard`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-181 mobile transport failure (SocketException) also triggers the offline 

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::mobile transport failure (SocketException) also triggers the offline `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-182 wizard confirm loads vertices and create save body carries 

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::wizard confirm loads vertices and create save body carries `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-183 edit save body never carries generationMetadata (语义锁)

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::edit save body never carries generationMetadata (语义锁)`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-184 save with 403 QUOTA_EXCEEDED shows the quota copy, not the generic 

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_entry_test.dart::save with 403 QUOTA_EXCEEDED shows the quota copy, not the generic `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-185 stale device row shows amber warning and 65% opacity

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::stale device row shows amber warning and 65% opacity`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-186 quota full disables the next button and shows the hint

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::quota full disables the next button and shows the hint`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-187 range over 30 days shows warning and disables generate

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::range over 30 days shows warning and disables generate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-188 full wizard flow: device → range → preview → confirm

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::full wizard flow: device → range → preview → confirm`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-189 failure branch: noData

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::failure branch: noData`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-190 failure branch: tooFew

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::failure branch: tooFew`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-191 failure branch: degenerate + only exit back to editing

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::failure branch: degenerate + only exit back to editing`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-192 wide layout renders the desktop panel with left 360px panel

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::wide layout renders the desktop panel with left 360px panel`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-193 desktop panel shows the generation source card after a preview and 

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::desktop panel shows the generation source card after a preview and `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-194 narrow layout renders the mobile wizard

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::narrow layout renders the mobile wizard`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-195 hull switcher chips render selected/unselected states and the stat 

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::hull switcher chips render selected/unselected states and the stat `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-196 unavailable hull chips are greyed out and reject selection 

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::unavailable hull chips are greyed out and reject selection `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-197 advanced params section collapses by default and expands with three 

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::advanced params section collapses by default and expands with three `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-198 dragging a slider pushes params to the controller and marks the 

- 优先级：P1
- 前置条件：目标 Widget 可独立 pump；必要时包 ProviderScope
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_draft_widgets_test.dart::dragging a slider pushes params to the controller and marks the `（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-199 rectangle walk converges to the walked outline

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::rectangle walk converges to the walked outline`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-200 L-shape keeps the concave corner

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::L-shape keeps the concave corner`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-201 reversed walk direction yields equivalent envelope

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::reversed walk direction yields equivalent envelope`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-202 separated clusters keep the largest inner face

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::separated clusters keep the largest inner face`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-203 collinear points are rejected as degenerate

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::collinear points are rejected as degenerate`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-204 too few points fail with tooFewPoints

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::too few points fail with tooFewPoints`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-205 stationary duplicate cluster is merged away

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::stationary duplicate cluster is merged away`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-206 noisy dense circle respects the vertex cap

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::noisy dense circle respects the vertex cap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-207 animal-track params keep 30m accuracy points dropped by defaults

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::animal-track params keep 30m accuracy points dropped by defaults`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-208 animal-track params report roaming trim count and trimmed points

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::animal-track params report roaming trim count and trimmed points`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-209 explicit gpxDefault params are equivalent to the default call

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/features/fence/track_to_envelope_converter_test.dart::explicit gpxDefault params are equivalent to the default call`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-330 coordinatesToLatLngPoints maps lng lat pairs to LatLng

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_dto_test.dart::coordinatesToLatLngPoints maps lng lat pairs to LatLng`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-331 livestockCountsByFenceId aggregates fenceId

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_dto_test.dart::livestockCountsByFenceId aggregates fenceId`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-332 fenceItemFromJson builds FenceItem from API map

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_dto_test.dart::fenceItemFromJson builds FenceItem from API map`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-333 fenceItemFromJson maps the shape key to the FenceType enum

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_dto_test.dart::fenceItemFromJson maps the shape key to the FenceType enum`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-334 fenceItemFromJson prefers the API area and falls back to vertices

- 优先级：P1
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_dto_test.dart::fenceItemFromJson prefers the API area and falls back to vertices`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-335 maps a square ring with 12% margins

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：FenceSandboxGeometry.mapperFor
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::maps a square ring with 12% margins`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-336 clamps extreme flat shapes to the 20% floor

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::clamps extreme flat shapes to the 20% floor`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-337 includes out-of-ring dots in the bounds

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::includes out-of-ring dots in the bounds`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-338 returns null for empty rings

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::returns null for empty rings`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-339 safe dots stay fully opaque

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：FenceSandboxGeometry.pulseOpacity
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::safe dots stay fully opaque`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-340 watch and alert dip to the 0.30 floor

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::watch and alert dip to the 0.30 floor`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-341 alert phase is continuous across the master wrap

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::alert phase is continuous across the master wrap`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-342 on-length totals perimeter * on/(on+off) for a closed square

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：FenceSandboxGeometry.dashedRingPath
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::on-length totals perimeter * on/(on+off) for a closed square`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-343 long dashes cross vertices as single contours

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::long dashes cross vertices as single contours`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-344 returns empty path for fewer than two points

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::returns empty path for fewer than two points`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-345 rotated polygons keep vertex-crossing dashes connected

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::rotated polygons keep vertex-crossing dashes connected`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

### TC-RCH-346 repaints on progress, mode, color or grid change

- 优先级：P2
- 前置条件：单元级，无需外部依赖（mock 由 setUp 注入）
- 所属分组：FenceSandboxPainter.shouldRepaint
- 步骤：运行来源测试 `Mobile/mobile_app/test/fence_sandbox_painter_test.dart::repaints on progress, mode, color or grid change`（脚本初稿：以单测作为可执行步骤载体；人工校对时改写为业务步骤）
- 预期结果：测试断言全部通过；失败即用例不通过
- 对应 REQ：REQ-RCH-003、REQ-RCH-004、REQ-RCH-005、REQ-RCH-006

