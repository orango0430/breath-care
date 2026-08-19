import '../models/statistics.dart';
import 'api_client.dart';

/// Aggregates for the home and log screens.
///
/// The date range is optional on both calls; leaving it off lets the server
/// pick its own default window rather than the app guessing one.
class StatisticsService {
  const StatisticsService();

  static const StatisticsService instance = StatisticsService();

  Future<StatisticsSummary> summary({DateTime? from, DateTime? to}) async {
    final data = await ApiClient.instance.get('/api/statistics/summary', query: {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    return StatisticsSummary.fromJson(data as Map<String, dynamic>);
  }

  /// Daily averages for charting. Includes days with no reading.
  Future<List<DailyMetric>> daily({DateTime? from, DateTime? to}) async {
    final data = await ApiClient.instance.get('/api/statistics/daily', query: {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    return (data as List)
        .map((e) => DailyMetric.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
