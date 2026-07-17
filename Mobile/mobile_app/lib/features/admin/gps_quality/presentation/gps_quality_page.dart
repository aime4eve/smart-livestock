import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/session_test_tab.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/truth_reference_tab.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/quality_report_tab.dart';
import 'package:hkt_livestock_agentic/features/admin/gps_quality/presentation/comparison_tab.dart';

/// GPS Quality Check page with three tabs:
/// Tab 1: Session-Test workflow (session list + test list + create/delete)
/// Tab 2: Truth reference management (RTK points + dynamic routes)
/// Tab 3: Quality comparison (cross-device comparison tables)
/// Tab 4: Device detail report (single device report with scatter, distribution)
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
    _tabController = TabController(length: 4, vsync: this);
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
              key: const Key('session-test-tab'),
              text: l10n.gpsQualitySessionList,
            ),
            Tab(
              key: const Key('truth-ref-tab'),
              text: l10n.gpsQualityTabTruthRef,
            ),
           Tab(
             key: const Key('quality-comparison-tab'),
             text: l10n.gpsQualityTabComparison,
           ),
            Tab(
              key: const Key('device-detail-tab'),
              text: l10n.gpsQualityTabQualityReport,
            ),
         ],
       ),
     ),
     body: TabBarView(
       controller: _tabController,
       children: const [
         SessionTestTab(),
         TruthReferenceTab(),
         ComparisonTab(),
          QualityReportTab(),
       ],
      ),
    );
  }
}
