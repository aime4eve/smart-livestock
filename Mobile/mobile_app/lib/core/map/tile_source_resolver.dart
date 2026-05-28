import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';

class TileSource {
  final String sourceName;
  final String tileUrl;
  TileSource({required this.sourceName, required this.tileUrl});

  factory TileSource.fromJson(Map<String, dynamic> json) {
    return TileSource(
      sourceName: json['sourceName'] as String,
      tileUrl: json['tileUrl'] as String,
    );
  }
}

class TileSourceResolver {
  final ApiClient _apiClient;

  TileSourceResolver({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<TileSource>> resolve(int farmId) async {
    final data = await _apiClient.farmGet('/tile-source');
    final rawList = data['data'];
    if (rawList is List) {
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => TileSource.fromJson(e))
          .toList();
    }
    return [];
  }
}

final tileSourceResolverProvider = Provider<TileSourceResolver>((ref) {
  return TileSourceResolver(apiClient: ApiClient.instance);
});
