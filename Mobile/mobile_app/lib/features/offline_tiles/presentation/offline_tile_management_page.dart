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
      if (mounted) setState(() { _storageUsed = used; _loading = false; });
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
                  ],
                ),
    );
  }
}
