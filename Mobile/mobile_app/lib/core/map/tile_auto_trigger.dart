// lib/core/map/tile_auto_trigger.dart

import 'package:hkt_livestock_agentic/core/api/api_client.dart';

/// 缺瓦片自动触发下载任务（P3 块2）。
///
/// 地图页检测到无自建 region 时，fire-and-forget POST /admin/tiles/tasks，
/// worker 后台生成 mbtiles → tileserver 加载。session 内每 farm 去重一次。
/// owner 无 admin 权限会 403，静默忽略（靠 admin 页手动或降级底图）。
class TileAutoTrigger {
  TileAutoTrigger._();

  static final _triggered = <String>{};
  static const _buffer = 0.15; // ~16km

  /// region 空时触发下载任务。fire-and-forget，调用方无需 await。
  static Future<void> triggerIfMissing({
    required String farmKey,
    required double centerLon,
    required double centerLat,
  }) async {
    if (!_triggered.add(farmKey)) return; // session 去重
    try {
      await ApiClient.instance.post('/admin/tiles/tasks', body: {
        'regionName': 'auto-$farmKey',
        'minLon': centerLon - _buffer,
        'minLat': centerLat - _buffer,
        'maxLon': centerLon + _buffer,
        'maxLat': centerLat + _buffer,
        'minZoom': 11,
        'maxZoom': 15,
        'isCustomRegion': true,
      });
    } catch (_) {
      // owner 无 admin 权限会 403，或其他错误：静默，不阻塞渲染
    }
  }
}
