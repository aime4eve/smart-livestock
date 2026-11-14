import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/utils/app_time.dart';
import 'package:hkt_livestock_agentic/core/utils/timezone_options.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:hkt_livestock_agentic/app/session/session_controller.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/map/coord_transform.dart';
import 'package:hkt_livestock_agentic/core/map/map_config.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_provider.dart';
import 'package:hkt_livestock_agentic/core/map/smart_tile_factory.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/farm_switcher/farm_switcher_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';

class WizardStepBasicInfo extends ConsumerStatefulWidget {
  const WizardStepBasicInfo({
    super.key,
    required this.onComplete,
  });

  final void Function(String farmId, String farmName, LatLng center) onComplete;

  @override
  ConsumerState<WizardStepBasicInfo> createState() =>
      _WizardStepBasicInfoState();
}

class _WizardStepBasicInfoState extends ConsumerState<WizardStepBasicInfo> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _mapController = MapController();

  /// NIX-189/237: canonical WGS-84 at all times. Taps land in screen space
  /// (GCJ-02 under 高德 tiles) and are inverse-converted via [_toWgs84];
  /// display goes through [_displayCenter]. Storing GCJ here used to shift
  /// the whole farm ~500 m.
  LatLng _selectedCenter = MapConfig.defaultCenter;
  bool _submitting = false;
  late String? _timezone = optionForOffset(activeTzOffsetMinutes())?.name;
  SmartTileProvider? _tileProvider;
  bool _tileProviderInitialized = false;

  @override
  void initState() {
    super.initState();
    // 已有牧场的用户再建新牧场时，默认锚定当前牧场位置而非演示默认点
    final center = ref.read(farmSwitcherControllerProvider).activeFarmCenter;
    if (center != null) _selectedCenter = center;
  }

  @override
  void dispose() {
    _tileProvider?.dispose();
    _nameController.dispose();
    _areaController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initTileProvider() async {
    _tileProvider = await loadSmartTileProvider(
      ref,
      onSourceChanged: () { if (mounted) setState(() {}); },
    );
    if (mounted) setState(() {});
  }

  /// NIX-237: whether the tiles actually serving [mapPoint] are GCJ-02.
  /// [mapPoint] must be a value in the map's own fed space — flutter_map
  /// derives the tile it renders from exactly that value, so the check must
  /// use it raw (local mbtiles / server OSM tiles are WGS-84 and suppress
  /// the transform even when the online source is 高德).
  bool _tilesAreGcj02(LatLng mapPoint) =>
      _tileProvider?.shouldTransformAt(mapPoint) ?? false;

  /// Screen tap (the map's fed space) → canonical WGS-84 (NIX-189/237).
  LatLng _toWgs84(LatLng screenPoint) => _tilesAreGcj02(screenPoint)
      ? CoordTransform.gcj02ToWgs84(screenPoint)
      : screenPoint;

  /// [_selectedCenter] (WGS-84) → screen coordinates for marker/center
  /// display. The decision probes the transformed candidate, because that
  /// is the value the map would project to pick its tiles.
  LatLng get _displayCenter {
    final candidate = CoordTransform.wgs84ToGcj02(_selectedCenter);
    return _tilesAreGcj02(candidate) ? candidate : _selectedCenter;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _submitting = true);

    final areaText = _areaController.text.trim();
    final area = areaText.isEmpty ? null : double.tryParse(areaText);

    try {
      final data = await ApiClient.instance.post(
        '/farms',
        body: {
          'name': _nameController.text.trim(),
          'latitude': _selectedCenter.latitude,
          'longitude': _selectedCenter.longitude,
          if (area != null) 'areaHectares': area,
          if (_timezone != null) 'timezone': _timezone,
        },
      );

      if (!mounted) return;

      final rawId = data['id'];
      final farmId = rawId is int ? rawId.toString() : (rawId as String? ?? '');
      if (farmId.isEmpty) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.wizardCreateFailedNoId)),
        );
        return;
      }

      ref.read(sessionControllerProvider.notifier).updateActiveFarm(farmId);
      widget.onComplete(farmId, _nameController.text.trim(), _selectedCenter);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.wizardCreateFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_tileProviderInitialized) {
      _tileProviderInitialized = true;
      _initTileProvider();
    }
    return SingleChildScrollView(
      key: const Key('farm-creation-step1'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '基本信息',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '填写牧场名称并在地图上点击选择牧场中心位置。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('farm-creation-name'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '牧场名称',
                hintText: '例如：阳光牧场',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请输入牧场名称' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('farm-creation-area'),
              controller: _areaController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '面积（公顷）',
                hintText: '选填，例如：120.5',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              key: const Key('farm-creation-timezone'),
              initialValue: _timezone,
              decoration: const InputDecoration(
                labelText: '所在时区（选填）',
                helperText: '留空跟随租户/平台默认；影响牧场的时间显示与按日统计',
                border: OutlineInputBorder(),
              ),
              items: [
                null,
                ...kTimezoneOptions.map((o) => o.name),
              ].map((tz) => DropdownMenuItem<String>(
                    value: tz,
                    child: Text(tz == null
                        ? '自动（跟随租户）'
                        : kTimezoneOptions
                            .firstWhere((o) => o.name == tz,
                                orElse: () => TimezoneOption(tz, 0, tz))
                            .label),
                  )).toList(),
              onChanged: (v) => setState(() => _timezone = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '牧场中心位置（点击地图选择）',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.md),
              child: SizedBox(
                key: const Key('farm-creation-map'),
                height: 260,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _displayCenter,
                    initialZoom: 13.0,
                    onTap: (tapPosition, point) {
                      if (!mounted) return;
                      setState(() => _selectedCenter = _toWgs84(point));
                    },
                  ),
                  children: [
                    TileLayer(
                      key: ValueKey(_tileProvider?.activeSourceName),
                      urlTemplate: _tileProvider == null ? MapConfig.tileUrlTemplate : null,
                      tileProvider: _tileProvider,
                      userAgentPackageName: 'com.smartlivestock.demo',
                      maxZoom: MapConfig.cacheMaxZoom.toDouble(),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          key: const Key('farm-creation-center-marker'),
                          point: _displayCenter,
                          width: 32,
                          height: 32,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // WGS-84 canonical values — the same numbers the farm is
            // registered with (NIX-189: the label used to show raw screen
            // coordinates, GCJ-02 under 高德).
            Text(
              '纬度：${_selectedCenter.latitude.toStringAsFixed(6)}，'
              '经度：${_selectedCenter.longitude.toStringAsFixed(6)}',
              key: const Key('farm-creation-coords'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              key: const Key('farm-creation-submit'),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.wizardNextStep),
            ),
          ],
        ),
      ),
    );
  }
}
