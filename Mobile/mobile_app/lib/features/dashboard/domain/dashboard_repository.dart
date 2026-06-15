import 'package:hkt_livestock_agentic/core/models/core_models.dart';

class DashboardViewData {
  const DashboardViewData({required this.metrics, this.message});
  final List<DashboardMetric> metrics;
  final String? message;
  static const empty = DashboardViewData(metrics: [], message: '暂无看板数据');
}

abstract class DashboardRepository {
  Future<DashboardViewData> load();
}
