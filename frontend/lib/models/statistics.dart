/// Average, high and low for one metric over a period.
///
/// Every field is nullable because a period with no readings still comes back
/// — the server reports an empty summary rather than 404, so the screen can
/// draw its frame and leave the numbers blank.
class MetricSummary {
  const MetricSummary({this.avg, this.max, this.min, required this.count});

  final double? avg;
  final double? max;
  final double? min;
  final int count;

  bool get isEmpty => count == 0;

  factory MetricSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MetricSummary(count: 0);
    return MetricSummary(
      avg: (json['avg'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      min: (json['min'] as num?)?.toDouble(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class StatisticsSummary {
  const StatisticsSummary({
    required this.measurementCount,
    required this.hr,
    required this.hrv,
    required this.conditionScore,
  });

  final int measurementCount;
  final MetricSummary hr;
  final MetricSummary hrv;
  final MetricSummary conditionScore;

  factory StatisticsSummary.fromJson(Map<String, dynamic> json) =>
      StatisticsSummary(
        measurementCount: (json['measurementCount'] as num?)?.toInt() ?? 0,
        hr: MetricSummary.fromJson(json['hr'] as Map<String, dynamic>?),
        hrv: MetricSummary.fromJson(json['hrv'] as Map<String, dynamic>?),
        conditionScore:
            MetricSummary.fromJson(json['conditionScore'] as Map<String, dynamic>?),
      );
}

/// One day on the chart. Days with no reading are included with null values so
/// the line has a gap rather than silently closing over the missing day.
class DailyMetric {
  const DailyMetric({
    required this.date,
    required this.measurementCount,
    this.hr,
    this.hrv,
    this.conditionScore,
  });

  final DateTime date;
  final double? hr;
  final double? hrv;
  final double? conditionScore;
  final int measurementCount;

  bool get hasData => measurementCount > 0;

  factory DailyMetric.fromJson(Map<String, dynamic> json) => DailyMetric(
        date: DateTime.parse(json['date'] as String),
        hr: (json['hr'] as num?)?.toDouble(),
        hrv: (json['hrv'] as num?)?.toDouble(),
        conditionScore: (json['conditionScore'] as num?)?.toDouble(),
        measurementCount: (json['measurementCount'] as num?)?.toInt() ?? 0,
      );
}
