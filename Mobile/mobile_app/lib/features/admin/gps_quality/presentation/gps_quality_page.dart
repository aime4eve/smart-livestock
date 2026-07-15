import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// GPS Quality Check page with two tabs:
/// Tab 1: RTK calibration management (RTK points + calibration sessions)
/// Tab 2: Quality reports (device comparison + statistics)
class GpsQualityPage extends ConsumerStatefulWidget {
  const GpsQualityPage({super.key});

  @override
  ConsumerState<GpsQualityPage> createState() => _GpsQualityPageState();
}

class _GpsQualityPageState extends ConsumerState<GpsQualityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      key: const Key('gps-quality-page'),
      appBar: AppBar(
        title: Text(l10n.gpsQualityTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              key: const Key('rtk-calibration-tab'),
              text: l10n.gpsQualityTabRtkCalibration,
            ),
            Tab(
              key: const Key('quality-report-tab'),
              text: l10n.gpsQualityTabQualityReport,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _Placeholder(icon: Icons.my_location, labelKey: 'rtk'),
          _Placeholder(icon: Icons.assessment, labelKey: 'report'),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, required this.labelKey});
  final IconData icon;
  final String labelKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            '（开发中）',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }
}
