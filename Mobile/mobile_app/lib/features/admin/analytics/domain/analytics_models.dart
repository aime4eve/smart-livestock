class UsageOverview {
  const UsageOverview({
    this.totalCalls = 0,
    this.successCalls = 0,
    this.errorCalls = 0,
    this.avgResponseMs = 0.0,
  });

  final int totalCalls;
  final int successCalls;
  final int errorCalls;
  final double avgResponseMs;

  double get successRate => totalCalls > 0 ? successCalls / totalCalls : 0.0;
}

class UsageTrendPoint {
  const UsageTrendPoint({
    required this.date,
    this.totalCalls = 0,
    this.successCalls = 0,
    this.errorCalls = 0,
    this.avgResponseMs = 0,
  });

  final String date;
  final int totalCalls;
  final int successCalls;
  final int errorCalls;
  final int avgResponseMs;
}
