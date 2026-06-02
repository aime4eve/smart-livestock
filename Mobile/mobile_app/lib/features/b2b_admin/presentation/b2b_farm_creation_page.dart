import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/core/map/map_config.dart';
import 'package:smart_livestock_demo/core/map/coord_transform.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/domain/b2b_repository.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';

class _TileRegion {
  final int id;
  final String name;
  final LatLng center;
  final double minLon, minLat, maxLon, maxLat;
  final int fileSize;
  final String status;

  _TileRegion({
    required this.id,
    required this.name,
    required this.center,
    required this.minLon,
    required this.minLat,
    required this.maxLon,
    required this.maxLat,
    required this.fileSize,
    required this.status,
  });

  factory _TileRegion.fromMap(Map<String, dynamic> m) {
    return _TileRegion(
      id: m['id'] as int,
      name: m['name'] as String,
      center: LatLng(
        ((m['minLat'] as num) + (m['maxLat'] as num)) / 2,
        ((m['minLon'] as num) + (m['maxLon'] as num)) / 2,
      ),
      minLon: (m['minLon'] as num).toDouble(),
      minLat: (m['minLat'] as num).toDouble(),
      maxLon: (m['maxLon'] as num).toDouble(),
      maxLat: (m['maxLat'] as num).toDouble(),
      fileSize: m['fileSize'] as int? ?? 0,
      status: m['status'] as String? ?? 'unknown',
    );
  }

  String get fileSizeLabel {
    final mb = fileSize / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

final _tileRegionsProvider =
    FutureProvider.autoDispose<List<_TileRegion>>((ref) async {
  final data = await ApiClient.instance.get('/admin/tiles/regions');
  final rawItems = data['value'] ?? data['items'] ?? [];
  final items = (rawItems as List).cast<Map<String, dynamic>>();
  return items.map((m) => _TileRegion.fromMap(m)).toList();
});

class B2bFarmCreationPage extends ConsumerStatefulWidget {
  const B2bFarmCreationPage({super.key});

  @override
  ConsumerState<B2bFarmCreationPage> createState() =>
      _B2bFarmCreationPageState();
}

class _B2bFarmCreationPageState extends ConsumerState<B2bFarmCreationPage> {
  _TileRegion? _selectedRegion;
  LatLng? _pickedPoint;
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  B2bUserSummary? _selectedOwner;
  bool _creating = false;
  final _mapController = MapController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  void _onRegionSelected(_TileRegion region) {
    final center = region.center;
    setState(() {
      _selectedRegion = region;
      _pickedPoint = center;
      _latCtrl.text = center.latitude.toStringAsFixed(6);
      _lngCtrl.text = center.longitude.toStringAsFixed(6);
    });
    _mapController.move(CoordTransform.wgs84ToGcj02(center), 13);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    final wgs84 = CoordTransform.gcj02ToWgs84(point);
    setState(() {
      _pickedPoint = wgs84;
      _latCtrl.text = wgs84.latitude.toStringAsFixed(6);
      _lngCtrl.text = wgs84.longitude.toStringAsFixed(6);
    });
  }

  void _onCoordChanged() {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat != null && lng != null) {
      setState(() => _pickedPoint = LatLng(lat, lng));
    }
  }

  Future<void> _handleCreate() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入牧场名称')),
      );
      return;
    }
    if (_pickedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请在地图上选点或输入经纬度')),
      );
      return;
    }

    setState(() => _creating = true);

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'latitude': _pickedPoint!.latitude,
      'longitude': _pickedPoint!.longitude,
      if (_selectedOwner != null) 'ownerId': _selectedOwner!.id,
      if (_areaCtrl.text.isNotEmpty)
        'areaHectares': double.tryParse(_areaCtrl.text),
    };

    final ok = await ref
        .read(b2bDashboardControllerProvider.notifier)
        .createFarm(body);

    if (!mounted) return;
    setState(() => _creating = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('牧场「${_nameCtrl.text.trim()}」创建成功'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('创建失败，请重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final regionsAsync = ref.watch(_tileRegionsProvider);
    final ownerUsers = ref.watch(b2bOwnerUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('新建牧场'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: FilledButton(
              onPressed: _creating ? null : _handleCreate,
              child: _creating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('创建牧场'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Step 1: Select tile region ──
                _stepHeader('1', '选择瓦片区域'),
                const SizedBox(height: AppSpacing.sm),
                regionsAsync.when(
                  data: (regions) {
                    final readyRegions =
                        regions.where((r) => r.status == 'ready').toList();
                    return _regionDropdown(readyRegions, theme);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('加载失败: $e',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Step 2: Map ──
                _stepHeader('2', '在地图上选择牧场位置'),
                const SizedBox(height: 4),
                Text(
                  '点击地图选点，或手动修改下方坐标',
                  style: TextStyle(
                      fontSize: 12, color: theme.hintColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                _mapSection(theme),
                const SizedBox(height: AppSpacing.sm),

                // Coordinate inputs
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        decoration: const InputDecoration(
                          labelText: '纬度 (WGS-84)',
                          hintText: '选区域后自动填充',
                          isDense: true,
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.my_location, size: 18),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => _onCoordChanged(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        decoration: const InputDecoration(
                          labelText: '经度 (WGS-84)',
                          hintText: '选区域后自动填充',
                          isDense: true,
                          border: OutlineInputBorder(),
                          prefixIcon:
                              Icon(Icons.explore, size: 18),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => _onCoordChanged(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Step 3: Farm info ──
                _stepHeader('3', '牧场信息'),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '牧场名称 *',
                    hintText: '请输入牧场名称',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ownerUsers.when(
                  data: (users) =>
                      DropdownButtonFormField<B2bUserSummary?>(
                    decoration: const InputDecoration(
                      labelText: '负责人',
                      hintText: '选择 owner（可选）',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<B2bUserSummary?>(
                        value: null,
                        child: Text('— 暂不指定 —'),
                      ),
                      ...users.map((u) =>
                          DropdownMenuItem<B2bUserSummary?>(
                            value: u,
                            child: Text('${u.name} (${u.phone})'),
                          )),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedOwner = v),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('加载用户列表失败'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaCtrl,
                  decoration: const InputDecoration(
                    labelText: '面积（公顷）',
                    hintText: '选填',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepHeader(String number, String title) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _regionDropdown(List<_TileRegion> regions, ThemeData theme) {
    return DropdownButtonFormField<_TileRegion>(
      key: const Key('farm-creation-region-select'),
      decoration: const InputDecoration(
        labelText: '瓦片区域',
        hintText: '选择离线瓦片区域',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.map_outlined, size: 20),
      ),
      value: _selectedRegion,
      items: regions.map((r) {
        return DropdownMenuItem(
          value: r,
          child: Row(
            children: [
              Expanded(
                child: Text(r.name,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(r.fileSizeLabel,
                  style: TextStyle(
                      fontSize: 11, color: theme.hintColor)),
            ],
          ),
        );
      }).toList(),
      onChanged: (r) {
        if (r != null) _onRegionSelected(r);
      },
    );
  }

  Widget _mapSection(ThemeData theme) {
    if (_selectedRegion == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined,
                  size: 48, color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),
              Text('请先选择瓦片区域',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Map hint bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFE3F2FD),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.touch_app,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '点击地图选择牧场中心位置',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (_pickedPoint != null)
                Text(
                  '${_pickedPoint!.latitude.toStringAsFixed(4)}, ${_pickedPoint!.longitude.toStringAsFixed(4)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
        // Map
        Container(
          height: 350,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  CoordTransform.wgs84ToGcj02(_selectedRegion!.center),
              initialZoom: 13,
              minZoom: 5,
              maxZoom: 18,
              onTap: _onMapTap,
              interactionOptions:
                  const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.chinaFallbackUrl,
                userAgentPackageName: 'com.smartlivestock.app',
                maxNativeZoom: 15,
                maxZoom: 18,
              ),
              if (_pickedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: CoordTransform.wgs84ToGcj02(_pickedPoint!),
                      width: 32,
                      height: 32,
                      child: const Icon(
                        Icons.location_pin,
                        size: 32,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
