-- 瓦片下载 Worker 专用 API Key（platform_admin 角色，访问 /admin/tiles/* 生成离线瓦片）
-- rawKey = sl_live_tile_worker_a1b2c3d4e5f6g7h8i9j0k1l2
-- Use via: X-API-Key: sl_live_tile_worker_a1b2c3d4e5f6g7h8i9j0k1l2
INSERT INTO api_keys (tenant_id, key_name, key_hash, key_prefix, status, role, scopes, requests_per_minute, daily_quota, description, created_at)
VALUES (
    1,
    '瓦片下载 Worker',
    '10373346c42b31e69a069264b2b2cbdf95002e551331baaa3ced4266adce5c62',
    'sl_live_tile',
    'ACTIVE',
    'platform_admin',
    '*',
    600,
    1000000,
    'P2 tile-download worker — polls pending TileGenerationTask, generates offline mbtiles',
    NOW()
);
