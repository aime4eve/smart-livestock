import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Tab 2: Truth reference management.
/// Left panel: RTK reference points CRUD.
/// Right panel: Dynamic test routes CRUD + point sequence.
class TruthReferenceTab extends ConsumerStatefulWidget {
  const TruthReferenceTab({super.key});

  @override
  ConsumerState<TruthReferenceTab> createState() => _TruthReferenceTabState();
}

class _TruthReferenceTabState extends ConsumerState<TruthReferenceTab> {
  int? _selectedRouteId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pointsAsync = ref.watch(rtkPointsProvider);
    final routesAsync = ref.watch(dynamicRoutesProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final left = _buildRtkPointsPanel(l10n, pointsAsync);
        final right = _buildRoutesPanel(l10n, routesAsync, pointsAsync);
        if (wide) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 380, child: SingleChildScrollView(child: left)),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: SingleChildScrollView(child: right)),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(children: [
            left, const SizedBox(height: AppSpacing.lg), right,
          ]),
        );
      },
    );
  }

  // ── Left: RTK points ─────────────────────────────────────────────

  Widget _buildRtkPointsPanel(AppLocalizations l10n, AsyncValue<List<RtkPoint>> pointsAsync) {
    return Card(
      key: const Key('rtk-points-panel'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Text(l10n.gpsQualityRtkPointList, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              key: const Key('add-rtk-point-btn'),
              icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
              tooltip: l10n.gpsQualityAddRtkPoint,
              onPressed: () => _showCreatePointDialog(l10n),
            ),
          ]),
        ),
        pointsAsync.when(
          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('$e', style: const TextStyle(color: AppColors.danger))),
          data: (points) {
            // Group by location name
            final grouped = <String, List<RtkPoint>>{};
            for (final p in points) {
              grouped.putIfAbsent(p.locationName, () => []).add(p);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: grouped.entries.map((entry) {
                return ExpansionTile(
                  key: ValueKey('loc-${entry.key}'),
                  dense: true,
                  title: Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('${entry.value.length} 个点位', style: const TextStyle(fontSize: 11)),
                  initiallyExpanded: true,
                  children: entry.value.map((p) => _buildPointItem(l10n, p)).toList(),
                );
              }).toList(),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildPointItem(AppLocalizations l10n, RtkPoint p) {
    return ListTile(
      dense: true,
      key: ValueKey('point-${p.id}'),
      title: Text(p.pointLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text('${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace')),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
        visualDensity: VisualDensity.compact,
        onPressed: () => _deletePoint(l10n, p),
      ),
    );
  }

  // ── Right: Dynamic routes ────────────────────────────────────────

  Widget _buildRoutesPanel(AppLocalizations l10n, AsyncValue<List<DynamicRoute>> routesAsync,
      AsyncValue<List<RtkPoint>> pointsAsync) {
    return Card(
      key: const Key('routes-panel'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Text(l10n.gpsQualityRouteList, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              key: const Key('add-route-btn'),
              icon: const Icon(Icons.add, color: AppColors.primary, size: 20),
              tooltip: l10n.gpsQualityAddRoute,
              onPressed: () => _showCreateRouteDialog(l10n),
            ),
          ]),
        ),
        routesAsync.when(
          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(AppSpacing.md),
            child: Text('$e', style: const TextStyle(color: AppColors.danger))),
          data: (routes) {
            if (routes.isEmpty) {
              return Padding(padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.route, size: 40, color: AppColors.textSecondary),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.gpsQualityNoData, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ])));
            }
            return Column(
              children: routes.map((r) => _buildRouteItem(l10n, r, pointsAsync)).toList(),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildRouteItem(AppLocalizations l10n, DynamicRoute route, AsyncValue<List<RtkPoint>> pointsAsync) {
    final selected = _selectedRouteId == route.id;
    final pointsAsyncVal = ref.watch(routePointsProvider(route.id));
    final rtkPoints = pointsAsync.value ?? [];

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
        color: selected ? AppColors.primarySoft : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: ValueKey('route-${route.id}'),
            onTap: () => setState(() {
              _selectedRouteId = selected ? null : route.id;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(route.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (route.description != null)
                    Text(route.description!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _deleteRoute(l10n, route),
                ),
              ]),
            ),
          ),
          // Route point sequence (expandable)
          if (selected)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(l10n.gpsQualityRoutePoints,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const Spacer(),
                  TextButton.icon(
                    key: const Key('add-route-point-btn'),
                    icon: const Icon(Icons.add, size: 14),
                    label: Text(l10n.gpsQualityAddRoutePoint, style: const TextStyle(fontSize: 11)),
                    onPressed: () => _showAddPointDialog(l10n, route.id, rtkPoints),
                  ),
                ]),
                pointsAsyncVal.when(
                  loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (e, _) => Text('$e', style: const TextStyle(fontSize: 11, color: AppColors.danger)),
                  data: (points) {
                    if (points.isEmpty) {
                      return Text(l10n.gpsQualityRouteNoPoints,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary));
                    }
                    return Wrap(spacing: 4, runSpacing: 4, children: points.map((p) {
                      final rtk = rtkPoints.where((r) => r.id == p.rtkPointId).firstOrNull;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 18, height: 18, alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(9)),
                            child: Text('${p.sequenceNo}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
                          const SizedBox(width: 4),
                          Text(rtk != null ? '${rtk.pointLabel}·${rtk.locationName}' : '#${p.rtkPointId}',
                            style: const TextStyle(fontSize: 11)),
                        ]),
                      );
                    }).toList());
                  },
                ),
              ]),
            ),
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────────────────────────────

  Future<void> _showCreatePointDialog(AppLocalizations l10n) async {
    final locCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      key: const Key('create-point-dialog'),
      title: Text(l10n.gpsQualityAddRtkPoint),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: locCtrl, decoration: InputDecoration(labelText: l10n.gpsQualityLocationName)),
        const SizedBox(height: AppSpacing.sm),
        TextField(controller: labelCtrl, decoration: InputDecoration(labelText: l10n.gpsQualityPointLabel)),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Expanded(child: TextField(controller: latCtrl, decoration: InputDecoration(labelText: l10n.gpsQualityLatitude),
            keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: TextField(controller: lngCtrl, decoration: InputDecoration(labelText: l10n.gpsQualityLongitude),
            keyboardType: const TextInputType.numberWithOptions(decimal: true))),
        ]),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.gpsQualityCancelSession)),
        FilledButton(
          onPressed: () async {
            final lat = double.tryParse(latCtrl.text.trim());
            final lng = double.tryParse(lngCtrl.text.trim());
            if (locCtrl.text.trim().isEmpty || labelCtrl.text.trim().isEmpty || lat == null || lng == null) return;
            Navigator.pop(ctx);
            try {
              await ref.read(rtkPointsProvider.notifier).createPoint(
                locationName: locCtrl.text.trim(), pointLabel: labelCtrl.text.trim(),
                latitude: lat, longitude: lng);
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
            }
          },
          child: Text(l10n.gpsQualityAddRtkPoint),
        ),
      ],
    ));
  }

  Future<void> _showCreateRouteDialog(AppLocalizations l10n) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      key: const Key('create-route-dialog'),
      title: Text(l10n.gpsQualityAddRoute),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: InputDecoration(labelText: l10n.gpsQualityRouteName)),
        const SizedBox(height: AppSpacing.sm),
        TextField(controller: descCtrl, decoration: InputDecoration(labelText: l10n.gpsQualityRouteDescription), maxLines: 2),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.gpsQualityCancelSession)),
        FilledButton(
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            Navigator.pop(ctx);
            try {
              await ref.read(gpsQualityApiRepositoryProvider).createDynamicRoute(name: nameCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim());
              ref.invalidate(dynamicRoutesProvider);
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
            }
          },
          child: Text(l10n.gpsQualityAddRoute),
        ),
      ],
    ));
  }

  Future<void> _showAddPointDialog(AppLocalizations l10n, int routeId, List<RtkPoint> rtkPoints) async {
    int? selectedPointId;
    final existing = ref.read(routePointsProvider(routeId)).value ?? [];
    final nextSeq = existing.isEmpty ? 1 : existing.map((p) => p.sequenceNo).reduce((a, b) => a > b ? a : b) + 1;

    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      key: const Key('add-route-point-dialog'),
      title: Text(l10n.gpsQualityAddRoutePoint),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(
          decoration: InputDecoration(labelText: l10n.gpsQualitySelectRtkPoint),
          value: selectedPointId,
          items: rtkPoints.map((p) => DropdownMenuItem(value: p.id,
            child: Text('${p.locationName}·${p.pointLabel}', style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) => setS(() => selectedPointId = v),
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.gpsQualityCancelSession)),
        FilledButton(
          onPressed: selectedPointId == null ? null : () async {
            Navigator.pop(ctx);
            final current = ref.read(routePointsProvider(routeId)).value ?? [];
            final updated = [
              ...current.map((p) => (rtkPointId: p.rtkPointId, sequenceNo: p.sequenceNo)),
              (rtkPointId: selectedPointId!, sequenceNo: nextSeq),
            ]..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
            try {
              await ref.read(gpsQualityApiRepositoryProvider).replaceRoutePoints(routeId, updated);
              ref.invalidate(routePointsProvider(routeId));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
            }
          },
          child: Text(l10n.gpsQualityAddRoutePoint),
        ),
      ],
    )));
  }

  // ── Delete actions ───────────────────────────────────────────────

  Future<void> _deletePoint(AppLocalizations l10n, RtkPoint p) async {
    final ok = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.gpsQualityDelete),
        content: Text('${p.pointLabel}·${p.locationName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.gpsQualityCancelSession)),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.gpsQualityDelete)),
        ])) ?? false;
    if (!ok) return;
    try {
      await ref.read(rtkPointsProvider.notifier).deletePoint(p.id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteRoute(AppLocalizations l10n, DynamicRoute route) async {
    final ok = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.gpsQualityDeleteRoute),
        content: Text('${route.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.gpsQualityCancelSession)),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.gpsQualityDelete)),
        ])) ?? false;
    if (!ok) return;
    try {
      await ref.read(gpsQualityApiRepositoryProvider).deleteDynamicRoute(route.id);
      ref.invalidate(dynamicRoutesProvider);
      if (_selectedRouteId == route.id) setState(() => _selectedRouteId = null);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
