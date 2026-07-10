import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/core/models/core_models.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Full device health detail dialog — shows all real data from agentic-platform.
/// Triggered by tapping on a device tile.
class DeviceHealthDialog extends StatefulWidget {
  const DeviceHealthDialog({super.key, required this.device, this.boundLivestockCode});

  final DeviceItem device;
  final String? boundLivestockCode;

  static Future<void> show(BuildContext context, DeviceItem device, {String? boundLivestockCode}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DeviceHealthDialog(device: device, boundLivestockCode: boundLivestockCode),
    );
  }

  @override
  State<DeviceHealthDialog> createState() => _DeviceHealthDialogState();
}

class _DeviceHealthDialogState extends State<DeviceHealthDialog> {
  Map<String, dynamic>? _healthData;
    // unused
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final health = await ApiClient.instance.farmGet('devices/${widget.device.id}/health');
      final d = health['data'];
      if (d is Map) _healthData = d.cast<String, dynamic>();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = widget.device;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: AppSpacing.md),

            // Header
            _HeaderTile(device: d, boundLivestockCode: widget.boundLivestockCode),

            // Health score card
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_healthData != null)
              _HealthScoreCard(score: _healthData!['score'] as int?, grade: _healthData!['grade'] as String?, dimensions: _healthData!['dimensions'] as Map<String, dynamic>?),
            const SizedBox(height: AppSpacing.md),

            // Signal card
            _InfoCard(title: '信号质量', icon: Icons.signal_cellular_alt, children: [
              if (d.rssi != null) _InfoRow(label: 'RSSI', value: '${d.rssi} dBm', badge: _rssiBadge(d.rssi!)),
              if (d.snr != null) _InfoRow(label: 'SNR', value: d.snr!),
              if (d.lastGateway != null) _InfoRow(label: '网关', value: d.lastGateway!, mono: true),
            ]),
            const SizedBox(height: AppSpacing.sm),

            // Device identity card
            _InfoCard(title: '设备信息', icon: Icons.memory, children: [
              if (d.devEui != null) _InfoRow(label: 'DevEUI', value: d.devEui!, mono: true),
              if (d.platformDeviceId != null) _InfoRow(label: '平台 ID', value: d.platformDeviceId.toString(), mono: true),
              if (d.softwareVersion != null) _InfoRow(label: '软件版本', value: d.softwareVersion!),
              if (d.hardwareVersion != null) _InfoRow(label: '硬件版本', value: d.hardwareVersion!),
              if (d.lastTelemetrySyncedAt != null) _InfoRow(label: '最后同步', value: _fmtTime(d.lastTelemetrySyncedAt!.toString())),
              _InfoRow(label: '运行状态', value: d.runtimeStatus ?? d.status.name, badge: _statusBadge(d)),
            ]),

            // Platform registration
            const SizedBox(height: AppSpacing.sm),
            _InfoCard(title: '平台注册', icon: Icons.cloud, children: [
              Row(children: [
                Icon(d.isPlatformRegistered ? Icons.cloud_done : Icons.cloud_off, size: 20,
                    color: d.isPlatformRegistered ? AppColors.success : AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Text(d.isPlatformRegistered ? '已注册 (agentic-middle-platform)' : '未注册'),
              ]),
              if (d.lastTelemetrySyncedAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('同步时间: ${_fmtTime(d.lastTelemetrySyncedAt!.toString())}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ]),
            const SizedBox(height: AppSpacing.sm),

            // Binding info
            _InfoCard(title: '牲畜绑定', icon: Icons.link, children: [
              if (widget.boundLivestockCode != null && widget.boundLivestockCode!.isNotEmpty)
                _InfoRow(label: '绑定牲畜', value: widget.boundLivestockCode!)
              else
                Text('未绑定', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _rssiBadge(int rssi) {
    final color = rssi >= -50 ? AppColors.success : rssi >= -80 ? AppColors.warning : AppColors.danger;
    final label = rssi >= -50 ? '优良' : rssi >= -80 ? '一般' : '差';
    return _Badge(color: color, label: label);
  }

  Widget _statusBadge(DeviceItem d) {
    final online = d.runtimeStatus?.toLowerCase() == 'online' || d.status == 'ACTIVE';
    return _Badge(color: online ? AppColors.success : AppColors.danger, label: online ? '在线' : '离线');
  }

  String _fmtTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ts; }
  }
}

class _HeaderTile extends StatelessWidget {
  const _HeaderTile({required this.device, this.boundLivestockCode});
  final DeviceItem device;
  final String? boundLivestockCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Row(children: [
        Icon(_typeIcon(device.type), size: 36, color: _statusColor(device)),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(device.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('${device.deviceTypeName ?? device.type.name} · ${device.runtimeStatus ?? device.status.name} · 电量 ${device.batteryPercent ?? "?"}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          if (boundLivestockCode != null && boundLivestockCode!.isNotEmpty) Text('绑定: $boundLivestockCode', style: Theme.of(context).textTheme.bodySmall),
        ])),

      ]),
    );
  }

  IconData _typeIcon(dynamic t) {
    if (t is DeviceType) return switch (t) { DeviceType.gps => Icons.gps_fixed, DeviceType.rumenCapsule => Icons.medication, DeviceType.earTag => Icons.tag };
    return Icons.devices;
  }
  Color _statusColor(DeviceItem d) => (d.runtimeStatus?.toLowerCase() == 'online' || d.status.name.toLowerCase() == 'active') ? AppColors.success : AppColors.danger;
}

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({this.score, this.grade, this.dimensions});
  final int? score;
  final String? grade;
  final Map<String, dynamic>? dimensions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _gradeColor(grade).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gradeColor(grade).withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Row(children: [
          _HealthScoreCircle(score: score ?? 0, radius: 30, fontSize: 20),
          const SizedBox(width: AppSpacing.md),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('设备健康分', style: Theme.of(context).textTheme.titleMedium),
            Text(grade ?? '--', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: _gradeColor(grade), fontWeight: FontWeight.bold)),
          ]),
        ]),
        if (dimensions != null) ...[
          const SizedBox(height: AppSpacing.md),
          ...dimensions!.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _DimBar(label: _dimLabel(e.key), value: (e.value as num).toInt(), color: _dimColor(e.key)),
          )),
        ],
      ]),
    );
  }

  Color _gradeColor(String? g) => switch (g?.toUpperCase()) { 'HEALTHY' => AppColors.success, 'WARNING' => AppColors.warning, _ => AppColors.danger };
  String _dimLabel(String k) => switch (k) { 'battery' => '电量', 'signal' => '信号', 'online' => '在线', 'tamper' => '防拆卸', 'reporting' => '数据上报', _ => k };
  Color _dimColor(String k) => switch (k) { 'battery' => Colors.orange, 'signal' => Colors.blue, 'online' => Colors.teal, 'tamper' => Colors.red, 'reporting' => Colors.purple, _ => Colors.grey };
}

class _DimBar extends StatelessWidget {
  const _DimBar({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: 80, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
    Expanded(child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: value / 100, backgroundColor: Colors.grey[200], color: color, minHeight: 8),
    )),
    SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodySmall)),
  ]);
}

class _HealthScoreCircle extends StatelessWidget {
  const _HealthScoreCircle({required this.score, this.radius = 24, this.fontSize = 16});
  final int score;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? AppColors.success : score >= 60 ? AppColors.warning : AppColors.danger;
    return Container(
      width: radius * 2, height: radius * 2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15), border: Border.all(color: color, width: 3)),
      child: Center(child: Text('$score', style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color))),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Theme.of(context).dividerColor)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary), const SizedBox(width: AppSpacing.sm), Text(title, style: Theme.of(context).textTheme.titleMedium)]),
      const SizedBox(height: AppSpacing.sm),
      ...children,
    ]),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.badge, this.mono = false});
  final String label;
  final String value;
  final Widget? badge;
  final bool mono;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))),
      Expanded(child: Text(value, style: TextStyle(fontFamily: mono ? 'monospace' : null, fontSize: 13))),
      if (badge != null) badge!,
    ]),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );
}
