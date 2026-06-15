import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hkt_livestock_agentic/app/app_route.dart';
import 'package:hkt_livestock_agentic/core/models/health_models.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/features/epidemic/presentation/epidemic_controller.dart';
import 'package:hkt_livestock_agentic/features/subscription/presentation/subscription_controller.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

class EpidemicContactPage extends ConsumerWidget {
  const EpidemicContactPage({super.key, required this.livestockId});
  final String livestockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final subAsync = ref.watch(subscriptionControllerProvider);
    final tier = subAsync.value?.tier ?? SubscriptionTier.basic;
    final hasEpidemicAlert = checkTierAccess(tier, FeatureFlags.epidemicAlert);

    if (!hasEpidemicAlert) {
      return Scaffold(
        appBar: AppBar(title: Text('🦠 ${l10n.epidemicContactTitle}'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(l10n.epidemicContactLockedMsg, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(AppRoute.subscription.path),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: Text(l10n.epidemicContactUpgrade),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final asyncNetwork = ref.watch(epidemicContactControllerProvider(livestockId));
    return Scaffold(
      appBar: AppBar(title: Text('🦠 ${l10n.epidemicContactTitle}'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: asyncNetwork.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.commonLoadFailed}: $e')),
        data: (network) => RefreshIndicator(
          onRefresh: () => ref.read(epidemicContactControllerProvider(livestockId).notifier).refresh(),
          child: _buildBody(context, l10n, ref, network),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, WidgetRef ref, ContactNetworkResponse network) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSourceCard(l10n, network),
        const SizedBox(height: 16),
        _buildRiskFormula(l10n),
        const SizedBox(height: 16),
        if (network.contacts.isNotEmpty) ...[
          _buildContactNetworkGraph(l10n, network),
          const SizedBox(height: 16),
          ..._buildContactListByWindow(l10n, network),
        ] else
          Card(child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(l10n.epidemicNoContacts)))),
        const SizedBox(height: 16),
        _buildNote(l10n),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.check_circle_outline, size: 18, color: AppColors.textSecondary),
          label: Text(l10n.commonBack, style: TextStyle(color: AppColors.textSecondary)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.border)),
        ),
      ],
    );
  }

  Widget _buildSourceCard(AppLocalizations l10n, ContactNetworkResponse network) {
    final diseaseType = network.diseaseType ?? l10n.epidemicNotMarked;
    final markedAt = network.markedAt;
    return Card(
      color: AppColors.danger.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Text('🐄', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${network.sourceLivestockCode} · ${l10n.epidemicSourceInfected}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                  Text('$diseaseType · ${l10n.epidemicMarkedAt}：${markedAt != null ? '${markedAt.month}/${markedAt.day} ${markedAt.hour}:${markedAt.minute.toString().padLeft(2, '0')}' : l10n.epidemicUnknown}',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskFormula(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧮', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.epidemicRiskFormula, style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactNetworkGraph(AppLocalizations l10n, ContactNetworkResponse network) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🔗 ${l10n.epidemicNetworkGraph}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Premium+', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark))),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: Size.infinite,
                painter: _NetworkPainter(network),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppColors.danger, l10n.riskHigh),
                const SizedBox(width: 12),
                _legendDot(AppColors.warning, l10n.riskMedium),
                const SizedBox(width: 12),
                _legendDot(AppColors.success, l10n.riskLow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContactListByWindow(AppLocalizations l10n, ContactNetworkResponse network) {
    final widgets = <Widget>[];
    final window24 = network.contacts.where((c) => c.hoursAgo <= 24).toList();
    final window48 = network.contacts.where((c) => c.hoursAgo > 24 && c.hoursAgo <= 48).toList();
    final window72 = network.contacts.where((c) => c.hoursAgo > 48 && c.hoursAgo <= 72).toList();

    if (window24.isNotEmpty) {
      widgets.add(_windowHeader(l10n.contactWindow24h, window24.length, l10n));
      widgets.addAll(window24.map((c) => _contactItem(l10n, c)));
    }
    if (window48.isNotEmpty) {
      widgets.add(_windowHeader(l10n.contactWindow48h, window48.length, l10n));
      widgets.addAll(window48.map((c) => _contactItem(l10n, c)));
    }
    if (window72.isNotEmpty) {
      widgets.add(_windowHeader(l10n.contactWindow72h, window72.length, l10n));
      widgets.addAll(window72.map((c) => _contactItem(l10n, c)));
    }
    return widgets;
  }

  Widget _windowHeader(String title, int count, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(8)),
            child: Text('$count${l10n.contactCountSuffix}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          ),
        ],
      ),
    );
  }

  Widget _contactItem(AppLocalizations l10n, ContactNode node) {
    final riskColor = node.riskLevel == 'HIGH' ? AppColors.danger : node.riskLevel == 'MEDIUM' ? AppColors.warning : AppColors.success;
    final riskLabel = node.riskLevel == 'HIGH' ? l10n.riskHigh : node.riskLevel == 'MEDIUM' ? l10n.riskMedium : l10n.riskLow;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            const Text('🐄'),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(node.livestockCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(4)),
                        child: Text('${l10n.contactScoreLabel} ${node.totalRiskScore}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  Text('${l10n.contactDistance} ${node.proximityMeters.toStringAsFixed(1)}m · ${l10n.contactDuration} ${node.contactDurationMinutes}min',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  Text('${l10n.contactFactorTime} ${node.timeScore} · ${l10n.contactFactorDistance} ${node.distanceScore} · ${l10n.contactFactorDuration} ${node.durationScore}',
                      style: TextStyle(fontSize: 9, color: AppColors.textSecondary.withOpacity(0.7))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: riskColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Text(riskLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: riskColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildNote(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.info),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.epidemicContactNote, style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _NetworkPainter extends CustomPainter {
  final ContactNetworkResponse network;
  _NetworkPainter(this.network);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final contacts = network.contacts;
    if (contacts.isEmpty) return;

    final radius = size.shortestSide / 2 - 30;
    final sourcePaint = Paint()..color = AppColors.danger;
    const sourceRadius = 18.0;

    canvas.drawCircle(center, sourceRadius, sourcePaint);
    final srcLabel = network.sourceLivestockCode.isEmpty ? '?' : network.sourceLivestockCode;
    final shortSrc = srcLabel.length > 6 ? srcLabel.substring(srcLabel.length - 3) : srcLabel;
    final tp = TextPainter(text: TextSpan(text: shortSrc, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

    for (int i = 0; i < contacts.length; i++) {
      final angle = (i / contacts.length) * 2 * math.pi - math.pi / 2;
      final nodePos = Offset(
        center.dx + radius * 0.7 * math.cos(angle),
        center.dy + radius * 0.7 * math.sin(angle),
      );

      final node = contacts[i];
      final nodeColor = node.riskLevel == 'HIGH' ? AppColors.danger
          : node.riskLevel == 'MEDIUM' ? AppColors.warning : AppColors.success;

      final linePaint = Paint()
        ..color = nodeColor.withOpacity(0.4)
        ..strokeWidth = node.riskLevel == 'HIGH' ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(center, nodePos, linePaint);

      canvas.drawCircle(nodePos, 12, Paint()..color = nodeColor.withOpacity(0.8));

      final shortCode = node.livestockCode.length > 6 ? node.livestockCode.substring(node.livestockCode.length - 3) : node.livestockCode;
      final labelTp = TextPainter(text: TextSpan(text: shortCode, style: const TextStyle(color: Colors.white, fontSize: 8)), textDirection: TextDirection.ltr);
      labelTp.layout();
      labelTp.paint(canvas, nodePos - Offset(labelTp.width / 2, labelTp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkPainter oldDelegate) => oldDelegate.network != network;
}
