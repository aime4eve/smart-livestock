import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hkt_livestock_agentic/core/database/app_database.dart';

class TileAnalytics {
  final AppDatabase _db;
  final String _apiBaseUrl;
  final Map<String, String> _headers;
  static const int _flushThreshold = 20;

  TileAnalytics(this._db, this._apiBaseUrl, this._headers);

  Future<void> log(String event, Map<String, dynamic> data) async {
    _db.insertAnalyticsEvent(event, jsonEncode(data));
    final unreported = _db.getUnreportedEvents();
    if (unreported.length >= _flushThreshold) {
      await flush();
    }
  }

  Future<void> flush() async {
    final events = _db.getUnreportedEvents();
    if (events.isEmpty) return;

    final batch = events.map((e) => {
      'event': e['event_type'],
      'timestamp': e['created_at'],
      ...jsonDecode(e['payload'] as String) as Map<String, dynamic>,
    }).toList();

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/analytics/events'),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode(batch),
      );
      if (response.statusCode == 200) {
        _db.markEventsReported(events.map((e) => e['id'] as int).toList());
      }
    } catch (e) {
      // Keep unreported events for next flush attempt
    }
  }
}

final tileAnalyticsProvider = Provider<TileAnalytics>((ref) {
  throw UnimplementedError('Override in app with real dependencies');
});
