-- ============================================================
-- V10: Seed IoT data — devices, device_licenses, installations, gps_logs
-- References: tenant_id=1 (demo tenant from V4), livestock from V9
-- ============================================================

-- 1. Devices (100 total: 50 GPS trackers, 30 rumen capsules, 20 accelerometers)
-- Type mapping: gps→TRACKER, rumenCapsule→CAPSULE, accelerometer→ACCELEROMETER
-- Status mapping: online→ACTIVE, offline→OFFLINE, lowBattery→ACTIVE (still online but low battery)

-- GPS Trackers (50: 42 online, 4 offline, 4 low-battery)
INSERT INTO devices (id, tenant_id, device_code, device_type, status, battery_level, last_online_at) VALUES
(1,  1, 'DEV-GPS-001', 'TRACKER', 'ACTIVE', 63, '2026-04-08 13:58:00'),
(2,  1, 'DEV-GPS-002', 'TRACKER', 'ACTIVE', 66, '2026-04-08 13:55:00'),
(3,  1, 'DEV-GPS-003', 'TRACKER', 'ACTIVE', 69, '2026-04-08 13:52:00'),
(4,  1, 'DEV-GPS-004', 'TRACKER', 'ACTIVE', 72, '2026-04-08 13:49:00'),
(5,  1, 'DEV-GPS-005', 'TRACKER', 'ACTIVE', 75, '2026-04-08 13:46:00'),
(6,  1, 'DEV-GPS-006', 'TRACKER', 'ACTIVE', 78, '2026-04-08 13:43:00'),
(7,  1, 'DEV-GPS-007', 'TRACKER', 'ACTIVE', 81, '2026-04-08 13:40:00'),
(8,  1, 'DEV-GPS-008', 'TRACKER', 'ACTIVE', 84, '2026-04-08 13:37:00'),
(9,  1, 'DEV-GPS-009', 'TRACKER', 'ACTIVE', 87, '2026-04-08 13:34:00'),
(10, 1, 'DEV-GPS-010', 'TRACKER', 'ACTIVE', 90, '2026-04-08 13:31:00'),
(11, 1, 'DEV-GPS-011', 'TRACKER', 'ACTIVE', 63, '2026-04-08 13:28:00'),
(12, 1, 'DEV-GPS-012', 'TRACKER', 'ACTIVE', 66, '2026-04-08 13:25:00'),
(13, 1, 'DEV-GPS-013', 'TRACKER', 'ACTIVE', 69, '2026-04-08 13:22:00'),
(14, 1, 'DEV-GPS-014', 'TRACKER', 'ACTIVE', 72, '2026-04-08 13:19:00'),
(15, 1, 'DEV-GPS-015', 'TRACKER', 'ACTIVE', 75, '2026-04-08 13:16:00'),
(16, 1, 'DEV-GPS-016', 'TRACKER', 'ACTIVE', 78, '2026-04-08 13:13:00'),
(17, 1, 'DEV-GPS-017', 'TRACKER', 'ACTIVE', 81, '2026-04-08 13:10:00'),
(18, 1, 'DEV-GPS-018', 'TRACKER', 'ACTIVE', 84, '2026-04-08 13:07:00'),
(19, 1, 'DEV-GPS-019', 'TRACKER', 'ACTIVE', 87, '2026-04-08 13:04:00'),
(20, 1, 'DEV-GPS-020', 'TRACKER', 'ACTIVE', 90, '2026-04-08 13:01:00'),
(21, 1, 'DEV-GPS-021', 'TRACKER', 'ACTIVE', 63, '2026-04-08 12:58:00'),
(22, 1, 'DEV-GPS-022', 'TRACKER', 'ACTIVE', 66, '2026-04-08 12:55:00'),
(23, 1, 'DEV-GPS-023', 'TRACKER', 'ACTIVE', 69, '2026-04-08 12:52:00'),
(24, 1, 'DEV-GPS-024', 'TRACKER', 'ACTIVE', 72, '2026-04-08 12:49:00'),
(25, 1, 'DEV-GPS-025', 'TRACKER', 'ACTIVE', 75, '2026-04-08 12:46:00'),
(26, 1, 'DEV-GPS-026', 'TRACKER', 'ACTIVE', 78, '2026-04-08 12:43:00'),
(27, 1, 'DEV-GPS-027', 'TRACKER', 'ACTIVE', 81, '2026-04-08 12:40:00'),
(28, 1, 'DEV-GPS-028', 'TRACKER', 'ACTIVE', 84, '2026-04-08 12:37:00'),
(29, 1, 'DEV-GPS-029', 'TRACKER', 'ACTIVE', 87, '2026-04-08 12:34:00'),
(30, 1, 'DEV-GPS-030', 'TRACKER', 'ACTIVE', 90, '2026-04-08 12:31:00'),
(31, 1, 'DEV-GPS-031', 'TRACKER', 'ACTIVE', 63, '2026-04-08 12:28:00'),
(32, 1, 'DEV-GPS-032', 'TRACKER', 'ACTIVE', 66, '2026-04-08 12:25:00'),
(33, 1, 'DEV-GPS-033', 'TRACKER', 'ACTIVE', 69, '2026-04-08 12:22:00'),
(34, 1, 'DEV-GPS-034', 'TRACKER', 'ACTIVE', 72, '2026-04-08 12:19:00'),
(35, 1, 'DEV-GPS-035', 'TRACKER', 'ACTIVE', 75, '2026-04-08 12:16:00'),
(36, 1, 'DEV-GPS-036', 'TRACKER', 'ACTIVE', 78, '2026-04-08 12:13:00'),
(37, 1, 'DEV-GPS-037', 'TRACKER', 'ACTIVE', 81, '2026-04-08 12:10:00'),
(38, 1, 'DEV-GPS-038', 'TRACKER', 'ACTIVE', 84, '2026-04-08 12:07:00'),
(39, 1, 'DEV-GPS-039', 'TRACKER', 'ACTIVE', 87, '2026-04-08 12:04:00'),
(40, 1, 'DEV-GPS-040', 'TRACKER', 'ACTIVE', 90, '2026-04-08 12:01:00'),
(41, 1, 'DEV-GPS-041', 'TRACKER', 'ACTIVE', 63, '2026-04-08 11:58:00'),
(42, 1, 'DEV-GPS-042', 'TRACKER', 'ACTIVE', 66, '2026-04-08 11:55:00'),
(43, 1, 'DEV-GPS-043', 'TRACKER', 'OFFLINE', NULL, '2026-04-08 11:00:00'),
(44, 1, 'DEV-GPS-044', 'TRACKER', 'OFFLINE', NULL, '2026-04-08 10:00:00'),
(45, 1, 'DEV-GPS-045', 'TRACKER', 'OFFLINE', NULL, '2026-04-08 09:00:00'),
(46, 1, 'DEV-GPS-046', 'TRACKER', 'OFFLINE', NULL, '2026-04-08 08:00:00'),
(47, 1, 'DEV-GPS-047', 'TRACKER', 'ACTIVE', 8, '2026-04-08 13:00:00'),
(48, 1, 'DEV-GPS-048', 'TRACKER', 'ACTIVE', 12, '2026-04-08 13:00:00'),
(49, 1, 'DEV-GPS-049', 'TRACKER', 'ACTIVE', 7, '2026-04-08 13:00:00'),
(50, 1, 'DEV-GPS-050', 'TRACKER', 'ACTIVE', 14, '2026-04-08 13:00:00');

-- Rumen Capsules (30: 26 online, 2 offline, 2 low-battery)
INSERT INTO devices (id, tenant_id, device_code, device_type, status, battery_level, last_online_at) VALUES
(51,  1, 'DEV-RC-001', 'CAPSULE', 'ACTIVE', 85, '2026-04-08 13:50:00'),
(52,  1, 'DEV-RC-002', 'CAPSULE', 'ACTIVE', 82, '2026-04-08 13:47:00'),
(53,  1, 'DEV-RC-003', 'CAPSULE', 'ACTIVE', 79, '2026-04-08 13:44:00'),
(54,  1, 'DEV-RC-004', 'CAPSULE', 'ACTIVE', 76, '2026-04-08 13:41:00'),
(55,  1, 'DEV-RC-005', 'CAPSULE', 'ACTIVE', 73, '2026-04-08 13:38:00'),
(56,  1, 'DEV-RC-006', 'CAPSULE', 'ACTIVE', 70, '2026-04-08 13:35:00'),
(57,  1, 'DEV-RC-007', 'CAPSULE', 'ACTIVE', 67, '2026-04-08 13:32:00'),
(58,  1, 'DEV-RC-008', 'CAPSULE', 'ACTIVE', 64, '2026-04-08 13:29:00'),
(59,  1, 'DEV-RC-009', 'CAPSULE', 'ACTIVE', 61, '2026-04-08 13:26:00'),
(60,  1, 'DEV-RC-010', 'CAPSULE', 'ACTIVE', 58, '2026-04-08 13:23:00'),
(61,  1, 'DEV-RC-011', 'CAPSULE', 'ACTIVE', 85, '2026-04-08 13:20:00'),
(62,  1, 'DEV-RC-012', 'CAPSULE', 'ACTIVE', 82, '2026-04-08 13:17:00'),
(63,  1, 'DEV-RC-013', 'CAPSULE', 'ACTIVE', 79, '2026-04-08 13:14:00'),
(64,  1, 'DEV-RC-014', 'CAPSULE', 'ACTIVE', 76, '2026-04-08 13:11:00'),
(65,  1, 'DEV-RC-015', 'CAPSULE', 'ACTIVE', 73, '2026-04-08 13:08:00'),
(66,  1, 'DEV-RC-016', 'CAPSULE', 'ACTIVE', 70, '2026-04-08 13:05:00'),
(67,  1, 'DEV-RC-017', 'CAPSULE', 'ACTIVE', 67, '2026-04-08 13:02:00'),
(68,  1, 'DEV-RC-018', 'CAPSULE', 'ACTIVE', 64, '2026-04-08 12:59:00'),
(69,  1, 'DEV-RC-019', 'CAPSULE', 'ACTIVE', 61, '2026-04-08 12:56:00'),
(70,  1, 'DEV-RC-020', 'CAPSULE', 'ACTIVE', 58, '2026-04-08 12:53:00'),
(71,  1, 'DEV-RC-021', 'CAPSULE', 'ACTIVE', 85, '2026-04-08 12:50:00'),
(72,  1, 'DEV-RC-022', 'CAPSULE', 'ACTIVE', 82, '2026-04-08 12:47:00'),
(73,  1, 'DEV-RC-023', 'CAPSULE', 'ACTIVE', 79, '2026-04-08 12:44:00'),
(74,  1, 'DEV-RC-024', 'CAPSULE', 'ACTIVE', 76, '2026-04-08 12:41:00'),
(75,  1, 'DEV-RC-025', 'CAPSULE', 'ACTIVE', 73, '2026-04-08 12:38:00'),
(76,  1, 'DEV-RC-026', 'CAPSULE', 'ACTIVE', 70, '2026-04-08 12:35:00'),
(77,  1, 'DEV-RC-027', 'CAPSULE', 'OFFLINE', NULL, '2026-04-08 10:30:00'),
(78,  1, 'DEV-RC-028', 'CAPSULE', 'OFFLINE', NULL, '2026-04-08 09:30:00'),
(79,  1, 'DEV-RC-029', 'CAPSULE', 'ACTIVE', 9, '2026-04-08 13:00:00'),
(80,  1, 'DEV-RC-030', 'CAPSULE', 'ACTIVE', 11, '2026-04-08 13:00:00');

-- Accelerometers (20: 17 online, 2 offline, 1 low-battery)
INSERT INTO devices (id, tenant_id, device_code, device_type, status, battery_level, last_online_at) VALUES
(81,  1, 'DEV-ACC-001', 'ACCELEROMETER', 'ACTIVE', 88, '2026-04-08 13:45:00'),
(82,  1, 'DEV-ACC-002', 'ACCELEROMETER', 'ACTIVE', 85, '2026-04-08 13:42:00'),
(83,  1, 'DEV-ACC-003', 'ACCELEROMETER', 'ACTIVE', 82, '2026-04-08 13:39:00'),
(84,  1, 'DEV-ACC-004', 'ACCELEROMETER', 'ACTIVE', 79, '2026-04-08 13:36:00'),
(85,  1, 'DEV-ACC-005', 'ACCELEROMETER', 'ACTIVE', 76, '2026-04-08 13:33:00'),
(86,  1, 'DEV-ACC-006', 'ACCELEROMETER', 'ACTIVE', 73, '2026-04-08 13:30:00'),
(87,  1, 'DEV-ACC-007', 'ACCELEROMETER', 'ACTIVE', 70, '2026-04-08 13:27:00'),
(88,  1, 'DEV-ACC-008', 'ACCELEROMETER', 'ACTIVE', 67, '2026-04-08 13:24:00'),
(89,  1, 'DEV-ACC-009', 'ACCELEROMETER', 'ACTIVE', 64, '2026-04-08 13:21:00'),
(90,  1, 'DEV-ACC-010', 'ACCELEROMETER', 'ACTIVE', 61, '2026-04-08 13:18:00'),
(91,  1, 'DEV-ACC-011', 'ACCELEROMETER', 'ACTIVE', 88, '2026-04-08 13:15:00'),
(92,  1, 'DEV-ACC-012', 'ACCELEROMETER', 'ACTIVE', 85, '2026-04-08 13:12:00'),
(93,  1, 'DEV-ACC-013', 'ACCELEROMETER', 'ACTIVE', 82, '2026-04-08 13:09:00'),
(94,  1, 'DEV-ACC-014', 'ACCELEROMETER', 'ACTIVE', 79, '2026-04-08 13:06:00'),
(95,  1, 'DEV-ACC-015', 'ACCELEROMETER', 'ACTIVE', 76, '2026-04-08 13:03:00'),
(96,  1, 'DEV-ACC-016', 'ACCELEROMETER', 'ACTIVE', 73, '2026-04-08 13:00:00'),
(97,  1, 'DEV-ACC-017', 'ACCELEROMETER', 'ACTIVE', 70, '2026-04-08 12:57:00'),
(98,  1, 'DEV-ACC-018', 'ACCELEROMETER', 'OFFLINE', NULL, '2026-04-08 11:00:00'),
(99,  1, 'DEV-ACC-019', 'ACCELEROMETER', 'OFFLINE', NULL, '2026-04-08 10:00:00'),
(100, 1, 'DEV-ACC-020', 'ACCELEROMETER', 'ACTIVE', 10, '2026-04-08 13:00:00');

-- 2. Device Licenses (one per device, auto-generated via SELECT)
INSERT INTO device_licenses (device_id, tenant_id, license_key, status, activated_at, expires_at)
SELECT
    d.id,
    d.tenant_id,
    'LIC-' || d.device_code || '-' || lpad(to_hex(d.id * 7919 % 65536), 4, '0'),
    'ACTIVE',
    '2026-01-01 00:00:00'::timestamp,
    '2027-12-31 23:59:59'::timestamp
FROM devices d
WHERE d.tenant_id = 1;

-- 3. Installations — pair GPS devices to livestock
-- Seed logic: animal N gets GPS if N%5!=0; animal N gets capsule if N%4==0
-- GPS installations: devices 1-40 mapped to livestock 1-40 (skip those where device_id%5==0)
INSERT INTO installations (device_id, livestock_id, installed_at, operator_id)
SELECT
    d.id,
    ls.id,
    '2026-03-01 09:00:00'::timestamp,
    (SELECT id FROM users WHERE username = 'owner' LIMIT 1)
FROM devices d
JOIN livestock ls ON ls.livestock_code = 'SL-2024-' || lpad((d.id)::text, 3, '0')
WHERE d.tenant_id = 1
  AND d.device_type = 'TRACKER'
  AND d.id <= 40
  AND d.id % 5 <> 0;

-- Capsule installations: devices 51-62 for livestock where livestock_code index % 4 == 0
-- i.e., livestock 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48
INSERT INTO installations (device_id, livestock_id, installed_at, operator_id)
SELECT
    d.id,
    ls.id,
    '2026-03-01 09:00:00'::timestamp,
    (SELECT id FROM users WHERE username = 'owner' LIMIT 1)
FROM (
    SELECT generate_series(1, 12) AS idx
) nums
JOIN devices d ON d.id = 50 + nums.idx
JOIN livestock ls ON ls.livestock_code = 'SL-2024-' || lpad((nums.idx * 4)::text, 3, '0')
WHERE d.tenant_id = 1
  AND d.device_type = 'CAPSULE';

-- 4. GPS Logs — 24 hourly positions per installed GPS tracker (trajectory data)
-- ~32 active trackers × 24 hours ≈ 768 rows
-- Each point adds small jitter around the livestock's last known position
INSERT INTO gps_logs (device_id, latitude, longitude, accuracy, recorded_at)
SELECT
    d.id,
    ls.last_latitude + (random() - 0.5) * 0.001,
    ls.last_longitude + (random() - 0.5) * 0.001,
    2.0 + random() * 3.0,
    (ls.last_position_at - (hours.h * INTERVAL '1 hour'))::timestamp
FROM devices d
JOIN installations inst ON inst.device_id = d.id AND inst.removed_at IS NULL
JOIN livestock ls ON ls.id = inst.livestock_id
CROSS JOIN generate_series(0, 23) AS hours(h)
WHERE d.tenant_id = 1
  AND d.device_type = 'TRACKER'
  AND d.status = 'ACTIVE';

-- Reset sequences
SELECT setval('devices_id_seq', (SELECT COALESCE(MAX(id), 1) FROM devices));
SELECT setval('device_licenses_id_seq', (SELECT COALESCE(MAX(id), 1) FROM device_licenses));
SELECT setval('installations_id_seq', (SELECT COALESCE(MAX(id), 1) FROM installations));
SELECT setval('gps_logs_id_seq', (SELECT COALESCE(MAX(id), 1) FROM gps_logs));
