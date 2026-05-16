import 'dart:math';
import 'package:latlong2/latlong.dart';

/// WGS-84 → GCJ-02 坐标转换
/// 高德地图使用 GCJ-02 坐标系，GPS 设备输出 WGS-84。
class CoordTransform {
  const CoordTransform._();

  static const double _a = 6378245.0;
  static const double _ee = 0.00669342162296594323;

  /// 将 WGS-84 坐标转换为 GCJ-02（用于高德瓦片上显示 GPS 数据）
  static LatLng wgs84ToGcj02(LatLng wgs) {
    final lat = wgs.latitude;
    final lng = wgs.longitude;
    if (_outOfChina(lat, lng)) return wgs;
    var dLat = _transformLat(lng - 105.0, lat - 35.0);
    var dLng = _transformLng(lng - 105.0, lat - 35.0);
    final radLat = lat / 180.0 * pi;
    var magic = sin(radLat);
    magic = 1 - _ee * magic * magic;
    final sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * pi);
    dLng = (dLng * 180.0) / (_a / sqrtMagic * cos(radLat) * pi);
    return LatLng(lat + dLat, lng + dLng);
  }

  /// 批量转换
  static List<LatLng> wgs84ToGcj02All(List<LatLng> points) {
    return points.map(wgs84ToGcj02).toList();
  }

  /// GCJ-02 → WGS-84 迭代法逆转换（精度 < 0.1m）
  static LatLng gcj02ToWgs84(LatLng gcj) {
    if (_outOfChina(gcj.latitude, gcj.longitude)) return gcj;
    var guess = gcj;
    for (int i = 0; i < 10; i++) {
      final transformed = wgs84ToGcj02(guess);
      final dLat = gcj.latitude - transformed.latitude;
      final dLng = gcj.longitude - transformed.longitude;
      if (dLat.abs() < 1e-8 && dLng.abs() < 1e-8) break;
      guess = LatLng(guess.latitude + dLat, guess.longitude + dLng);
    }
    return guess;
  }

  /// 批量逆转换
  static List<LatLng> gcj02ToWgs84All(List<LatLng> points) {
    return points.map(gcj02ToWgs84).toList();
  }

  static double _transformLat(double x, double y) {
    var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y +
        0.1 * x * y + 0.2 * sqrt(x.abs());
    ret +=
        (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret +=
        (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) *
        2.0 /
        3.0;
    return ret;
  }

  static double _transformLng(double x, double y) {
    var ret = 300.0 + x + 2.0 * y + 0.1 * x * x +
        0.1 * x * y + 0.1 * sqrt(x.abs());
    ret +=
        (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret +=
        (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) *
        2.0 /
        3.0;
    return ret;
  }

  static bool _outOfChina(double lat, double lng) {
    return lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271;
  }
}
