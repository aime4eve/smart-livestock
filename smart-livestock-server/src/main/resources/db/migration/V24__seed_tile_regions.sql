-- Seed tile_regions from server MBTiles files (15 regions)
-- All files confirmed to exist in /data/mbtiles/ on the server

INSERT INTO tile_regions (id, name, min_lon, min_lat, max_lon, max_lat, min_zoom, max_zoom, file_name, file_size, status, generated_at) VALUES
(1,  'changsha-demo',       112.8,    28.1,    113.1,    28.4,     11, 15, 'changsha-demo.mbtiles',       19656704, 'ready', NOW()),
(2,  'changsha',            112.8588, 28.1682, 113.0188, 28.2882,  11, 15, 'changsha.mbtiles',             2162688, 'ready', NOW()),
(3,  'inner-mongolia',      105.0,    38.0,    125.0,    52.0,     11, 15, 'inner-mongolia.mbtiles',     109309952, 'ready', NOW()),
(4,  'xinjiang',            73.0,     35.0,    96.0,     50.0,     11, 15, 'xinjiang.mbtiles',            33624064, 'ready', NOW()),
(5,  'qinghai-tibet',       78.0,     26.0,    103.0,    40.0,     11, 15, 'qinghai-tibet.mbtiles',       46424064, 'ready', NOW()),
(6,  'mongolia',            88.0,     42.0,    120.0,    52.0,     11, 15, 'mongolia.mbtiles',            29016064, 'ready', NOW()),
(7,  'australia',           113.0,   -38.0,    153.0,   -12.0,     11, 15, 'australia.mbtiles',           57819136, 'ready', NOW()),
(8,  'new-zealand',         165.0,   -47.0,    179.0,   -34.0,     11, 15, 'new-zealand.mbtiles',         39940096, 'ready', NOW()),
(9,  'scandinavia-reindeer',  5.0,    55.0,     30.0,    71.0,     11, 15, 'scandinavia-reindeer.mbtiles',151162880,'ready', NOW()),
(10, 'uk-ireland',          -11.0,    50.0,      2.0,    59.0,     11, 15, 'uk-ireland.mbtiles',          30797824, 'ready', NOW()),
(11, 'argentina-pampas',    -70.0,   -42.0,    -55.0,   -22.0,     11, 15, 'argentina-pampas.mbtiles',    37109760, 'ready', NOW()),
(12, 'brazil-central',      -58.0,   -30.0,    -34.0,     0.0,     11, 15, 'brazil-central.mbtiles',      75223040, 'ready', NOW()),
(13, 'east-africa',          33.0,    -5.0,     42.0,    12.0,     11, 15, 'east-africa.mbtiles',         19595264, 'ready', NOW()),
(14, 'india-northwest',      68.0,    20.0,     78.0,    30.0,     11, 15, 'india-northwest.mbtiles',     21123072, 'ready', NOW()),
(15, 'south-africa',         16.0,   -35.0,     33.0,   -22.0,     11, 15, 'south-africa.mbtiles',        24162304, 'ready', NOW());

-- Reset tile_regions_id_seq so future inserts get id > 15
SELECT setval('tile_regions_id_seq', 15);

-- farm_tile_tasks: match existing farms to tile_regions by coordinates
-- Farm 1: 主牧场 (28.2458, 112.8519) → inside changsha-demo AND changsha
INSERT INTO farm_tile_tasks (farm_id, region_id, status, file_size, requested_at)
VALUES
  (1, 1, 'ready', 19656704, NOW()),
  (1, 2, 'ready',  2162688, NOW());

-- Farm 2: 南山分场 (28.2000, 112.9000) → inside changsha-demo only
INSERT INTO farm_tile_tasks (farm_id, region_id, status, file_size, requested_at)
VALUES
  (2, 1, 'ready', 19656704, NOW());

-- Farm 5: 瓦片测试牧场 (28.2458, 112.8519) → same as farm 1
INSERT INTO farm_tile_tasks (farm_id, region_id, status, file_size, requested_at)
VALUES
  (5, 1, 'ready', 19656704, NOW()),
  (5, 2, 'ready',  2162688, NOW());
