import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/quality_report_tab.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/rtk_calibration_tab.dart';

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
          RtkCalibrationTab(),
          QualityReportTab(),
        ],
      ),
    );
  }
}
