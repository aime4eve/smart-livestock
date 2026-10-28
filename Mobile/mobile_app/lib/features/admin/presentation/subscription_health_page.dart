import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// NIX-324 admin — all-tenant subscription health overview. Urgency-sorted
/// rows from GET /admin/subscription-overview (wall-clock verdicts, same-day
/// group flag when ≥2 tenants share an expiry date, NIX-325 export window).
class SubscriptionHealthPage extends StatefulWidget {
  const SubscriptionHealthPage({super.key});

  @override
  State<SubscriptionHealthPage> createState() => _SubscriptionHealthPageState();
}

class _SubscriptionHealthPageState extends State<SubscriptionHealthPage> {
  // Spec §4.2 enum: all eight values (prototype showed six — suspended and
  // healthy were added by the spec review v1.1).
  static const _filters = [
    'all',
    'EXPIRING_SOON',
    'EXPIRED',
    'RENEWAL_FAILED',
    'CANCELLED',
    'SUSPENDED',
    'TRIAL',
    'HEALTHY',
  ];

  List<Map<String, dynamic>> _items = [];
  int _total = 0;
  String _filter = 'all';
  String _keyword = '';
  final TextEditingController _searchCtrl = TextEditingController();
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Backend params: health / keyword / size (not pageSize).
      final data = await ApiClient.instance.get(
          '/admin/subscription-overview?health=$_filter&size=100'
          '${_keyword.trim().isEmpty ? '' : '&keyword=${Uri.encodeQueryComponent(_keyword.trim())}'}');
      if (!mounted) return;
      setState(() {
        _items = (data['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        _total = data['total'] as int? ?? 0;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      key: const Key('subscription-health-page'),
      appBar: AppBar(
        title: Text(l10n.subscriptionHealthAdminTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surfaceAlt,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: SizedBox(
              height: 38,
              child: TextField(
                key: const Key('health-keyword'),
                controller: _searchCtrl,
                onSubmitted: (v) {
                  _keyword = v;
                  _load();
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.subscriptionHealthSearchHint,
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: _keyword.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            _keyword = '';
                            _load();
                          },
                        ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        key: Key('health-filter-$f'),
                        label: Text(_filterLabel(l10n, f),
                            style: const TextStyle(fontSize: 12)),
                        selected: _filter == f,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _filter == f
                              ? AppColors.surfaceAlt
                              : AppColors.textSecondary,
                        ),
                        onSelected: (_) {
                          setState(() => _filter = f);
                          _load();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, i) => _row(l10n, _items[i]),
              ),
            ),
          // Legend footer (prototype: four-colour legend + urgency note).
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: Column(
              children: [
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _legendDot(l10n.subscriptionHealthLegendHealthy,
                        const Color(0xFF4C9A5F)),
                    _legendDot(l10n.subscriptionHealthLegendExpiring,
                        const Color(0xFFD28A2D)),
                    _legendDot(l10n.subscriptionHealthLegendExpired,
                        const Color(0xFFC2564B)),
                    _legendDot(l10n.subscriptionHealthLegendRevivable,
                        const Color(0xFF4A7F9D)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.subscriptionHealthSortNote(_total),
                  key: const Key('health-total'),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _row(dynamic l10n, Map<String, dynamic> r) {
    final status = r['healthStatus'] as String? ?? '';
    final sameDay = r['sameDayGroup'] as bool? ?? false;
    final ew = r['exportWindow'];
    final days = r['daysToExpiry'];
    return Container(
      key: Key('health-row-${r['tenantId']}'),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text('${r['tenantName']}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700))),
                  if (sameDay) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.groups, size: 13, color: Color(0xFF4A7F9D)),
                  ],
                ]),
                Text('t${r['tenantId']} · ${r['tier'] ?? '-'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _pill(l10n, status),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days != null
                      ? (status == 'EXPIRING_SOON' || status == 'TRIAL'
                          ? '${days}d'
                          : '-')
                      : '-',
                  style: const TextStyle(fontSize: 12),
                ),
                if (ew != null && ew is Map<String, dynamic>)
                  Text('⬇ ${ew['daysLeft']}d',
                      key: const Key('health-export-window'),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF4A7F9D))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(dynamic l10n, String status) {
    final (bg, fg) = switch (status) {
      'EXPIRING_SOON' => (const Color(0xFFF7EDDD), const Color(0xFFD28A2D)),
      'EXPIRED' || 'CANCELLED' => (const Color(0xFFF7E5E2), const Color(0xFFC2564B)),
      'RENEWAL_FAILED' || 'TRIAL' => (const Color(0xFFE2EDF4), const Color(0xFF4A7F9D)),
      _ => (AppColors.primarySoft, AppColors.primaryDark),
    };
    // Localised label (AGENTS §4.1): never render the raw enum to users.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(_statusLabel(l10n, status),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  String _statusLabel(dynamic l10n, String status) => switch (status) {
        'EXPIRING_SOON' => l10n.subscriptionHealthFilterExpiring,
        'EXPIRED' => l10n.subscriptionHealthFilterExpired,
        'RENEWAL_FAILED' => l10n.subscriptionHealthFilterRepayment,
        'CANCELLED' => l10n.subscriptionHealthFilterCancelled,
        'SUSPENDED' => l10n.subscriptionHealthFilterSuspended,
        'TRIAL' => l10n.subscriptionHealthFilterTrial,
        'HEALTHY' => l10n.subscriptionHealthFilterHealthy,
        _ => status,
      };

  String _filterLabel(dynamic l10n, String f) => switch (f) {
        'all' => l10n.subscriptionHealthFilterAll,
        'EXPIRING_SOON' => l10n.subscriptionHealthFilterExpiring,
        'EXPIRED' => l10n.subscriptionHealthFilterExpired,
        'RENEWAL_FAILED' => l10n.subscriptionHealthFilterRepayment,
        'CANCELLED' => l10n.subscriptionHealthFilterCancelled,
        'SUSPENDED' => l10n.subscriptionHealthFilterSuspended,
        'TRIAL' => l10n.subscriptionHealthFilterTrial,
        'HEALTHY' => l10n.subscriptionHealthFilterHealthy,
        _ => f,
      };
}
