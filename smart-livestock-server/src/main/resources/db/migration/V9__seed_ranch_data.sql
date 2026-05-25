-- ============================================================
-- V9: Seed Ranch data — fences, livestock, alerts (demo tenant)
-- References: tenant_id=1, farm_id=1 (from V4)
-- ============================================================

-- 1. Fences (4 zones from mock seed data)
-- vertices stored as JSONB array of [lng, lat] pairs (GeoJSON-like order)
INSERT INTO fences (id, farm_id, name, vertices, status) VALUES
    (1, 1, '放牧A区',
     '[[112.94,28.234],[112.944,28.234],[112.944,28.2305],[112.94,28.2305]]'::jsonb,
     'ACTIVE'),
    (2, 1, '放牧B区',
     '[[112.932,28.2275],[112.936,28.2275],[112.936,28.224],[112.932,28.224]]'::jsonb,
     'ACTIVE'),
    (3, 1, '夜间休息区',
     '[[112.938,28.2295],[112.94,28.2295],[112.94,28.228],[112.938,28.228]]'::jsonb,
     'ACTIVE'),
    (4, 1, '隔离区',
     '[[112.94,28.2255],[112.941,28.2255],[112.941,28.2248],[112.94,28.2248]]'::jsonb,
     'ACTIVE');

-- 2. Livestock (50 head, distributed across 4 fences)
-- fence 1 (放牧A区): 25 head, fence 2 (放牧B区): 18 head, fence 3 (休息区): 4 head, fence 4 (隔离区): 3 head
-- Breeds: 西门塔尔牛 (20), 安格斯牛 (15), 利木赞牛 (15)
-- Positions randomly distributed within each fence boundary

INSERT INTO livestock (farm_id, livestock_code, breed, health_status, last_latitude, last_longitude, last_position_at) VALUES
-- 放牧A区 (fence 1): 25 head, 西门塔尔牛 first 20, then 安格斯牛 next 5
(1, 'SL-2024-001', '西门塔尔牛', 'HEALTHY', 28.2312, 112.9412, '2026-04-08 14:00:00'),
(1, 'SL-2024-002', '西门塔尔牛', 'HEALTHY', 28.2325, 112.9425, '2026-04-08 14:00:00'),
(1, 'SL-2024-003', '西门塔尔牛', 'WARNING', 28.2333, 112.9433, '2026-04-08 14:00:00'),
(1, 'SL-2024-004', '西门塔尔牛', 'HEALTHY', 28.2318, 112.9418, '2026-04-08 14:00:00'),
(1, 'SL-2024-005', '西门塔尔牛', 'HEALTHY', 28.2337, 112.9403, '2026-04-08 14:00:00'),
(1, 'SL-2024-006', '西门塔尔牛', 'HEALTHY', 28.2321, 112.9437, '2026-04-08 14:00:00'),
(1, 'SL-2024-007', '西门塔尔牛', 'HEALTHY', 28.2308, 112.9415, '2026-04-08 14:00:00'),
(1, 'SL-2024-008', '西门塔尔牛', 'HEALTHY', 28.2332, 112.9421, '2026-04-08 14:00:00'),
(1, 'SL-2024-009', '西门塔尔牛', 'HEALTHY', 28.2316, 112.9406, '2026-04-08 14:00:00'),
(1, 'SL-2024-010', '西门塔尔牛', 'HEALTHY', 28.2328, 112.9431, '2026-04-08 14:00:00'),
(1, 'SL-2024-011', '西门塔尔牛', 'HEALTHY', 28.2314, 112.9428, '2026-04-08 14:00:00'),
(1, 'SL-2024-012', '西门塔尔牛', 'HEALTHY', 28.2335, 112.9410, '2026-04-08 14:00:00'),
(1, 'SL-2024-013', '西门塔尔牛', 'HEALTHY', 28.2307, 112.9435, '2026-04-08 14:00:00'),
(1, 'SL-2024-014', '西门塔尔牛', 'HEALTHY', 28.2323, 112.9408, '2026-04-08 14:00:00'),
(1, 'SL-2024-015', '西门塔尔牛', 'HEALTHY', 28.2338, 112.9422, '2026-04-08 14:00:00'),
(1, 'SL-2024-016', '西门塔尔牛', 'HEALTHY', 28.2311, 112.9413, '2026-04-08 14:00:00'),
(1, 'SL-2024-017', '西门塔尔牛', 'CRITICAL', 28.2327, 112.9430, '2026-04-08 14:00:00'),
(1, 'SL-2024-018', '西门塔尔牛', 'HEALTHY', 28.2330, 112.9405, '2026-04-08 14:00:00'),
(1, 'SL-2024-019', '西门塔尔牛', 'HEALTHY', 28.2319, 112.9420, '2026-04-08 14:00:00'),
(1, 'SL-2024-020', '西门塔尔牛', 'HEALTHY', 28.2322, 112.9417, '2026-04-08 14:00:00'),
(1, 'SL-2024-021', '安格斯牛', 'HEALTHY', 28.2336, 112.9423, '2026-04-08 14:00:00'),
(1, 'SL-2024-022', '安格斯牛', 'HEALTHY', 28.2309, 112.9411, '2026-04-08 14:00:00'),
(1, 'SL-2024-023', '安格斯牛', 'HEALTHY', 28.2324, 112.9432, '2026-04-08 14:00:00'),
(1, 'SL-2024-024', '安格斯牛', 'HEALTHY', 28.2315, 112.9409, '2026-04-08 14:00:00'),
(1, 'SL-2024-025', '安格斯牛', 'HEALTHY', 28.2331, 112.9416, '2026-04-08 14:00:00'),
-- 放牧B区 (fence 2): 18 head, 安格斯牛 next 10, then 利木赞牛 next 8
(1, 'SL-2024-026', '安格斯牛', 'HEALTHY', 28.2261, 112.9331, '2026-04-08 14:00:00'),
(1, 'SL-2024-027', '安格斯牛', 'HEALTHY', 28.2248, 112.9345, '2026-04-08 14:00:00'),
(1, 'SL-2024-028', '安格斯牛', 'HEALTHY', 28.2259, 112.9352, '2026-04-08 14:00:00'),
(1, 'SL-2024-029', '安格斯牛', 'HEALTHY', 28.2268, 112.9328, '2026-04-08 14:00:00'),
(1, 'SL-2024-030', '安格斯牛', 'HEALTHY', 28.2253, 112.9337, '2026-04-08 14:00:00'),
(1, 'SL-2024-031', '安格斯牛', 'HEALTHY', 28.2245, 112.9355, '2026-04-08 14:00:00'),
(1, 'SL-2024-032', '安格斯牛', 'HEALTHY', 28.2271, 112.9341, '2026-04-08 14:00:00'),
(1, 'SL-2024-033', '安格斯牛', 'HEALTHY', 28.2256, 112.9325, '2026-04-08 14:00:00'),
(1, 'SL-2024-034', '安格斯牛', 'HEALTHY', 28.2265, 112.9358, '2026-04-08 14:00:00'),
(1, 'SL-2024-035', '安格斯牛', 'HEALTHY', 28.2243, 112.9334, '2026-04-08 14:00:00'),
(1, 'SL-2024-036', '利木赞牛', 'HEALTHY', 28.2262, 112.9348, '2026-04-08 14:00:00'),
(1, 'SL-2024-037', '利木赞牛', 'HEALTHY', 28.2251, 112.9327, '2026-04-08 14:00:00'),
(1, 'SL-2024-038', '利木赞牛', 'HEALTHY', 28.2270, 112.9350, '2026-04-08 14:00:00'),
(1, 'SL-2024-039', '利木赞牛', 'HEALTHY', 28.2249, 112.9339, '2026-04-08 14:00:00'),
(1, 'SL-2024-040', '利木赞牛', 'HEALTHY', 28.2264, 112.9323, '2026-04-08 14:00:00'),
(1, 'SL-2024-041', '利木赞牛', 'HEALTHY', 28.2257, 112.9356, '2026-04-08 14:00:00'),
(1, 'SL-2024-042', '利木赞牛', 'HEALTHY', 28.2267, 112.9335, '2026-04-08 14:00:00'),
(1, 'SL-2024-043', '利木赞牛', 'HEALTHY', 28.2247, 112.9343, '2026-04-08 14:00:00'),
-- 夜间休息区 (fence 3): 4 head
(1, 'SL-2024-044', '利木赞牛', 'HEALTHY', 28.2288, 112.9391, '2026-04-08 14:00:00'),
(1, 'SL-2024-045', '利木赞牛', 'HEALTHY', 28.2291, 112.9385, '2026-04-08 14:00:00'),
(1, 'SL-2024-046', '利木赞牛', 'HEALTHY', 28.2283, 112.9395, '2026-04-08 14:00:00'),
(1, 'SL-2024-047', '利木赞牛', 'HEALTHY', 28.2293, 112.9388, '2026-04-08 14:00:00'),
-- 隔离区 (fence 4): 3 head
(1, 'SL-2024-048', '西门塔尔牛', 'CRITICAL', 28.2253, 112.9406, '2026-04-08 14:00:00'),
(1, 'SL-2024-049', '西门塔尔牛', 'CRITICAL', 28.2250, 112.9403, '2026-04-08 14:00:00'),
(1, 'SL-2024-050', '西门塔尔牛', 'HEALTHY', 28.2251, 112.9408, '2026-04-08 14:00:00');

-- 3. Alerts (18 alerts from mock seed data)
-- Types mapped: geofence→FENCE_BREACH, fever→TEMPERATURE_ABNORMAL, behavior→BEHAVIOR_ABNORMAL,
--               offline/lowbattery→BEHAVIOR_ABNORMAL (closest match within CHECK constraint)
-- Severities mapped: critical→CRITICAL, warning→WARNING, info→INFO
-- Statuses mapped: pending→PENDING, acknowledged→ACKNOWLEDGED, handled→HANDLED, archived→ARCHIVED

INSERT INTO alerts (farm_id, livestock_id, fence_id, type, status, severity, message, created_at) VALUES
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-003'), 1, 'FENCE_BREACH', 'PENDING', 'CRITICAL', '越界 · SL-2024-003', '2026-04-08 14:23:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-048'), NULL, 'TEMPERATURE_ABNORMAL', 'ACKNOWLEDGED', 'CRITICAL', '体温异常 · SL-2024-048', '2026-04-08 11:05:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-017'), 1, 'FENCE_BREACH', 'HANDLED', 'CRITICAL', '越界 · SL-2024-017', '2026-04-07 16:30:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-049'), NULL, 'TEMPERATURE_ABNORMAL', 'HANDLED', 'CRITICAL', '体温异常 · SL-2024-049', '2026-04-07 09:15:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-043'), NULL, 'BEHAVIOR_ABNORMAL', 'PENDING', 'WARNING', '设备离线 · SL-2024-043', '2026-04-08 13:40:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-045'), NULL, 'BEHAVIOR_ABNORMAL', 'PENDING', 'WARNING', '低电量 · SL-2024-045', '2026-04-08 12:20:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-044'), NULL, 'BEHAVIOR_ABNORMAL', 'ACKNOWLEDGED', 'WARNING', '设备离线 · SL-2024-044', '2026-04-08 08:50:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-046'), NULL, 'BEHAVIOR_ABNORMAL', 'HANDLED', 'WARNING', '低电量 · SL-2024-046', '2026-04-07 15:10:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-042'), NULL, 'BEHAVIOR_ABNORMAL', 'HANDLED', 'WARNING', '设备离线 · SL-2024-042', '2026-04-07 10:25:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-047'), NULL, 'BEHAVIOR_ABNORMAL', 'PENDING', 'INFO', '行为异常 · SL-2024-047', '2026-04-08 09:30:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-012'), 1, 'FENCE_BREACH', 'HANDLED', 'INFO', '围栏接近 · SL-2024-012', '2026-04-07 14:50:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-050'), NULL, 'BEHAVIOR_ABNORMAL', 'HANDLED', 'INFO', '行为异常 · SL-2024-050', '2026-04-07 11:35:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-008'), 1, 'FENCE_BREACH', 'HANDLED', 'INFO', '围栏接近 · SL-2024-008', '2026-04-06 16:45:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-030'), NULL, 'BEHAVIOR_ABNORMAL', 'ARCHIVED', 'INFO', '行为异常 · SL-2024-030', '2026-04-06 10:00:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-005'), 1, 'FENCE_BREACH', 'ARCHIVED', 'CRITICAL', '越界 · SL-2024-005', '2026-04-05 09:10:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-041'), NULL, 'BEHAVIOR_ABNORMAL', 'ARCHIVED', 'WARNING', '设备离线 · SL-2024-041', '2026-04-04 14:30:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-047'), NULL, 'BEHAVIOR_ABNORMAL', 'ARCHIVED', 'WARNING', '低电量 · SL-2024-047', '2026-04-03 11:20:00'),
    (1, (SELECT id FROM livestock WHERE livestock_code='SL-2024-050'), NULL, 'TEMPERATURE_ABNORMAL', 'ARCHIVED', 'CRITICAL', '体温异常 · SL-2024-050', '2026-04-02 08:00:00');

-- Reset sequences after explicit ID inserts
SELECT setval('fences_id_seq', (SELECT COALESCE(MAX(id), 1) FROM fences));
