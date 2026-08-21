import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/data/gps_quality_providers.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/domain/gps_quality_models.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/standard_tracks_panel.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Tab 2: Truth reference management.
/// Three category sub-tabs (NIX-68): RTK points / dynamic routes / standard
/// track lines. The first two panels are unchanged, the third is new.
class TruthReferenceTab extends ConsumerStatefulWidget {
  const TruthReferenceTab({super.key});

  @override
  ConsumerState<TruthReferenceTab> createState() => _TruthReferenceTabState();
}

enum _RtkSortField { label, location, latitude, longitude }

class _TruthReferenceTabState extends ConsumerState<TruthReferenceTab> {
  int? _selectedRouteId;
  // 0 = RTK 真值点, 1 = 动态路线, 2 = 标准轨迹 (NIX-68)
  int _subTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedLocation;
  bool _hasDefaultLocation = false;
  _RtkSortField _sortField = _RtkSortField.label;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pointsAsync = ref.watch(rtkPointsProvider);
    final routesAsync = ref.watch(dynamicRoutesProvider);
    final trackLinesAsync = ref.watch(trackLinesProvider);

    final pointCount = pointsAsync.value?.length ?? 0;
    final routeCount = routesAsync.value?.length ?? 0;
    final trackLineCount = trackLinesAsync.value?.length ?? 0;

    final subTabs = SegmentedButton<int>(
      key: const Key('truth-ref-subtabs'),
      segments: [
        ButtonSegment(
          value: 0,
          icon: const Icon(Icons.location_on, size: 16),
          label: Text(
            '${l10n.gpsQualityRtkPointList} ($pointCount)',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        ButtonSegment(
          value: 1,
          icon: const Icon(Icons.route, size: 16),
          label: Text(
            '${l10n.gpsQualityRouteList} ($routeCount)',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        ButtonSegment(
          value: 2,
          icon: const Icon(Icons.satellite_alt, size: 16),
          label: Text(
            '${l10n.gpsQualityTrackLines} ($trackLineCount)',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
      selected: {_subTab},
      onSelectionChanged: (v) => setState(() => _subTab = v.first),
      showSelectedIcon: false,
    );

    if (_subTab == 0) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            subTabs,
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _buildRtkPointsPanel(l10n, pointsAsync)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          subTabs,
          const SizedBox(height: AppSpacing.lg),
          if (_subTab == 1)
            _buildRoutesPanel(l10n, routesAsync, pointsAsync)
          else
            const StandardTracksPanel(),
        ],
      ),
    );
  }

  List<String> _locationOrder(List<RtkPoint> points) {
    final locations = <String>[];
    for (final point in points) {
      if (!locations.contains(point.locationName)) {
        locations.add(point.locationName);
      }
    }
    return locations;
  }

  String _largestLocation(List<RtkPoint> points) {
    final counts = _locationCounts(points);
    var largest = points.first.locationName;
    for (final location in _locationOrder(points)) {
      if ((counts[location] ?? 0) > (counts[largest] ?? 0)) {
        largest = location;
      }
    }
    return largest;
  }

  Map<String, int> _locationCounts(List<RtkPoint> points) {
    final counts = <String, int>{};
    for (final point in points) {
      counts.update(
        point.locationName,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return counts;
  }

  int _naturalPointNumber(String label) {
    final match = RegExp(r'\d+').firstMatch(label);
    return match == null ? 1 << 31 : int.parse(match.group(0)!);
  }

  List<RtkPoint> _visiblePoints(
    List<RtkPoint> points,
    List<String> locationOrder,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    final selectedLocation = query.isEmpty ? _selectedLocation : null;
    final visible = points.where((point) {
      final locationMatches =
          selectedLocation == null || point.locationName == selectedLocation;
      if (!locationMatches) return false;
      if (query.isEmpty) return true;
      final searchable = [
        point.locationName,
        point.pointLabel,
        point.latitude.toStringAsFixed(7),
        point.longitude.toStringAsFixed(7),
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();

    int compareLabels(RtkPoint a, RtkPoint b) {
      final aNumber = _naturalPointNumber(a.pointLabel);
      final bNumber = _naturalPointNumber(b.pointLabel);
      if (aNumber != bNumber) return aNumber.compareTo(bNumber);
      return a.pointLabel.compareTo(b.pointLabel);
    }

    visible.sort((a, b) {
      int result;
      switch (_sortField) {
        case _RtkSortField.location:
          final aLocation = locationOrder.indexOf(a.locationName);
          final bLocation = locationOrder.indexOf(b.locationName);
          result = aLocation.compareTo(bLocation);
          if (result == 0) result = compareLabels(a, b);
        case _RtkSortField.latitude:
          result = a.latitude.compareTo(b.latitude);
          if (result == 0) result = compareLabels(a, b);
        case _RtkSortField.longitude:
          result = a.longitude.compareTo(b.longitude);
          if (result == 0) result = compareLabels(a, b);
        case _RtkSortField.label:
          result = compareLabels(a, b);
      }
      return _sortAscending ? result : -result;
    });
    return visible;
  }

  // ── Left: RTK points ─────────────────────────────────────────────

  Widget _buildRtkPointsPanel(
    AppLocalizations l10n,
    AsyncValue<List<RtkPoint>> pointsAsync,
  ) {
    final points = pointsAsync.value ?? const <RtkPoint>[];
    final locationOrder = _locationOrder(points);
    if (!pointsAsync.isLoading && !_hasDefaultLocation) {
      _selectedLocation = points.isEmpty ? null : _largestLocation(points);
      _hasDefaultLocation = true;
    } else if (_selectedLocation != null &&
        !locationOrder.contains(_selectedLocation)) {
      _selectedLocation = null;
    }

    final visiblePoints = _visiblePoints(points, locationOrder);
    final isAllLocations =
        _searchQuery.trim().isNotEmpty || _selectedLocation == null;

    return RepaintBoundary(
      key: const Key('rtk-points-panel'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wideLayout = constraints.maxWidth >= 960;
          final compactHeader = constraints.maxWidth < 720;
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Color(0x14263126),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  _RtkPanelHeader(
                    title: l10n.gpsQualityRtkPointList,
                    resultCount: visiblePoints.length,
                    searchController: _searchController,
                    searchHint: l10n.gpsQualityRtkSearchHint,
                    onSearchChanged: (value) => setState(() {
                      _searchQuery = value;
                      if (value.trim().isNotEmpty) _selectedLocation = null;
                    }),
                    onAdd: () => _showCreatePointDialog(l10n),
                    addLabel: l10n.gpsQualityAddRtkPoint,
                    compact: compactHeader,
                  ),
                  Expanded(
                    child: pointsAsync.when(
                      loading: () => const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          '$e',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                      data: (points) {
                        final locationNav = _RtkLocationNav(
                          locations: locationOrder,
                          counts: _locationCounts(points),
                          pointsUnit: l10n.gpsQualityPointsUnit,
                          selectedLocation:
                              isAllLocations && _searchQuery.isNotEmpty
                              ? null
                              : _selectedLocation,
                          allLocationsLabel: l10n.gpsQualityRtkAllLocations,
                          onSelected: (location) => setState(() {
                            _selectedLocation = location;
                            _hasDefaultLocation = true;
                          }),
                          vertical: wideLayout,
                        );
                        final table = _RtkPointTable(
                          points: visiblePoints,
                          showLocation: isAllLocations,
                          compact: compactHeader,
                          sortField: _sortField,
                          sortAscending: _sortAscending,
                          onSort: (field) => setState(() {
                            if (_sortField == field) {
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortField = field;
                              _sortAscending = true;
                            }
                          }),
                          onDelete: (point) => _deletePoint(l10n, point),
                          emptyLabel: visiblePoints.isEmpty
                              ? (points.isEmpty
                                    ? l10n.gpsQualityNoData
                                    : l10n.gpsQualityRtkNoMatches)
                              : null,
                          labels: (
                            location: l10n.gpsQualityLocationName,
                            pointLabel: l10n.gpsQualityPointLabel,
                            latitude: l10n.gpsQualityLatitude,
                            longitude: l10n.gpsQualityLongitude,
                            actions: l10n.gpsQualityActions,
                          ),
                        );

                        if (wideLayout) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              locationNav,
                              Expanded(child: table),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            locationNav,
                            Expanded(child: table),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Right: Dynamic routes ────────────────────────────────────────

  Widget _buildRoutesPanel(
    AppLocalizations l10n,
    AsyncValue<List<DynamicRoute>> routesAsync,
    AsyncValue<List<RtkPoint>> pointsAsync,
  ) {
    return Card(
      key: const Key('routes-panel'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Text(
                  l10n.gpsQualityRouteList,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  key: const Key('add-route-btn'),
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  tooltip: l10n.gpsQualityAddRoute,
                  onPressed: () => _showCreateRouteDialog(l10n),
                ),
              ],
            ),
          ),
          routesAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                '$e',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
            data: (routes) {
              if (routes.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.route,
                          size: 40,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.gpsQualityNoData,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: routes
                    .map((r) => _buildRouteItem(l10n, r, pointsAsync))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteItem(
    AppLocalizations l10n,
    DynamicRoute route,
    AsyncValue<List<RtkPoint>> pointsAsync,
  ) {
    final selected = _selectedRouteId == route.id;
    final pointsAsyncVal = ref.watch(routePointsProvider(route.id));
    final rtkPoints = pointsAsync.value ?? [];

    return Container(
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: AppColors.border)),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (route.description != null)
                          Text(
                            route.description!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.danger,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _deleteRoute(l10n, route),
                  ),
                ],
              ),
            ),
          ),
          // Route point sequence (expandable)
          if (selected)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.gpsQualityRoutePoints,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        key: const Key('add-route-point-btn'),
                        icon: const Icon(Icons.add, size: 14),
                        label: Text(
                          l10n.gpsQualityAddRoutePoint,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onPressed: () =>
                            _showAddPointDialog(l10n, route.id, rtkPoints),
                      ),
                    ],
                  ),
                  pointsAsyncVal.when(
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, _) => Text(
                      '$e',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.danger,
                      ),
                    ),
                    data: (points) {
                      if (points.isEmpty) {
                        return Text(
                          l10n.gpsQualityRouteNoPoints,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        );
                      }
                      return Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: points.map((p) {
                          final rtk = rtkPoints
                              .where((r) => r.id == p.rtkPointId)
                              .firstOrNull;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    '${p.sequenceNo}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rtk != null
                                      ? '${rtk.pointLabel}·${rtk.locationName}'
                                      : '#${p.rtkPointId}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
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

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('create-point-dialog'),
        title: Text(l10n.gpsQualityAddRtkPoint),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: locCtrl,
                decoration: InputDecoration(
                  labelText: l10n.gpsQualityLocationName,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  labelText: l10n.gpsQualityPointLabel,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.gpsQualityLatitude,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: lngCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.gpsQualityLongitude,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.gpsQualityCancelSession),
          ),
          FilledButton(
            onPressed: () async {
              final lat = double.tryParse(latCtrl.text.trim());
              final lng = double.tryParse(lngCtrl.text.trim());
              if (locCtrl.text.trim().isEmpty ||
                  labelCtrl.text.trim().isEmpty ||
                  lat == null ||
                  lng == null) {
                return;
              }
              Navigator.pop(ctx);
              try {
                final success = await ref
                    .read(rtkPointsProvider.notifier)
                    .createPoint(
                      locationName: locCtrl.text.trim(),
                      pointLabel: labelCtrl.text.trim(),
                      latitude: lat,
                      longitude: lng,
                    );
                if (success && mounted) {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _selectedLocation = locCtrl.text.trim();
                    _hasDefaultLocation = true;
                  });
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            child: Text(l10n.gpsQualityAddRtkPoint),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateRouteDialog(AppLocalizations l10n) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('create-route-dialog'),
        title: Text(l10n.gpsQualityAddRoute),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.gpsQualityRouteName,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: l10n.gpsQualityRouteDescription,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.gpsQualityCancelSession),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(gpsQualityApiRepositoryProvider)
                    .createDynamicRoute(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty
                          ? null
                          : descCtrl.text.trim(),
                    );
                ref.invalidate(dynamicRoutesProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('$e')));
                }
              }
            },
            child: Text(l10n.gpsQualityAddRoute),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPointDialog(
    AppLocalizations l10n,
    int routeId,
    List<RtkPoint> rtkPoints,
  ) async {
    int? selectedPointId;
    final existing = ref.read(routePointsProvider(routeId)).value ?? [];
    final nextSeq = existing.isEmpty
        ? 1
        : existing.map((p) => p.sequenceNo).reduce((a, b) => a > b ? a : b) + 1;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          key: const Key('add-route-point-dialog'),
          title: Text(l10n.gpsQualityAddRoutePoint),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: l10n.gpsQualitySelectRtkPoint,
                  ),
                  initialValue: selectedPointId,
                  items: rtkPoints
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.locationName}·${p.pointLabel}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setS(() => selectedPointId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.gpsQualityCancelSession),
            ),
            FilledButton(
              onPressed: selectedPointId == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      final current =
                          ref.read(routePointsProvider(routeId)).value ?? [];
                      final updated = [
                        ...current.map(
                          (p) => (
                            rtkPointId: p.rtkPointId,
                            sequenceNo: p.sequenceNo,
                          ),
                        ),
                        (rtkPointId: selectedPointId!, sequenceNo: nextSeq),
                      ]..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
                      try {
                        await ref
                            .read(gpsQualityApiRepositoryProvider)
                            .replaceRoutePoints(routeId, updated);
                        ref.invalidate(routePointsProvider(routeId));
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
              child: Text(l10n.gpsQualityAddRoutePoint),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete actions ───────────────────────────────────────────────

  Future<void> _deletePoint(AppLocalizations l10n, RtkPoint p) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.gpsQualityDelete),
            content: Text('${p.pointLabel}·${p.locationName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.gpsQualityCancelSession),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                key: const Key('confirm-delete-rtk-point'),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.gpsQualityDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await ref.read(rtkPointsProvider.notifier).deletePoint(p.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _deleteRoute(AppLocalizations l10n, DynamicRoute route) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.gpsQualityDeleteRoute),
            content: Text('${route.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.gpsQualityCancelSession),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.gpsQualityDelete),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await ref
          .read(gpsQualityApiRepositoryProvider)
          .deleteDynamicRoute(route.id);
      ref.invalidate(dynamicRoutesProvider);
      if (_selectedRouteId == route.id) setState(() => _selectedRouteId = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _RtkPanelHeader extends StatelessWidget {
  const _RtkPanelHeader({
    required this.title,
    required this.resultCount,
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    required this.onAdd,
    required this.addLabel,
    required this.compact,
  });

  final String title;
  final int resultCount;
  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;
  final String addLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final searchField = TextField(
      key: const Key('rtk-point-search-field'),
      controller: searchController,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: searchHint,
        hintStyle: const TextStyle(fontSize: 13),
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        prefixIcon: const Icon(Icons.search, size: 16),
        prefixIconConstraints: const BoxConstraints(minWidth: 34),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      onChanged: onSearchChanged,
    );

    final addButton = FilledButton.icon(
      key: const Key('add-rtk-point-btn'),
      onPressed: onAdd,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      icon: const Icon(Icons.add, size: 16),
      label: Text(addLabel),
    );

    Widget content;
    if (compact) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ResultCount(count: resultCount),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: AppSpacing.sm),
              addButton,
            ],
          ),
        ],
      );
    } else {
      content = Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ResultCount(count: resultCount),
          const Spacer(),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: searchField,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          addButton,
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: content,
    );
  }
}

class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 38),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _RtkLocationNav extends StatelessWidget {
  const _RtkLocationNav({
    required this.locations,
    required this.counts,
    required this.pointsUnit,
    required this.selectedLocation,
    required this.allLocationsLabel,
    required this.onSelected,
    required this.vertical,
  });

  final List<String> locations;
  final Map<String, int> counts;
  final String pointsUnit;
  final String? selectedLocation;
  final String allLocationsLabel;
  final ValueChanged<String?> onSelected;
  final bool vertical;

  Widget _option({required String? location, required int count}) {
    final selected = location == selectedLocation;
    final label = location ?? allLocationsLabel;
    final child = Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: vertical ? null : Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$count $pointsUnit',
            style: TextStyle(
              fontSize: 12,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: vertical ? 2 : 0,
        right: vertical ? 0 : AppSpacing.sm,
      ),
      child: InkWell(
        key: ValueKey('rtk-location-${location ?? '__all__'}'),
        onTap: () => onSelected(location),
        borderRadius: BorderRadius.circular(6),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      _option(location: null, count: counts.values.fold(0, (a, b) => a + b)),
      for (final location in locations)
        _option(location: location, count: counts[location] ?? 0),
    ];

    if (vertical) {
      return Container(
        key: const Key('rtk-location-nav'),
        width: 236,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppColors.border)),
        ),
        child: SingleChildScrollView(child: Column(children: options)),
      );
    }

    return Container(
      key: const Key('rtk-location-nav'),
      height: 52,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: options),
      ),
    );
  }
}

class _RtkPointTable extends StatelessWidget {
  const _RtkPointTable({
    required this.points,
    required this.showLocation,
    required this.compact,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onDelete,
    required this.emptyLabel,
    required this.labels,
  });

  final List<RtkPoint> points;
  final bool showLocation;
  final bool compact;
  final _RtkSortField sortField;
  final bool sortAscending;
  final ValueChanged<_RtkSortField> onSort;
  final ValueChanged<RtkPoint> onDelete;
  final String? emptyLabel;
  final ({
    String location,
    String pointLabel,
    String latitude,
    String longitude,
    String actions,
  })
  labels;

  Widget _headerCell({
    required String label,
    required double width,
    _RtkSortField? field,
    bool alignEnd = false,
  }) {
    final active = field != null && field == sortField;
    final content = Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
        if (active) ...[
          const SizedBox(width: 4),
          Icon(
            sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14,
            color: AppColors.primary,
          ),
        ],
      ],
    );

    Widget cell = Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
      alignment: Alignment.centerLeft,
      child: field == null
          ? Container(
              alignment: Alignment.centerRight,
              width: 28,
              child: content,
            )
          : content,
    );

    if (field == null) return cell;
    return InkWell(
      key: ValueKey('rtk-sort-${field.name}'),
      onTap: () => onSort(field),
      child: cell,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = compact ? 620.0 : 680.0;
        final width = constraints.maxWidth < minWidth
            ? minWidth
            : constraints.maxWidth;
        // These ratios mirror the prototype browser table's automatic layout.
        const actionWidth = 56.0;
        final flexibleWidth = width - actionWidth;
        final pointWidth = showLocation
            ? flexibleWidth * 0.1897
            : flexibleWidth * 0.2791;
        final locationWidth = flexibleWidth * 0.3201;
        final coordinateWidth = showLocation
            ? flexibleWidth * 0.2451
            : flexibleWidth * 0.36045;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            key: const Key('rtk-points-table'),
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceAlt,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      _headerCell(
                        label: labels.pointLabel,
                        width: pointWidth,
                        field: _RtkSortField.label,
                      ),
                      if (showLocation)
                        _headerCell(
                          label: labels.location,
                          width: locationWidth,
                          field: _RtkSortField.location,
                        ),
                      _headerCell(
                        label: labels.latitude,
                        width: coordinateWidth,
                        field: _RtkSortField.latitude,
                      ),
                      _headerCell(
                        label: labels.longitude,
                        width: coordinateWidth,
                        field: _RtkSortField.longitude,
                      ),
                      _headerCell(label: labels.actions, width: actionWidth),
                    ],
                  ),
                ),
                Expanded(
                  child: emptyLabel == null
                      ? ListView.builder(
                          itemCount: points.length,
                          itemBuilder: (context, index) => _RtkPointRow(
                            key: ValueKey('point-${points[index].id}'),
                            point: points[index],
                            showLocation: showLocation,
                            compact: compact,
                            pointWidth: pointWidth,
                            locationWidth: locationWidth,
                            coordinateWidth: coordinateWidth,
                            actionWidth: actionWidth,
                            showBottomBorder: index != points.length - 1,
                            onDelete: onDelete,
                          ),
                        )
                      : _RtkEmptyState(label: emptyLabel!),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RtkPointRow extends StatefulWidget {
  const _RtkPointRow({
    super.key,
    required this.point,
    required this.showLocation,
    required this.compact,
    required this.pointWidth,
    required this.locationWidth,
    required this.coordinateWidth,
    required this.actionWidth,
    required this.showBottomBorder,
    required this.onDelete,
  });

  final RtkPoint point;
  final bool showLocation;
  final bool compact;
  final double pointWidth;
  final double locationWidth;
  final double coordinateWidth;
  final double actionWidth;
  final bool showBottomBorder;
  final ValueChanged<RtkPoint> onDelete;

  @override
  State<_RtkPointRow> createState() => _RtkPointRowState();
}

class _RtkPointRowState extends State<_RtkPointRow> {
  static const Color _rowHover = Color(0xFFFBFAF6);

  bool _hovered = false;

  Widget _cell({required Widget child, required double width}) => Container(
    width: width,
    padding: EdgeInsets.symmetric(horizontal: widget.compact ? 10 : 16),
    alignment: Alignment.centerLeft,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _hovered ? _rowHover : Colors.transparent,
          border: widget.showBottomBorder
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              _cell(
                width: widget.pointWidth,
                child: Text(
                  widget.point.pointLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.showLocation)
                _cell(
                  width: widget.locationWidth,
                  child: Text(
                    widget.point.locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              _cell(
                width: widget.coordinateWidth,
                child: Text(
                  widget.point.latitude.toStringAsFixed(7),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _cell(
                width: widget.coordinateWidth,
                child: Text(
                  widget.point.longitude.toStringAsFixed(7),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                width: widget.actionWidth,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: ValueKey('delete-rtk-point-${widget.point.id}'),
                  onPressed: () => widget.onDelete(widget.point),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: AppColors.textSecondary,
                  constraints: const BoxConstraints.tightFor(
                    width: 28,
                    height: 28,
                  ),
                  padding: EdgeInsets.zero,
                  style: const ButtonStyle(
                    overlayColor: WidgetStatePropertyAll(AppColors.dangerSoft),
                    foregroundColor: WidgetStatePropertyAll(
                      AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RtkEmptyState extends StatelessWidget {
  const _RtkEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
