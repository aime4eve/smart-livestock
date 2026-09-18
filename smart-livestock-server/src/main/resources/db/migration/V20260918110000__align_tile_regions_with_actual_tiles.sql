-- Align tile_regions with the MBTiles actually shipped in
-- infrastructure/tileserver/data/ (16 files, md5-verified against the
-- test-environment tileserver volume on 2026-09-18).
--
-- V24 seeded 15 regions with placeholder zoom 11-15 and missed
-- usa-great-plains, whose file ships and deploys to test. Real per-file
-- zoom ranges (read from each MBTiles metadata table) are 7-10 / 7-11 /
-- 11-15 (changsha-demo) / 12-14 (changsha).
--
-- Idempotent upsert by the unique region name, without explicit ids:
-- live environments re-registered these rows via tile-worker sync_regions
-- under fresh ids, so hardcoding ids like V24 did would collide.

INSERT INTO tile_regions
    (name, min_lon, min_lat, max_lon, max_lat, min_zoom, max_zoom,
     file_name, file_size, md5, status, generated_at)
VALUES
  -- usa-great-plains first: conflicting rows still draw from the id
  -- sequence, so putting the only true INSERT first lands it on id 16
  -- (right after V24's setval(15)) on a fresh install; the trailing
  -- setval() re-tightens the sequence on live environments.
  ('usa-great-plains',   -105.0,  25.0, -80.0,  49.0,   7, 10, 'usa-great-plains.mbtiles',    127426560, 'c3b00e4ac5b8ed9f9eb6189d7866badb', 'ready', NOW()),
  ('argentina-pampas',    -70.0, -42.0, -55.0, -22.0,  7, 10, 'argentina-pampas.mbtiles',     37109760, 'd798798a71cf3befe86dbb0f155f716f', 'ready', NOW()),
  ('australia',           113.0, -38.0, 153.0, -12.0,   7, 10, 'australia.mbtiles',            57819136, 'fe53f5e4c6ffdaee34efbf702034ebbc', 'ready', NOW()),
  ('brazil-central',      -58.0, -30.0, -34.0,   0.0,   7, 10, 'brazil-central.mbtiles',       75223040, 'de7e2674b1c19f898fe21eca1165f952', 'ready', NOW()),
  ('changsha-demo',       112.8,  28.1, 113.1,  28.4,  11, 15, 'changsha-demo.mbtiles',        19656704, '76416ebe15552eac42572ccb2a2f3b2a', 'ready', NOW()),
  ('changsha',        112.8588, 28.1682, 113.0188, 28.2882, 12, 14, 'changsha.mbtiles',      2162688, 'bea6ebcacbae7b95a4dd692cab0fa4ef', 'ready', NOW()),
  ('east-africa',          33.0,  -5.0,  42.0,  12.0,   7, 10, 'east-africa.mbtiles',          19595264, '9c1c4435ca3c771181176eb97290a875', 'ready', NOW()),
  ('india-northwest',      68.0,  20.0,  78.0,  30.0,   7, 10, 'india-northwest.mbtiles',      21123072, 'e66fff0fda409cfab0970fa3843d333b', 'ready', NOW()),
  ('inner-mongolia',      105.0,  38.0, 125.0,  52.0,   7, 11, 'inner-mongolia.mbtiles',      109309952, 'd8b34cd9c9c150b6e67e4a7ff0dfa205', 'ready', NOW()),
  ('mongolia',             88.0,  42.0, 120.0,  52.0,   7, 10, 'mongolia.mbtiles',             29016064, '2f73987748734fe325c4847d2d681279', 'ready', NOW()),
  ('new-zealand',         165.0, -47.0, 179.0, -34.0,   7, 11, 'new-zealand.mbtiles',          39940096, 'ec87cd4ff27942310d7450044f2ed56e', 'ready', NOW()),
  ('qinghai-tibet',        78.0,  26.0, 103.0,  40.0,   7, 10, 'qinghai-tibet.mbtiles',        46424064, '08763703fcf6c010c308c484d166a2ce', 'ready', NOW()),
  ('scandinavia-reindeer',  5.0,  55.0,  30.0,  71.0,   7, 10, 'scandinavia-reindeer.mbtiles',151162880, 'ef29f81bd6029d2418487804e9e1f528', 'ready', NOW()),
  ('south-africa',         16.0, -35.0,  33.0, -22.0,   7, 10, 'south-africa.mbtiles',         24162304, 'ce7ba1a57cb51ef0a6b13d1519f8f063', 'ready', NOW()),
  ('uk-ireland',          -11.0,  50.0,   2.0,  59.0,   7, 10, 'uk-ireland.mbtiles',           30797824, 'b331e9ee4206fe24a27d8551e20009e8', 'ready', NOW()),
  ('xinjiang',             73.0,  35.0,  96.0,  50.0,   7, 10, 'xinjiang.mbtiles',             33624064, 'a063597fda55379a0c18aa50f9bdcdaf', 'ready', NOW())
ON CONFLICT (name) DO UPDATE SET
  min_lon      = EXCLUDED.min_lon,
  min_lat      = EXCLUDED.min_lat,
  max_lon      = EXCLUDED.max_lon,
  max_lat      = EXCLUDED.max_lat,
  min_zoom     = EXCLUDED.min_zoom,
  max_zoom     = EXCLUDED.max_zoom,
  file_name    = EXCLUDED.file_name,
  file_size    = EXCLUDED.file_size,
  md5          = EXCLUDED.md5,
  status       = 'ready',
  generated_at = NOW();

-- Keep the id sequence above the highest row so future API inserts
-- (tile-worker sync_regions) never collide with existing ids.
SELECT setval('tile_regions_id_seq',
              GREATEST((SELECT COALESCE(MAX(id), 1) FROM tile_regions), 1));
