/// Farm-global alert counters from GET /alerts/summary.
///
/// Invariant (guaranteed server-side): critical + warning + info == activeTotal.
/// Unread counts are per current user.
class RanchAlertSummary {
  const RanchAlertSummary({
    required this.activeTotal,
    required this.unread,
    required this.critical,
    required this.warning,
    required this.info,
    required this.byGroup,
    required this.byGroupUnread,
    required this.resolved,
  });

  final int activeTotal;
  final int unread;
  final int critical;
  final int warning;
  final int info;
  final GroupCounts byGroup;
  final GroupCounts byGroupUnread;
  final int resolved;

  factory RanchAlertSummary.fromJson(Map<String, dynamic> m) {
    final active = m['active'] is Map<String, dynamic>
        ? m['active'] as Map<String, dynamic>
        : <String, dynamic>{};
    return RanchAlertSummary(
      activeTotal: active['total'] as int? ?? 0,
      unread: active['unread'] as int? ?? 0,
      critical: active['critical'] as int? ?? 0,
      warning: active['warning'] as int? ?? 0,
      info: active['info'] as int? ?? 0,
      byGroup: GroupCounts.fromJson(active['byGroup']),
      byGroupUnread: GroupCounts.fromJson(active['byGroupUnread']),
      resolved: m['resolved'] as int? ?? 0,
    );
  }

  /// Total unread across all type groups (ranch bottom-tab badge).
  int get unreadTotal =>
      byGroupUnread.fence + byGroupUnread.health + byGroupUnread.device;
}

/// fence = FENCE_BREACH+FENCE_APPROACH+ZONE_APPROACH,
/// health = TEMPERATURE_ABNORMAL+DIGESTIVE_ABNORMAL+ESTRUS+EPIDEMIC+AI_ANOMALY,
/// device = DEVICE_TAMPER+DEVICE_LOW_BATTERY.
class GroupCounts {
  const GroupCounts({
    this.fence = 0,
    this.health = 0,
    this.device = 0,
  });

  final int fence;
  final int health;
  final int device;

  factory GroupCounts.fromJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return const GroupCounts();
    }
    return GroupCounts(
      fence: raw['fence'] as int? ?? 0,
      health: raw['health'] as int? ?? 0,
      device: raw['device'] as int? ?? 0,
    );
  }
}
