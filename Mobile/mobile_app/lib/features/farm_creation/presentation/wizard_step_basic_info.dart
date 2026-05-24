import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/map/map_config.dart';
import 'package:smart_livestock_demo/core/map/mbtiles_tile_provider.dart';
import 'package:smart_livestock_demo/core/map/smart_tile_provider.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class WizardStepBasicInfo extends ConsumerStatefulWidget {
  const WizardStepBasicInfo({
    super.key,
    required this.onComplete,
  });

  final void Function(String farmId, String farmName) onComplete;

  @override
  ConsumerState<WizardStepBasicInfo> createState() =>
      _WizardStepBasicInfoState();
}

class _WizardStepBasicInfoState extends ConsumerState<WizardStepBasicInfo> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _mapController = MapController();
  LatLng _selectedCenter = MapConfig.defaultCenter;
  bool _submitting = false;
  SmartTileProvider? _tileProvider;
  bool _tileProviderInitialized = false;

  @override
  void dispose() {
    _tileProvider?.dispose();
    _nameController.dispose();
    _areaController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initTileProvider() async {
    MBTilesTileProvider? mbtiles;
    if (!kIsWeb) {
      mbtiles = await MBTilesTileProvider.fromAsset();
    }
    final region = const String.fromEnvironment('REGION', defaultValue: 'china');
    final isChina = region == 'china';
    _tileProvider = await SmartTileProvider.create(
      selfHostedTileUrl: MapConfig.selfHostedTileUrl,
      mbtilesProvider: mbtiles,
      fallbackUrl: isChina ? MapConfig.chinaFallbackUrl : MapConfig.overseasFallbackUrl,
      isGcj02Fallback: isChina,
      onSourceChanged: () { if (mounted) setState(() {}); },
    );
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    setState(() => _submitting = true);

    final session = ref.read(sessionControllerProvider);
    final cache = ApiCache.instance;
    final tokens = session.accessToken != null
        ? ApiAuthTokens(accessToken: session.accessToken!)
        : null;

    final areaText = _areaController.text.trim();
    final area = areaText.isEmpty ? 0.0 : double.tryParse(areaText) ?? 0.0;

    final success = await cache.createFarmRemote(
      session.role?.wireName ?? 'owner',
      name: _nameController.text.trim(),
      latitude: _selectedCenter.latitude,
      longitude: _selectedCenter.longitude,
      areaHectares: area,
      tokens: tokens,
    );

    if (!mounted) return;

    if (success) {
      final farmId = cache.activeFarmId ?? '';
      if (farmId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('创建牧场失败：未获取到牧场ID')),
          );
        }
        return;
      }
      widget.onComplete(farmId, _nameController.text.trim());
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('创建牧场失败，请重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    initialCenter: MapConfig.defaultCenter,
                    initialZoom: 13.0,
                    onTap: (tapPosition, point) {
                      if (!mounted) return;
                      setState(() => _selectedCenter = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _tileProvider == null ? MapConfig.tileUrlTemplate : null,
                      tileProvider: _tileProvider,
                      userAgentPackageName: 'com.smartlivestock.demo',
                      maxZoom: MapConfig.cacheMaxZoom.toDouble(),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          key: const Key('farm-creation-center-marker'),
                          point: _selectedCenter,
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
                  : const Text('下一步'),
            ),
          ],
        ),
      ),
    );
  }
}
