-- ============================================================
-- V29: Update seed data — Chinese → English for i18n
-- This migration applies the name/display text translations
-- that were originally edited directly into V4/V9/V16/V17/V21/V23/V24/V25.
-- ============================================================

-- ── Users: name ──────────────────────────────────────────────
UPDATE users SET name = 'Platform Admin'  WHERE phone = '13800000000' AND role = 'PLATFORM_ADMIN';
UPDATE users SET name = 'Rancher Zhang'   WHERE phone = '13800138000' AND role = 'OWNER';
UPDATE users SET name = 'B2B Admin'       WHERE phone = '13900139000' AND role = 'B2B_ADMIN';
UPDATE users SET name = 'Worker Li'       WHERE phone = '13800138001' AND role = 'WORKER';

-- ── Tenants: name, contact_name ──────────────────────────────
UPDATE tenants SET name = 'Demo Ranch', contact_name = 'Rancher Zhang' WHERE id = 1;

-- ── Farms: name ──────────────────────────────────────────────
UPDATE farms SET name = 'Main Ranch'       WHERE id = 1 AND tenant_id = 1;
UPDATE farms SET name = 'South Hill Ranch' WHERE name = '南山分场' AND tenant_id = 1;

-- ── Fences: name (Farm 1) ────────────────────────────────────
UPDATE fences SET name = 'Grazing Zone A'   WHERE farm_id = 1 AND name = '放牧A区';
UPDATE fences SET name = 'Grazing Zone B'   WHERE farm_id = 1 AND name = '放牧B区';
UPDATE fences SET name = 'Night Rest Zone'  WHERE farm_id = 1 AND name = '夜间休息区';
UPDATE fences SET name = 'Isolation Zone'   WHERE farm_id = 1 AND name = '隔离区';

-- ── Fences: name (Farm 2) ────────────────────────────────────
UPDATE fences SET name = 'Grazing Zone C' WHERE name = '放牧C区';
UPDATE fences SET name = 'Watering Zone'  WHERE name = '饮水区';

-- ── Livestock: breed ─────────────────────────────────────────
UPDATE livestock SET breed = 'Simmental'  WHERE breed = '西门塔尔牛';
UPDATE livestock SET breed = 'Angus'      WHERE breed = '安格斯牛';
UPDATE livestock SET breed = 'Limousin'   WHERE breed = '利木赞牛';

-- ── Estrus scores: advice ────────────────────────────────────
UPDATE estrus_scores SET advice = 'High estrus score. Breeding recommended within 12 hours.'
  WHERE advice = '发情评分较高，建议 12 小时内安排配种';
UPDATE estrus_scores SET advice = 'Moderately high estrus score. Continue monitoring and prepare for breeding.'
  WHERE advice = '发情评分中等偏高，建议持续观察并准备配种';

-- ── API Keys: key_name ──────────────────────────────────────
UPDATE api_keys SET key_name = 'Test Developer Key' WHERE key_name = '测试开发者 Key';
