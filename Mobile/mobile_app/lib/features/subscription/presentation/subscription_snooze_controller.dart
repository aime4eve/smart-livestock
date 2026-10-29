import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NIX-334 "remind me later" for the EXPIRING_SOON banner.
///
/// A snooze is bound to (tenant, level, period end) instead of a duration:
/// it lapses by itself when the subscription crosses the next threshold
/// (14 → 7 → 3) or renews (the period end moves), so the banner never stays
/// hidden past the moment the user asked to be reminded at.
class SubscriptionSnoozeRecord {
  const SubscriptionSnoozeRecord({required this.level, required this.periodEnd});

  final int level;

  /// UTC ISO-8601 of the subscription period end the snooze was taken at;
  /// empty when the row had no expiry.
  final String periodEnd;

  static String normalizePeriodEnd(DateTime? end) =>
      end?.toUtc().toIso8601String() ?? '';

  String encode() => '$level|$periodEnd';

  static SubscriptionSnoozeRecord? decode(String? raw) {
    if (raw == null) return null;
    final sep = raw.indexOf('|');
    if (sep < 0) return null;
    final level = int.tryParse(raw.substring(0, sep));
    if (level == null) return null;
    return SubscriptionSnoozeRecord(
        level: level, periodEnd: raw.substring(sep + 1));
  }

  /// True when this record still covers the banner the user would see now.
  bool suppresses(SubscriptionHealth health, DateTime? currentPeriodEnd) {
    return health.healthStatus == 'EXPIRING_SOON' &&
        health.level == level &&
        normalizePeriodEnd(currentPeriodEnd) == periodEnd;
  }
}

class SubscriptionSnoozeController extends AsyncNotifier<SubscriptionSnoozeRecord?> {
  SubscriptionSnoozeController(this.tenantId);
  final String tenantId;

  static String prefsKey(String tenantId) =>
      'subscription_health_snooze_$tenantId';

  @override
  Future<SubscriptionSnoozeRecord?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return SubscriptionSnoozeRecord.decode(prefs.getString(prefsKey(tenantId)));
  }

  Future<void> snooze({required int level, required DateTime? periodEnd}) async {
    final record = SubscriptionSnoozeRecord(
      level: level,
      periodEnd: SubscriptionSnoozeRecord.normalizePeriodEnd(periodEnd),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey(tenantId), record.encode());
    state = AsyncData(record);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey(tenantId));
    state = const AsyncData(null);
  }
}

/// Keyed by tenant id so a device shared between tenants keeps separate snoozes.
final subscriptionSnoozeProvider = AsyncNotifierProvider.family<
    SubscriptionSnoozeController, SubscriptionSnoozeRecord?, String>(
  SubscriptionSnoozeController.new,
);
