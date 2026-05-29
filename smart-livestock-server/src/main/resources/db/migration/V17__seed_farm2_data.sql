-- ============================================================
-- V17: Seed Farm 2 (南山分场) data for multi-farm journey testing
-- Center: (28.20, 112.90), 10 livestock, 2 fences, 5 alerts
-- ============================================================

-- 1. Fences for Farm 2
INSERT INTO fences (farm_id, name, vertices, status)
SELECT f.id, '放牧C区',
    '[[112.898,28.202],[112.902,28.202],[112.902,28.199],[112.898,28.199]]'::jsonb,
    'ACTIVE'
FROM farms f WHERE f.name = '南山分场' AND f.tenant_id = 1;

INSERT INTO fences (farm_id, name, vertices, status)
SELECT f.id, '饮水区',
    '[[112.901,28.198],[112.903,28.198],[112.903,28.1965],[112.901,28.1965]]'::jsonb,
    'ACTIVE'
FROM farms f WHERE f.name = '南山分场' AND f.tenant_id = 1;

-- 2. Livestock for Farm 2 (10 head, mixed breeds)
INSERT INTO livestock (farm_id, livestock_code, breed, health_status, last_latitude, last_longitude, last_position_at)
SELECT f.id, code, breed, status, lat, lng, '2026-04-08 14:00:00'
FROM farms f
CROSS JOIN (VALUES
    ('SL-2024-051', '西门塔尔牛', 'HEALTHY',  28.2005, 112.8995),
    ('SL-2024-052', '西门塔尔牛', 'HEALTHY',  28.2012, 112.9008),
    ('SL-2024-053', '西门塔尔牛', 'HEALTHY',  28.1998, 112.9012),
    ('SL-2024-054', '安格斯牛',   'WARNING',  28.2008, 112.8988),
    ('SL-2024-055', '安格斯牛',   'HEALTHY',  28.2015, 112.9002),
    ('SL-2024-056', '安格斯牛',   'HEALTHY',  28.1992, 112.9015),
    ('SL-2024-057', '利木赞牛',   'HEALTHY',  28.2003, 112.8998),
    ('SL-2024-058', '利木赞牛',   'CRITICAL', 28.2010, 112.9005),
    ('SL-2024-059', '利木赞牛',   'HEALTHY',  28.1995, 112.9010),
    ('SL-2024-060', '利木赞牛',   'HEALTHY',  28.2008, 112.9000)
) AS t(code, breed, status, lat, lng)
WHERE f.name = '南山分场' AND f.tenant_id = 1;

-- 3. Alerts for Farm 2 (5 alerts, covering multiple statuses/types)
-- PENDING: 2, ACKNOWLEDGED: 1, HANDLED: 1, ARCHIVED: 1
INSERT INTO alerts (farm_id, livestock_id, fence_id, type, status, severity, message, created_at)
SELECT f.id, ls.id, NULL, 'FENCE_BREACH', 'PENDING', 'WARNING',
    '越界 · SL-2024-054', '2026-04-08 15:10:00'
FROM farms f, livestock ls
WHERE f.name = '南山分场' AND f.tenant_id = 1
  AND ls.livestock_code = 'SL-2024-054' AND ls.farm_id = f.id;

INSERT INTO alerts (farm_id, livestock_id, fence_id, type, status, severity, message, created_at)
SELECT f.id, ls.id, NULL, 'TEMPERATURE_ABNORMAL', 'PENDING', 'CRITICAL',
    '体温异常 · SL-2024-058', '2026-04-08 10:30:00'
FROM farms f, livestock ls
WHERE f.name = '南山分场' AND f.tenant_id = 1
  AND ls.livestock_code = 'SL-2024-058' AND ls.farm_id = f.id;

INSERT INTO alerts (farm_id, livestock_id, fence_id, type, status, severity, message, created_at)
SELECT f.id, ls.id, NULL, 'BEHAVIOR_ABNORMAL', 'ACKNOWLEDGED', 'WARNING',
    '设备离线 · SL-2024-051', '2026-04-08 09:20:00'
FROM farms f, livestock ls
WHERE f.name = '南山分场' AND f.tenant_id = 1
  AND ls.livestock_code = 'SL-2024-051' AND ls.farm_id = f.id;

INSERT INTO alerts (farm_id, livestock_id, fence_id, type, status, severity, message, created_at)
SELECT f.id, ls.id, NULL, 'BEHAVIOR_ABNORMAL', 'HANDLED', 'INFO',
    '行为异常 · SL-2024-055', '2026-04-07 14:00:00'
FROM farms f, livestock ls
WHERE f.name = '南山分场' AND f.tenant_id = 1
  AND ls.livestock_code = 'SL-2024-055' AND ls.farm_id = f.id;

INSERT INTO alerts (farm_id, livestock_id, fence_id, type, status, severity, message, created_at)
SELECT f.id, ls.id, NULL, 'FENCE_BREACH', 'ARCHIVED', 'INFO',
    '围栏接近 · SL-2024-057', '2026-04-06 11:45:00'
FROM farms f, livestock ls
WHERE f.name = '南山分场' AND f.tenant_id = 1
  AND ls.livestock_code = 'SL-2024-057' AND ls.farm_id = f.id;
