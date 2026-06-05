import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:smart_livestock_demo/core/api/api_client.dart';

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
  List<Map<String, dynamic>> _regions = [];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiClient.instance.farmGet('/tile-status');
      final regions = (data['regions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() { _regions = regions; _loading = false; });
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
              : _regions.isEmpty
                  ? const Center(child: Text('暂无可用离线地图'))
                  : ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.map),
                          title: Text('可用区域（${_regions.length}）'),
                        ),
                        const Divider(),
                        ..._regions.map((r) => ListTile(
                          leading: Icon(
                            r['status'] == 'ready' ? Icons.check_circle : Icons.cloud_download,
                            color: r['status'] == 'ready' ? Colors.green : Colors.blue,
                          ),
                          title: Text(r['regionName'] as String? ?? ''),
                          subtitle: Text(
                            '${((r['fileSize'] as int? ?? 0) / 1024 / 1024).toStringAsFixed(1)} MB',
                          ),
                        )),
                      ],
                    ),
    );
  }
}
