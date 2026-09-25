class AlertWorkbenchData {
  const AlertWorkbenchData({
    required this.summary,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final WorkbenchSummary summary;
  final List<WorkbenchItem> items;
  final int page;
  final int pageSize;
  final int total;

  bool get canLoadMore => items.length < total;
}

class WorkbenchSummary {
  const WorkbenchSummary({required this.buckets, required this.assets});

  final List<WorkbenchBucket> buckets;
  final List<WorkbenchAssetCount> assets;

  int totalFor(String bucket) => buckets
      .where((item) => item.key == bucket)
      .fold(0, (sum, item) => sum + item.total);

  int unreadFor(String bucket) => buckets
      .where((item) => item.key == bucket)
      .fold(0, (sum, item) => sum + item.unread);

  int get immediate => totalFor('immediate');
  int get field => totalFor('field');
  int get observe => totalFor('observe');
  int get resolved => totalFor('resolved');
  int get activeTotal => immediate + field + observe;
  int get unreadTotal =>
      unreadFor('immediate') + unreadFor('field') + unreadFor('observe');
}

class WorkbenchBucket {
  const WorkbenchBucket({
    required this.key,
    required this.total,
    required this.unread,
  });

  final String key;
  final int total;
  final int unread;
}

class WorkbenchAssetCount {
  const WorkbenchAssetCount({
    required this.key,
    required this.total,
    required this.unread,
  });

  final String key;
  final int total;
  final int unread;
}

class WorkbenchAsset {
  const WorkbenchAsset({
    required this.kind,
    required this.id,
    required this.name,
    required this.subtitle,
  });

  final String kind;
  final String id;
  final String name;
  final String subtitle;
}

class WorkbenchReason {
  const WorkbenchReason({
    required this.alertId,
    required this.type,
    required this.severity,
    required this.message,
    required this.occurredAt,
    required this.read,
  });

  final String alertId;
  final String type;
  final String severity;
  final String message;
  final DateTime? occurredAt;
  final bool read;
}

class WorkbenchAi {
  const WorkbenchAi({
    required this.band,
    required this.findingCode,
    required this.score,
    required this.assessedAt,
  });

  final String band;
  final String findingCode;
  final double score;
  final DateTime? assessedAt;
}

class WorkbenchItem {
  const WorkbenchItem({
    required this.id,
    required this.bucket,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.unread,
    required this.occurredAt,
    required this.resolvedAt,
    required this.resolvedType,
    required this.reasons,
    required this.ai,
    required this.actions,
    required this.targetRoute,
  });

  final String id;
  final String bucket;
  final WorkbenchAsset asset;
  final String title;
  final String subtitle;
  final String severity;
  final bool unread;
  final DateTime? occurredAt;
  final DateTime? resolvedAt;
  final String? resolvedType;
  final List<WorkbenchReason> reasons;
  final WorkbenchAi? ai;
  final List<String> actions;
  final String targetRoute;

  bool get isResolved => bucket == 'resolved';
}

DateTime? _date(dynamic value) {
  final text = value is String ? value : null;
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}

WorkbenchBucket _bucket(dynamic raw, String key) {
  final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  return WorkbenchBucket(
    key: key,
    total: map['total'] as int? ?? 0,
    unread: map['unread'] as int? ?? 0,
  );
}

WorkbenchAssetCount _assetCount(dynamic raw, String key) {
  final map = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
  return WorkbenchAssetCount(
    key: key,
    total: map['total'] as int? ?? 0,
    unread: map['unread'] as int? ?? 0,
  );
}

extension AlertWorkbenchJson on AlertWorkbenchData {
  static AlertWorkbenchData fromMap(Map<String, dynamic> map) {
    final summaryMap = map['summary'] is Map<String, dynamic>
        ? map['summary'] as Map<String, dynamic>
        : <String, dynamic>{};
    final bucketRows = (summaryMap['buckets'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final assetRows = (summaryMap['assets'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    String rowKey(Map<String, dynamic> row) => row['key'] as String? ?? '';
    dynamic rowFor(List<Map<String, dynamic>> rows, String key) =>
        rows.where((row) => rowKey(row) == key).firstOrNull;
    final summary = WorkbenchSummary(
      buckets: [
        _bucket(rowFor(bucketRows, 'immediate'), 'immediate'),
        _bucket(rowFor(bucketRows, 'field'), 'field'),
        _bucket(rowFor(bucketRows, 'observe'), 'observe'),
        _bucket(rowFor(bucketRows, 'resolved'), 'resolved'),
      ],
      assets: [
        _assetCount(rowFor(assetRows, 'livestock'), 'livestock'),
        _assetCount(rowFor(assetRows, 'herd'), 'herd'),
        _assetCount(rowFor(assetRows, 'fence'), 'fence'),
        _assetCount(rowFor(assetRows, 'device'), 'device'),
      ],
    );
    final items = (map['items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_itemFromMap)
        .toList();
    return AlertWorkbenchData(
      summary: summary,
      items: items,
      page: map['page'] as int? ?? 1,
      pageSize: map['pageSize'] as int? ?? 50,
      total: map['total'] as int? ?? items.length,
    );
  }

  static WorkbenchItem _itemFromMap(Map<String, dynamic> map) {
    final asset = map['asset'] is Map<String, dynamic>
        ? map['asset'] as Map<String, dynamic>
        : <String, dynamic>{};
    final ai = map['ai'] is Map<String, dynamic> ? map['ai'] as Map<String, dynamic> : null;
    return WorkbenchItem(
      id: map['id']?.toString() ?? '',
      bucket: map['bucket'] as String? ?? 'field',
      asset: WorkbenchAsset(
        kind: asset['kind'] as String? ?? 'livestock',
        id: asset['id']?.toString() ?? '',
        name: asset['name'] as String? ?? '-',
        subtitle: asset['subtitle'] as String? ?? '',
      ),
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      severity: map['severity'] as String? ?? 'WARNING',
      unread: map['unread'] as bool? ?? false,
      occurredAt: _date(map['occurredAt']),
      resolvedAt: _date(map['resolvedAt']),
      resolvedType: map['resolvedType'] as String?,
      reasons: (map['reasons'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((reason) => WorkbenchReason(
                alertId: reason['alertId']?.toString() ?? '',
                type: reason['type'] as String? ?? '',
                severity: reason['severity'] as String? ?? 'WARNING',
                message: reason['message'] as String? ?? '',
                occurredAt: _date(reason['occurredAt']),
                read: reason['read'] as bool? ?? false,
              ))
          .toList(),
      ai: ai == null
          ? null
          : WorkbenchAi(
              band: ai['band'] as String? ?? 'calm',
              findingCode: ai['findingCode'] as String? ?? 'none',
              score: (ai['score'] as num?)?.toDouble() ?? 0,
              assessedAt: _date(ai['assessedAt']),
            ),
      actions: (map['actions'] as List? ?? []).whereType<String>().toList(),
      targetRoute: map['targetRoute'] as String? ?? '',
    );
  }
}
