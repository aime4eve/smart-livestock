import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/database/app_database_provider.dart';
import 'package:hkt_livestock_agentic/features/offline_tiles/presentation/offline_tile_manager.dart';
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
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _serverRegions = [];
  List<LocalTileMeta> _localTiles = [];
  int _storageUsed = 0;

  // Download state
  String? _downloadingRegion;
  double _downloadProgress = 0.0;
  DownloadCancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.instance.farmPost('/tile-tasks');
      final data = await ApiClient.instance.farmGet('/tile-status');
      final regions = (data['regions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final mgr = ref.read(offlineTileManagerProvider);
      final localTiles = mgr.getLocalTiles();
      final storage = mgr.getStorageUsedSync();
      if (mounted) {
        setState(() {
          _serverRegions = regions;
          _localTiles = localTiles;
          _storageUsed = storage;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _refreshLocal() async {
    final mgr = ref.read(offlineTileManagerProvider);
    if (mounted) {
      setState(() {
        _localTiles = mgr.getLocalTiles();
        _storageUsed = mgr.getStorageUsedSync();
      });
    }
  }

  Future<void> _downloadRegion(String regionName) async {
    final farmId = ApiClient.instance.activeFarmId;
    if (farmId == null) return;

    final cancelToken = DownloadCancelToken();
    setState(() {
      _downloadingRegion = regionName;
      _downloadProgress = 0.0;
      _cancelToken = cancelToken;
    });

    try {
     final headers = await ApiClient.instance.authHeaders();
     final mgr = ref.read(offlineTileManagerProvider);
      // Create a fresh manager with current auth headers for the download
      final downloadMgr = OfflineTileManager(
       mgr.db,
        ApiClient.instance.baseUrl,
        headers,
      );
      await downloadMgr.downloadRegion(
        int.parse(farmId),
        regionName,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
        cancelToken: cancelToken,
      );
      await _refreshLocal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.offlineTileDownloadSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.offlineTileDownloadFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _downloadingRegion = null; _downloadProgress = 0.0; _cancelToken = null; });
      }
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() { _downloadingRegion = null; _downloadProgress = 0.0; _cancelToken = null; });
  }

  Future<void> _deleteRegion(String regionName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.offlineTileDelete),
        content: Text(l10n.offlineTileDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.offlineTileCancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.offlineTileDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final mgr = ref.read(offlineTileManagerProvider);
    await mgr.deleteLocalTiles(regionName);
    await _refreshLocal();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final downloadedNames = _localTiles.map((t) => t.regionName).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.offlineTileTitle),
        actions: [
          IconButton(
            key: const Key('offline-tile-recheck'),
            onPressed: _busy ? null : () async { setState(() => _busy = true); await _loadData(); setState(() => _busy = false); },
            tooltip: l10n.offlineTileRecheck,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('${l10n.commonLoadFailed}: $_error'))
              : ListView(
                  children: [
                    // Storage usage
                    ListTile(
                      leading: const Icon(Icons.sd_storage),
                      title: Text(l10n.offlineTileStorageUsed(_formatBytes(_storageUsed))),
                    ),
                    const Divider(),

                    // Download progress bar
                    if (_downloadingRegion != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.offlineTileDownloading(_downloadingRegion!),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _cancelDownload,
                                  child: Text(l10n.offlineTileCancel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(value: _downloadProgress),
                          ],
                        ),
                      ),
                      const Divider(),
                    ],

                    // Available regions (server-side, not yet downloaded)
                    if (_serverRegions.isNotEmpty) ...[
                      ListTile(
                        leading: const Icon(Icons.cloud_download),
                        title: Text(l10n.offlineTileRegionsAvailable(_serverRegions.length.toString())),
                      ),
                      ..._serverRegions.where((r) {
                        final name = r['regionName'] as String? ?? '';
                        return !downloadedNames.contains(name);
                      }).map((r) {
                        final name = r['regionName'] as String? ?? '';
                        final size = r['fileSize'] as int? ?? 0;
                        final status = r['status'] as String? ?? '';
                        return ListTile(
                          leading: Icon(
                            status == 'ready' ? Icons.download : Icons.hourglass_empty,
                            color: status == 'ready' ? Colors.blue : Colors.grey,
                          ),
                          title: Text(name),
                          subtitle: Text(_formatBytes(size)),
                          trailing: status == 'ready'
                              ? FilledButton.tonal(
                                  onPressed: _downloadingRegion != null ? null : () => _downloadRegion(name),
                                  child: Text(l10n.offlineTileDownload),
                                )
                              : null,
                        );
                      }),
                      const Divider(),
                    ],

                    // Downloaded regions (local)
                    ListTile(
                      leading: const Icon(Icons.offline_bolt),
                      title: Text(l10n.offlineTileDownloadedRegions(_localTiles.length.toString())),
                    ),
                    if (_localTiles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        child: Center(child: Text(l10n.offlineTileNoDownloaded, style: const TextStyle(color: Colors.grey))),
                      )
                    else
                      ..._localTiles.map((t) => ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(t.regionName),
                        subtitle: Text(_formatBytes(t.fileSize)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteRegion(t.regionName),
                        ),
                      )),
                  ],
                ),
    );
  }
}
