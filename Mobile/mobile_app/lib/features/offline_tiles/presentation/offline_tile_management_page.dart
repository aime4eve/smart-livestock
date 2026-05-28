import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_tile_manager.dart';

class OfflineTileManagementPage extends ConsumerStatefulWidget {
  const OfflineTileManagementPage({super.key});

  @override
  ConsumerState<OfflineTileManagementPage> createState() =>
      _OfflineTileManagementPageState();
}

class _OfflineTileManagementPageState
    extends ConsumerState<OfflineTileManagementPage> {
  bool _loading = true;
  String? _error;
  int _storageUsed = 0;
  List<Map<String, dynamic>> _regions = [];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() { _loading = true; _error = null; });
    try {
      final manager = ref.read(offlineTileManagerProvider);
      final used = await manager.getStorageUsed();
      final regions = ref.read(offlineTileManagerProvider).getTileMetasSync != null
          ? ref.read(offlineTileManagerProvider).getTileMetasSync!() : <Map<String, dynamic>>[];
      if (mounted) setState(() { _storageUsed = used; _regions = regions; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('离线地图管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('加载失败: $_error'))
              : ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.storage),
                      title: const Text('已用存储'),
                      subtitle: Text('${(_storageUsed / 1024 / 1024).toStringAsFixed(1)} MB'),
                    ),
                    const Divider(),
                    ..._regions.map((r) => ListTile(
                      leading: Icon(
                        r['status'] == 'ready' ? Icons.check_circle : Icons.downloading,
                        color: r['status'] == 'ready' ? Colors.green : Colors.orange,
                      ),
                      title: Text(r['region_name'] as String? ?? ''),
                      subtitle: Text(
                        '${((r['file_size'] as int? ?? 0) / 1024 / 1024).toStringAsFixed(1)} MB',
                      ),
                    )),
                  ],
                ),
    );
  }
}
