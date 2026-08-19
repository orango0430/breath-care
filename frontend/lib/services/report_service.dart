import '../services/api_config.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// A week's AI-written summary.
class WeeklyReport {
  const WeeklyReport({
    required this.summary,
    required this.insights,
    required this.advice,
    required this.disclaimer,
    required this.generatedAt,
    required this.cached,
  });

  final String summary;
  final List<String> insights;
  final List<String> advice;

  /// Required wording — this is not medical advice. Show it.
  final String disclaimer;

  final DateTime generatedAt;

  /// True when the server returned a stored report instead of calling the
  /// model. Useful when debugging why a refresh appears to do nothing.
  final bool cached;

  factory WeeklyReport.fromJson(Map<String, dynamic> json) => WeeklyReport(
        summary: json['summary'] as String? ?? '',
        insights: (json['insights'] as List?)?.cast<String>() ?? const [],
        advice: (json['advice'] as List?)?.cast<String>() ?? const [],
        disclaimer: json['disclaimer'] as String? ?? '',
        generatedAt: DateTime.parse(json['generatedAt'] as String).toLocal(),
        cached: json['cached'] as bool? ?? false,
      );
}

class ReportService {
  const ReportService();

  static const ReportService instance = ReportService();

  /// This week's report, or null when none has been made yet.
  ///
  /// Cheap — it never calls the model. Use it on screen entry and show a
  /// "만들기" button when it comes back null.
  Future<WeeklyReport?> weekly() async {
    try {
      final data = await ApiClient.instance.get('/api/reports/weekly');
      return WeeklyReport.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.code == 'NOT_FOUND') return null;
      rethrow;
    }
  }

  /// Writes this week's report. Slow — it calls an external model, so the
  /// screen needs a spinner and the longer timeout.
  ///
  /// Throws `INSUFFICIENT_DATA` when there are too few readings to say
  /// anything, and `REPORT_UNAVAILABLE` when the model call fails. Neither is
  /// fatal: measurements and statistics still work, so only blank the report
  /// area.
  Future<WeeklyReport> generate({bool refresh = false}) async {
    final data = await ApiClient.instance.post(
      '/api/reports/weekly?refresh=$refresh',
      timeout: ApiConfig.reportTimeout,
    );
    return WeeklyReport.fromJson(data as Map<String, dynamic>);
  }
}
