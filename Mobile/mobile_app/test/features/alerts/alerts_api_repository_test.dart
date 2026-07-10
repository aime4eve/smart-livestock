import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/features/alerts/data/alerts_api_repository.dart';

void main() {
  group('AlertsApiRepository._alertItemFromMap', () {
    test('CRITICAL severity maps to P0 priority', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'type': 'FENCE_BREACH',
        'severity': 'CRITICAL',
        'status': 'ACTIVE',
        'message': '越界告警',
        'livestockId': 'liv-1',
      });
      expect(a.priority, 'P0');
      expect(a.type, 'FENCE_BREACH');
      expect(a.stage, 'active');
      expect(a.title, '越界告警');
      expect(a.livestockId, 'liv-1');
      expect(a.earTag, 'liv-1');
      expect(a.source, 'RULE');
    });

    test('WARNING severity maps to P1 priority', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
      });
      expect(a.priority, 'P1');
    });

    test('LOW severity maps to P2 priority', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'LOW',
      });
      expect(a.priority, 'P2');
    });

    test('null severity defaults to WARNING/P1', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
      });
      expect(a.priority, 'P1');
    });

    test('lowercase severity still maps correctly', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'critical',
      });
      expect(a.priority, 'P0');
    });

    test('status DISMISSED maps to dismissed stage', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
        'status': 'DISMISSED',
      });
      expect(a.stage, 'dismissed');
    });

    test('status AUTO_RESOLVED maps to autoResolved stage', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
        'status': 'AUTO_RESOLVED',
      });
      expect(a.stage, 'autoResolved');
    });

    test('legacy status PENDING maps to active', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
        'status': 'PENDING',
      });
      expect(a.stage, 'active');
    });

    test('legacy status ACKNOWLEDGED maps to active', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
        'status': 'ACKNOWLEDGED',
      });
      expect(a.stage, 'active');
    });

    test('legacy status HANDLED maps to dismissed', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
        'status': 'HANDLED',
      });
      expect(a.stage, 'dismissed');
    });

    test('legacy status ARCHIVED maps to autoResolved', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
        'status': 'ARCHIVED',
      });
      expect(a.stage, 'autoResolved');
    });

    test('unknown status defaults to active', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
        'status': 'WHATEVER',
      });
      expect(a.stage, 'active');
    });

    test('null status defaults to active', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
      });
      expect(a.stage, 'active');
    });

    test('null type defaults to unknown', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
      });
      expect(a.type, 'unknown');
    });

    test('int id converted to string', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': 99,
        'severity': 'WARNING',
      });
      expect(a.id, '99');
    });

    test('int livestockId converted to string', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
        'livestockId': 42,
      });
      expect(a.livestockId, '42');
      expect(a.earTag, '42');
    });

    test('null livestockId defaults earTag to dash', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
      });
      expect(a.livestockId, isNull);
      expect(a.earTag, '-');
    });

    test('custom source overrides default RULE', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
        'source': 'AI',
      });
      expect(a.source, 'AI');
    });

    test('null message produces empty title', () {
      final a = AlertsApiRepository.alertItemFromMapForTest({
        'id': '1',
        'severity': 'WARNING',
      });
      expect(a.title, '');
    });
  });

  group('AlertsApiRepository._alertDetailFromMap', () {
    test('occurredAt extracted from response', () {
      final d = AlertsApiRepository.alertDetailFromMapForTest({
        'id': 'a1',
        'type': 'TEMPERATURE_ABNORMAL',
        'severity': 'CRITICAL',
        'status': 'ACTIVE',
        'message': '体温过高',
        'livestockId': 'liv-1',
        'occurredAt': '2026-07-01T08:00:00Z',
      });

      expect(d.id, 'a1');
      expect(d.priority, 'P0');
      expect(d.occurredAt, '2026-07-01T08:00:00Z');
      expect(d.description, '体温过高');
      expect(d.title, '体温过高');
    });

    test('resolvedAt used as fallback when occurredAt absent', () {
      final d = AlertsApiRepository.alertDetailFromMapForTest({
        'id': 'a2',
        'severity': 'WARNING',
        'status': 'AUTO_RESOLVED',
        'resolvedAt': '2026-07-01T09:00:00Z',
      });

      expect(d.occurredAt, '2026-07-01T09:00:00Z');
    });

    test('null occurredAt and resolvedAt yields null', () {
      final d = AlertsApiRepository.alertDetailFromMapForTest({
        'id': 'a3',
        'severity': 'WARNING',
      });

      expect(d.occurredAt, isNull);
    });
  });
}
