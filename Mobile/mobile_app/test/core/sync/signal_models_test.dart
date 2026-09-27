import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/sync/signal_models.dart';

void main() {
  test('parses livestock signal with nested rumen metrics', () {
    final signal = LivestockSignal.fromJson({
      'livestockId': 14,
      'livestockCode': 'HKT14',
      'revision': 8,
      'health': {
        'status': 'CRITICAL',
        'activeAlertTypes': ['TEMPERATURE_ABNORMAL'],
        'metrics': {
          'rumenTemperature': {
            'value': 39.4,
            'unit': 'CELSIUS',
            'status': 'CRITICAL',
            'recordedAt': '2026-09-27T10:00:00Z',
            'ageSeconds': 12,
            'freshness': 'FRESH',
            'source': 'AGENTIC_PLATFORM',
          },
          'rumenMotility': {
            'value': 2.1,
            'unit': 'TIMES_PER_MINUTE',
            'status': 'NORMAL',
            'freshness': 'FRESH',
          },
        },
      },
      'ai': {'status': 'ALERT', 'score': 0.82},
      'fence': {'status': 'BREACH'},
      'presence': {
        'status': 'RETURN_HOME',
        'activeAlertTypes': ['RETURN_HOME'],
      },
      'device': {'status': 'NORMAL', 'deviceCount': 1},
      'alerts': {'activeCount': 2, 'unreadCount': 1},
    });

    expect(signal.livestockId, '14');
    expect(signal.health.status, 'CRITICAL');
    expect(signal.health.metrics.rumenTemperature.value, 39.4);
    expect(signal.health.metrics.rumenMotility.freshness, 'FRESH');
    expect(signal.ai.status, 'ALERT');
    expect(signal.fence.status, 'BREACH');
    expect(signal.presence.status, 'RETURN_HOME');
    expect(signal.presence.returnHome, isTrue);
    expect(signal.alerts.unreadCount, 1);
  });

  test('missing presence signal defaults to normal', () {
    final signal = LivestockSignal.fromJson({
      'livestockId': 14,
      'livestockCode': 'HKT14',
      'revision': 1,
    });

    expect(signal.presence.status, 'NORMAL');
    expect(signal.presence.returnHome, isFalse);
  });

  test('missing metrics remain missing instead of becoming zero', () {
    final health = HealthSignal.fromJson({});
    expect(health.metrics.rumenTemperature.value, isNull);
    expect(health.metrics.rumenTemperature.freshness, 'MISSING');
    expect(health.metrics.rumenMotility.value, isNull);
  });

  test('parses position updates', () {
    final position = PositionSignal.fromJson({
      'livestockId': 14,
      'revision': 3,
      'lat': 28.2465,
      'lng': 112.8513,
      'recordedAt': '2026-09-27T10:00:00Z',
      'ageSeconds': 15,
      'freshness': 'FRESH',
      'source': 'AGENTIC_PLATFORM',
    });

    expect(position.latitude, 28.2465);
    expect(position.freshness, 'FRESH');
  });
}
