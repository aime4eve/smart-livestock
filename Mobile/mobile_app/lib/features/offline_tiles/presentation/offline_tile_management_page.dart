import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class OfflineTileManagementPage extends ConsumerStatefulWidget {
  const OfflineTileManagementPage({super.key});

  @override
  ConsumerState<OfflineTileManagementPage> createState() =>
      _OfflineTileManagementPageState();
}

class _OfflineTileManagementPageState
    extends ConsumerState<OfflineTileManagementPage> {
  bool _loading = true;
  bool _busy = false; // 正在请求生成/重新检测
  String? _error;
  List<Map<String, dynamic>> _regions = [];

  @override
  void initState() {
    super.initState();
    _requestAndLoad();
  }

  /// 进页/重检：先 POST /tile-tasks（幂等——已生成的 region 立即关联，无则去重触发生成），
  /// 再拉 tile-status。owner 无需 admin 权限。
  Future<void> _requestAndLoad() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.instance.farmPost('/tile-tasks');
      final data = await ApiClient.instance.farmGet('/tile-status');
      final regions = (data['regions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() { _regions = regions; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _recheck() async {
    setState(() { _busy = true; });
    try {
      await ApiClient.instance.farmPost('/tile-tasks');
      final data = await ApiClient.instance.farmGet('/tile-status');
      final regions = (data['regions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) setState(() { _regions = regions; _busy = false; });
    } catch (_) {
      if (mounted) setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.offlineTileTitle),
        actions: [
          IconButton(
            key: const Key('offline-tile-recheck'),
            onPressed: _busy ? null : _recheck,
            tooltip: l10n.offlineTileRecheck,
            icon: _busy
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('${l10n.commonLoadFailed}: $_error'))
              : _regions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_download,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(l10n.offlineTileGeneratingHint,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton.tonalIcon(
                              key: const Key('offline-tile-generate'),
                              onPressed: _busy ? null : _recheck,
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.offlineTileRecheck),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.map),
                          title: Text(l10n.offlineTileRegionsAvailable(_regions.length.toString())),
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
