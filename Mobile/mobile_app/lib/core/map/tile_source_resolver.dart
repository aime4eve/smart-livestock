import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final String baseUrl;
  final Map<String, String> headers;

  TileSourceResolver({required this.baseUrl, required this.headers});

  Future<List<TileSource>> resolve(int farmId) async {
    final uri = Uri.parse('$baseUrl/farms/$farmId/tile-source');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body);
    final data = body['data'];
    if (data is List) {
      return data.map((e) => TileSource.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}

final tileSourceResolverProvider = Provider<TileSourceResolver>((ref) {
  return TileSourceResolver(
    baseUrl: 'http://127.0.0.1:18080/api/v1',
    headers: {},
  );
});
