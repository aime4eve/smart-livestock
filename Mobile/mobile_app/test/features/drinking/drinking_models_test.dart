import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/drinking/domain/drinking_models.dart';

void main() {
  group('DrinkingSummary.fromJson', () {
    test('days=7 payload parses daily, weekly and 7 dayCounts', () {
      final m = <String, dynamic>{
        'date': '2026-10-04',
        'days': 7,
        'daily': {
          'count': 7,
          'events': [
            {
              'startAt': '2026-10-03T22:10:00Z',
              'endAt': '2026-10-03T22:16:00Z',
              'tempDrop': 1.7,
              'label': 'UNLABELED',
              'confidence': 0.91,
              'source': 'THINGSBOARD',
            },
          ],
          'lastDrinkEndAt': '2026-10-04T01:46:00Z',
        },
        'weekly': {'count': 48, 'avgPerDay': 6.9},
        'rolling30dBaseline': null,
        'dayCounts': [
          {'date': '2026-09-28', 'count': 8, 'feverCoveredPercent': 0},
          {'date': '2026-09-29', 'count': 7, 'feverCoveredPercent': null},
          {'date': '2026-09-30', 'count': 9, 'feverCoveredPercent': 0},
          {'date': '2026-10-01', 'count': 6, 'feverCoveredPercent': 0},
          {'date': '2026-10-02', 'count': 3, 'feverCoveredPercent': 82.5},
          {'date': '2026-10-03', 'count': 8, 'feverCoveredPercent': 0},
          {'date': '2026-10-04', 'count': 7, 'feverCoveredPercent': 0},
        ],
      };

      final s = DrinkingSummary.fromJson(m);

      expect(s.daily.count, 7);
      expect(s.daily.lastDrinkEndAt, DateTime.parse('2026-10-04T01:46:00Z'));
      expect(s.daily.events.single.label, DrinkingLabel.unlabeled);
      expect(s.daily.events.single.tempDrop, 1.7);
      expect(s.weekly!.count, 48);
      expect(s.weekly!.avgPerDay, 6.9);
      expect(s.rolling30dBaseline, isNull);
      expect(s.dayCounts.length, 7);
      expect(s.dayCounts[4].isFeverDay, isTrue);
      expect(s.dayCounts[1].isFeverDay, isFalse); // null percent → not fever
      // Missing baselineMinDays falls back to the response-default 3.
      expect(s.baselineMinDays, kDrinkingBaselineMinDays);
    });

    test('days=30 payload parses rolling baseline', () {
      final m = <String, dynamic>{
        'date': '2026-10-04',
        'days': 30,
        'daily': {
          'count': 7,
          'events': const [],
          'lastDrinkEndAt': '2026-10-04T01:46:00Z',
        },
        'weekly': null,
        'rolling30dBaseline': {'avgPerDay': 7.6, 'sampleDays': 6},
        'dayCounts': const [],
        'baselineMinDays': 5,
      };

      final s = DrinkingSummary.fromJson(m);

      expect(s.weekly, isNull);
      expect(s.rolling30dBaseline!.avgPerDay, 7.6);
      expect(s.rolling30dBaseline!.sampleDays, 6);
      // Server-delivered threshold is consumed as-is (no front-end mirror).
      expect(s.baselineMinDays, 5);
    });
  });

  group('DrinkingSummaryBundle', () {
    DrinkingSummary summary7WithCounts(List<int> counts) {
      return DrinkingSummary(
        date: '2026-10-04',
        days: 7,
        daily: DrinkingDaily(
          count: counts.last,
          events: const [],
          lastDrinkEndAt: null,
        ),
        dayCounts: [
          for (var i = 0; i < counts.length; i++)
            DrinkingDayCount(
              date: '2026-10-0${i + 1}',
              count: counts[i],
              feverCoveredPercent: i == 4 ? 90 : 0,
            ),
        ],
      );
    }

    test('weekBars sorts ascending and trims to 7', () {
      final bundle = DrinkingSummaryBundle(
        summary7: summary7WithCounts([8, 7, 9, 6, 3, 8, 7]),
        summary30: const DrinkingSummary(
          date: '2026-10-04',
          days: 30,
          daily: DrinkingDaily(count: 7, events: [], lastDrinkEndAt: null),
          rolling30dBaseline: DrinkingRollingBaseline(
            avgPerDay: 7.6,
            sampleDays: 6,
          ),
          dayCounts: [],
        ),
      );

      expect(bundle.weekBars.map((b) => b.count).toList(), [8, 7, 9, 6, 3, 8, 7]);
      expect(bundle.baselineSampleDays, 6);
      expect(bundle.lastFeverDay!.date, '2026-10-05');
    });

    test('missing baseline block yields 0 sample days', () {
      final bundle = DrinkingSummaryBundle(
        summary7: summary7WithCounts([1, 1, 1, 1, 1, 1, 1]),
        summary30: const DrinkingSummary(
          date: '2026-10-04',
          days: 30,
          daily: DrinkingDaily(count: 1, events: [], lastDrinkEndAt: null),
          dayCounts: [],
        ),
      );
      expect(bundle.baselineSampleDays, 0);
    });

    test('baselineMinDays is exposed from the days=30 layer', () {
      final bundle = DrinkingSummaryBundle(
        summary7: summary7WithCounts([8, 7, 9, 6, 3, 8, 7]),
        summary30: const DrinkingSummary(
          date: '2026-10-04',
          days: 30,
          daily: DrinkingDaily(count: 7, events: [], lastDrinkEndAt: null),
          rolling30dBaseline: DrinkingRollingBaseline(
            avgPerDay: 7.6,
            sampleDays: 6,
          ),
          dayCounts: [],
          baselineMinDays: 5,
        ),
      );
      expect(bundle.baselineMinDays, 5);
    });
  });

  group('DrinkingEvent.fromJson', () {
    test('parses candidate rows and marking-loop helpers', () {
      final candidate = DrinkingEvent.fromJson({
        'id': 11,
        'livestockId': 4,
        'deviceId': 2,
        'eventStartAt': '2026-10-04T02:00:00Z',
        'eventEndAt': '2026-10-04T02:07:00Z',
        'tempDrop': 0.9,
        'minTemp': 37.4,
        'source': 'ALGORITHM_CANDIDATE',
        'label': 'UNLABELED',
        'confidence': 0.42,
        'algorithmVersion': 'v1',
        'note': null,
        'lowConfidence': true,
      });
      expect(candidate.isCandidate, isTrue);
      expect(candidate.isManual, isFalse);
      // The server-derived flag drives the badge (0.42 < 0.5 server-side).
      expect(candidate.lowConfidence, isTrue);
      expect(candidate.needsVerification, isTrue);

      final manual = DrinkingEvent.fromJson({
        'id': 12,
        'livestockId': 4,
        'eventStartAt': '2026-10-04T03:00:00Z',
        'eventEndAt': '2026-10-04T03:05:00Z',
        'source': 'MANUAL',
        'label': 'CONFIRMED',
        'confidence': null,
        'lowConfidence': false,
      });
      expect(manual.isManual, isTrue);
      expect(manual.label, DrinkingLabel.confirmed);
      expect(manual.lowConfidence, isFalse);
      expect(manual.needsVerification, isFalse);
    });

    test('missing lowConfidence defaults to false', () {
      final legacy = DrinkingEvent.fromJson({
        'id': 13,
        'livestockId': 4,
        'eventStartAt': '2026-10-04T04:00:00Z',
        'eventEndAt': '2026-10-04T04:06:00Z',
        'source': 'THINGSBOARD',
        'label': 'CONFIRMED',
        'confidence': 0.42,
      });
      expect(legacy.lowConfidence, isFalse);
      expect(legacy.needsVerification, isFalse);
    });
  });

  group('DrinkingPeerComparison.fromJson', () {
    test('normal payload', () {
      final peer = DrinkingPeerComparison.fromJson({
        'peerAvgPerDay': 7.3,
        'reason': null,
        'groupBreed': 'SIMMENTAL',
        'groupStage': 'LACTATING',
        'peerCount': 12,
        'sampleDaysTotal': 260,
        'minSampleDays': 5,
      });
      expect(peer.insufficientPeers, isFalse);
      expect(peer.peerAvgPerDay, 7.3);
      expect(peer.groupStage, 'LACTATING');
    });

    test('INSUFFICIENT_PEERS keeps the degraded copy path', () {
      final peer = DrinkingPeerComparison.fromJson({
        'peerAvgPerDay': null,
        'reason': 'INSUFFICIENT_PEERS',
        'groupBreed': 'SIMMENTAL',
        'groupStage': null,
        'peerCount': 1,
        'sampleDaysTotal': 6,
        'minSampleDays': 5,
      });
      expect(peer.insufficientPeers, isTrue);
      expect(peer.peerAvgPerDay, isNull);
    });
  });
}
