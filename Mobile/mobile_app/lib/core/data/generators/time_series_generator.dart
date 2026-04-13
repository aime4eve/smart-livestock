import 'dart:math';

abstract class TimeSeriesGenerator<T> {
  TimeSeriesGenerator({this.seed = 42});

  final int seed;
  final Map<String, List<T>> _cache = {};

  Random rngForEntity(String entityId) => Random(seed + entityId.hashCode);

  List<T> memoized(String key, List<T> Function() compute) =>
      _cache.putIfAbsent(key, compute);
}
