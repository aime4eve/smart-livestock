-- ============================================================
-- V30: Translate alert messages — Chinese → English
-- Moved out of V29: V29 was already executed, so per the
-- Flyway checksum lesson its content must not change.
-- ============================================================

UPDATE alerts SET message = REPLACE(message, '越界', 'Breach') WHERE message LIKE '%越界%';
UPDATE alerts SET message = REPLACE(message, '围栏接近', 'Near Fence') WHERE message LIKE '%围栏接近%';
UPDATE alerts SET message = REPLACE(message, '体温异常', 'Temperature Abnormal') WHERE message LIKE '%体温异常%';
UPDATE alerts SET message = REPLACE(message, '设备离线', 'Device Offline') WHERE message LIKE '%设备离线%';
UPDATE alerts SET message = REPLACE(message, '低电量', 'Low Battery') WHERE message LIKE '%低电量%';
UPDATE alerts SET message = REPLACE(message, '行为异常', 'Behavior Abnormal') WHERE message LIKE '%行为异常%';
