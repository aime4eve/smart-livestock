import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/map/coord_transform.dart';

/// 地图默认配置 — 预设城市中心点、缩放级别、瓦片源
class MapConfig {
  const MapConfig._();

  // ── 默认城市：中国·湖南·长沙 ──
  static const String defaultCity = '长沙';
  static const String defaultProvince = '湖南';
  static const String defaultCountry = '中国';

  /// 长沙市中心 WGS-84 坐标
  static const LatLng _wgsCenter = LatLng(28.2282, 112.9388);

  /// 地图中心（已转为 GCJ-02 适配高德瓦片）
  static final LatLng defaultCenter =
      CoordTransform.wgs84ToGcj02(_wgsCenter);

  /// 默认缩放级别（13 ≈ 城区街道级别）
  static const double defaultZoom = 13.0;

  /// 预缓存范围：市中心四周各偏移 0.05° ≈ 5.5 km
  static const double cacheRadius = 0.05;

  /// 预缓存缩放级别范围
  static const int cacheMinZoom = 11;
  static const int cacheMaxZoom = 15;

  /// 高德瓦片源（GCJ-02 坐标系，国内可访问）
  static const String tileUrlTemplate =
      'https://webrd02.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=7&x={x}&y={y}&z={z}';

  /// OSM 瓦片源（WGS-84，需外网访问）
  static const String osmTileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// MBTiles 离线瓦片配置
  static const String mbtilesAssetPath = 'assets/map/sample.mbtiles';
  static const String mbtilesFileName = 'sample.mbtiles';

  /// 缓存子目录名
  static const String cacheDirName = 'map_tiles';

  /// 瓦片缓存有效期
  static const Duration cacheValidDuration = Duration(days: 30);

  /// 预设城市列表（坐标已转为 GCJ-02）
  static final List<MapPreset> cityPresets = [
    MapPreset(
      name: '长沙',
      province: '湖南',
      country: '中国',
      center: CoordTransform.wgs84ToGcj02(const LatLng(28.2282, 112.9388)),
    ),
    MapPreset(
      name: '北京',
      province: '北京',
      country: '中国',
      center: CoordTransform.wgs84ToGcj02(const LatLng(39.9042, 116.4074)),
    ),
    MapPreset(
      name: '上海',
      province: '上海',
      country: '中国',
      center: CoordTransform.wgs84ToGcj02(const LatLng(31.2304, 121.4737)),
    ),
    MapPreset(
      name: '乌鲁木齐',
      province: '新疆',
      country: '中国',
      center: CoordTransform.wgs84ToGcj02(const LatLng(43.8256, 87.6168)),
    ),
    MapPreset(
      name: '呼和浩特',
      province: '内蒙古',
      country: '中国',
      center: CoordTransform.wgs84ToGcj02(const LatLng(40.8422, 111.7500)),
    ),
    MapPreset(
      name: '悉尼',
      province: '新南威尔士',
      country: '澳大利亚',
      center: const LatLng(-33.8688, 151.2093),
    ),
  ];
}

class MapPreset {
  const MapPreset({
    required this.name,
    required this.province,
    required this.country,
    required this.center,
  });

  final String name;
  final String province;
  final String country;
  final LatLng center;

  String get displayName => '$country·$province·$name';
}
