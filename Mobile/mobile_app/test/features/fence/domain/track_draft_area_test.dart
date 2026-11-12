import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/features/fence/domain/track_draft_area.dart';

/// formatAreaForLocale unit tests: zh mu formatting (1 decimal, 0.1-mu
/// display floor), en hectare formatting (2 decimals, 0.01-ha floor),
/// exact-boundary non-degradation, raw-㎡ fallback for sub-floor areas,
/// and the non-zh → hectare branch routing (plan Task 4 / appendix A
/// rulings #14/#30).
void main() {
  test('zh formats areas >= 0.1 mu with 1 decimal', () {
    // 666.7 m² = 1.00005 mu → "1.0"; 333.3 m² = 0.49995 mu → "0.5".
    final oneMu = formatAreaForLocale('zh', 666.7);
    expect(oneMu.value, '1.0');
    expect(oneMu.fallback, isFalse);

    final halfMu = formatAreaForLocale('zh', 333.3);
    expect(halfMu.value, '0.5');
    expect(halfMu.fallback, isFalse);
  });

  test('zh keeps exactly-0.1-mu areas on the mu scale (no fallback)', () {
    // sqmPerMu × 0.1 (= 200/3 m²) is mathematically exactly 0.1 mu. In
    // IEEE doubles the quotient lands at 0.10000000000000002, still
    // >= 0.1 → stays on the mu scale, formatted with 1 decimal.
    final area = formatAreaForLocale('zh', sqmPerMu * 0.1);
    expect(area.fallback, isFalse);
    expect(area.value, '0.1');
  });

  test('zh degrades areas < 0.1 mu to raw square meters', () {
    // 25 m² = 0.0375 mu → below the display floor; value is the rounded
    // raw ㎡ rendered by the caller via fenceTrackDraftAreaSqmFallback.
    final area = formatAreaForLocale('zh', 25);
    expect(area.fallback, isTrue);
    expect(area.value, '25');
  });

  test('en formats areas >= 0.01 ha with 2 decimals', () {
    final oneHa = formatAreaForLocale('en', 10000);
    expect(oneHa.value, '1.00');
    expect(oneHa.fallback, isFalse);

    // 12345 m² = 1.2345 ha → rounds to "1.23".
    final fractional = formatAreaForLocale('en', 12345);
    expect(fractional.value, '1.23');
    expect(fractional.fallback, isFalse);
  });

  test('en keeps exactly-0.01-ha areas on the ha scale (no fallback)', () {
    // 100 m² / 10000 = 0.01 exactly (both doubles exact) → >= 0.01 holds.
    final area = formatAreaForLocale('en', 100);
    expect(area.fallback, isFalse);
    expect(area.value, '0.01');
  });

  test('en degrades areas < 0.01 ha to raw square meters', () {
    final area = formatAreaForLocale('en', 50); // 0.005 ha
    expect(area.fallback, isTrue);
    expect(area.value, '50');
  });

  test('non-zh language codes take the hectare branch', () {
    // Branch condition is languageCode == 'zh'; ja (and any other code)
    // falls into the en/ha branch, formatting and degrading identically.
    final ja = formatAreaForLocale('ja', 10000);
    expect(ja.value, '1.00');
    expect(ja.fallback, isFalse);

    final jaSmall = formatAreaForLocale('ja', 50);
    expect(jaSmall.fallback, isTrue);
    expect(jaSmall.value, '50');
  });
}
