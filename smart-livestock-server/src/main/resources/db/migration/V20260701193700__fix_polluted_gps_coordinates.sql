-- V41: 修复 datagen 随机游走从 (0,0) 开始污染的 GPS 坐标
-- 根因：SynthesisState.create() 未初始化 currentLat/currentLng，默认 0.0
-- 已在代码中修复，此迁移恢复被覆盖的种子数据坐标

-- V9 种子数据恢复（SL-2024-001 ~ SL-2024-050, farm_id=1）
UPDATE livestock SET last_latitude = 28.2312, last_longitude = 112.9412 WHERE livestock_code = 'SL-2024-001';
UPDATE livestock SET last_latitude = 28.2325, last_longitude = 112.9425 WHERE livestock_code = 'SL-2024-002';
UPDATE livestock SET last_latitude = 28.2333, last_longitude = 112.9433 WHERE livestock_code = 'SL-2024-003';
UPDATE livestock SET last_latitude = 28.2318, last_longitude = 112.9418 WHERE livestock_code = 'SL-2024-004';
UPDATE livestock SET last_latitude = 28.2337, last_longitude = 112.9403 WHERE livestock_code = 'SL-2024-005';
UPDATE livestock SET last_latitude = 28.2321, last_longitude = 112.9437 WHERE livestock_code = 'SL-2024-006';
UPDATE livestock SET last_latitude = 28.2308, last_longitude = 112.9415 WHERE livestock_code = 'SL-2024-007';
UPDATE livestock SET last_latitude = 28.2332, last_longitude = 112.9421 WHERE livestock_code = 'SL-2024-008';
UPDATE livestock SET last_latitude = 28.2316, last_longitude = 112.9406 WHERE livestock_code = 'SL-2024-009';
UPDATE livestock SET last_latitude = 28.2328, last_longitude = 112.9431 WHERE livestock_code = 'SL-2024-010';
UPDATE livestock SET last_latitude = 28.2314, last_longitude = 112.9428 WHERE livestock_code = 'SL-2024-011';
UPDATE livestock SET last_latitude = 28.2335, last_longitude = 112.9410 WHERE livestock_code = 'SL-2024-012';
UPDATE livestock SET last_latitude = 28.2307, last_longitude = 112.9435 WHERE livestock_code = 'SL-2024-013';
UPDATE livestock SET last_latitude = 28.2323, last_longitude = 112.9408 WHERE livestock_code = 'SL-2024-014';
UPDATE livestock SET last_latitude = 28.2338, last_longitude = 112.9422 WHERE livestock_code = 'SL-2024-015';
UPDATE livestock SET last_latitude = 28.2311, last_longitude = 112.9413 WHERE livestock_code = 'SL-2024-016';
UPDATE livestock SET last_latitude = 28.2327, last_longitude = 112.9430 WHERE livestock_code = 'SL-2024-017';
UPDATE livestock SET last_latitude = 28.2330, last_longitude = 112.9405 WHERE livestock_code = 'SL-2024-018';
UPDATE livestock SET last_latitude = 28.2319, last_longitude = 112.9420 WHERE livestock_code = 'SL-2024-019';
UPDATE livestock SET last_latitude = 28.2322, last_longitude = 112.9417 WHERE livestock_code = 'SL-2024-020';
UPDATE livestock SET last_latitude = 28.2336, last_longitude = 112.9423 WHERE livestock_code = 'SL-2024-021';
UPDATE livestock SET last_latitude = 28.2309, last_longitude = 112.9411 WHERE livestock_code = 'SL-2024-022';
UPDATE livestock SET last_latitude = 28.2324, last_longitude = 112.9432 WHERE livestock_code = 'SL-2024-023';
UPDATE livestock SET last_latitude = 28.2315, last_longitude = 112.9409 WHERE livestock_code = 'SL-2024-024';
UPDATE livestock SET last_latitude = 28.2331, last_longitude = 112.9416 WHERE livestock_code = 'SL-2024-025';
UPDATE livestock SET last_latitude = 28.2261, last_longitude = 112.9331 WHERE livestock_code = 'SL-2024-026';
UPDATE livestock SET last_latitude = 28.2248, last_longitude = 112.9345 WHERE livestock_code = 'SL-2024-027';
UPDATE livestock SET last_latitude = 28.2259, last_longitude = 112.9352 WHERE livestock_code = 'SL-2024-028';
UPDATE livestock SET last_latitude = 28.2268, last_longitude = 112.9328 WHERE livestock_code = 'SL-2024-029';
UPDATE livestock SET last_latitude = 28.2253, last_longitude = 112.9337 WHERE livestock_code = 'SL-2024-030';
UPDATE livestock SET last_latitude = 28.2245, last_longitude = 112.9355 WHERE livestock_code = 'SL-2024-031';
UPDATE livestock SET last_latitude = 28.2271, last_longitude = 112.9341 WHERE livestock_code = 'SL-2024-032';
UPDATE livestock SET last_latitude = 28.2256, last_longitude = 112.9325 WHERE livestock_code = 'SL-2024-033';
UPDATE livestock SET last_latitude = 28.2265, last_longitude = 112.9358 WHERE livestock_code = 'SL-2024-034';
UPDATE livestock SET last_latitude = 28.2243, last_longitude = 112.9334 WHERE livestock_code = 'SL-2024-035';
UPDATE livestock SET last_latitude = 28.2262, last_longitude = 112.9348 WHERE livestock_code = 'SL-2024-036';
UPDATE livestock SET last_latitude = 28.2251, last_longitude = 112.9327 WHERE livestock_code = 'SL-2024-037';
UPDATE livestock SET last_latitude = 28.2270, last_longitude = 112.9350 WHERE livestock_code = 'SL-2024-038';
UPDATE livestock SET last_latitude = 28.2249, last_longitude = 112.9339 WHERE livestock_code = 'SL-2024-039';
UPDATE livestock SET last_latitude = 28.2264, last_longitude = 112.9323 WHERE livestock_code = 'SL-2024-040';
UPDATE livestock SET last_latitude = 28.2257, last_longitude = 112.9356 WHERE livestock_code = 'SL-2024-041';
UPDATE livestock SET last_latitude = 28.2267, last_longitude = 112.9335 WHERE livestock_code = 'SL-2024-042';
UPDATE livestock SET last_latitude = 28.2247, last_longitude = 112.9343 WHERE livestock_code = 'SL-2024-043';
UPDATE livestock SET last_latitude = 28.2288, last_longitude = 112.9391 WHERE livestock_code = 'SL-2024-044';
UPDATE livestock SET last_latitude = 28.2291, last_longitude = 112.9385 WHERE livestock_code = 'SL-2024-045';
UPDATE livestock SET last_latitude = 28.2283, last_longitude = 112.9395 WHERE livestock_code = 'SL-2024-046';
UPDATE livestock SET last_latitude = 28.2293, last_longitude = 112.9388 WHERE livestock_code = 'SL-2024-047';
UPDATE livestock SET last_latitude = 28.2253, last_longitude = 112.9406 WHERE livestock_code = 'SL-2024-048';
UPDATE livestock SET last_latitude = 28.2250, last_longitude = 112.9403 WHERE livestock_code = 'SL-2024-049';
UPDATE livestock SET last_latitude = 28.2251, last_longitude = 112.9408 WHERE livestock_code = 'SL-2024-050';

-- V17 种子数据恢复（farm2, SL-2024-051 ~ SL-2024-060）
UPDATE livestock SET last_latitude = 28.2005, last_longitude = 112.8995 WHERE livestock_code = 'SL-2024-051';
UPDATE livestock SET last_latitude = 28.2012, last_longitude = 112.9008 WHERE livestock_code = 'SL-2024-052';
UPDATE livestock SET last_latitude = 28.1998, last_longitude = 112.9012 WHERE livestock_code = 'SL-2024-053';
UPDATE livestock SET last_latitude = 28.2008, last_longitude = 112.8988 WHERE livestock_code = 'SL-2024-054';
UPDATE livestock SET last_latitude = 28.2015, last_longitude = 112.9002 WHERE livestock_code = 'SL-2024-055';
UPDATE livestock SET last_latitude = 28.1992, last_longitude = 112.9015 WHERE livestock_code = 'SL-2024-056';
UPDATE livestock SET last_latitude = 28.2003, last_longitude = 112.8998 WHERE livestock_code = 'SL-2024-057';
UPDATE livestock SET last_latitude = 28.2008, last_longitude = 112.9008 WHERE livestock_code = 'SL-2024-058';
UPDATE livestock SET last_latitude = 28.1995, last_longitude = 112.8990 WHERE livestock_code = 'SL-2024-059';
UPDATE livestock SET last_latitude = 28.2008, last_longitude = 112.9012 WHERE livestock_code = 'SL-2024-060';

-- 通过 API 创建的牲畜（TEST-COW-001 / DEV-COW-001）不恢复（没有原始种子坐标）
