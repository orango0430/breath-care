/// How much of the reading can be trusted.
///
/// A `poor` result never reaches the app as data — the server answers 422
/// `POOR_SIGNAL_QUALITY` instead and asks for a retake. It exists here only so
/// history rows recorded before that gate can still be parsed.
enum MeasurementQuality {
  good,
  fair,
  poor;

  static MeasurementQuality parse(String? raw) => switch (raw) {
        'GOOD' => MeasurementQuality.good,
        'FAIR' => MeasurementQuality.fair,
        _ => MeasurementQuality.poor,
      };

  /// `fair` means the heart rate stands but the HRV does not, so anything
  /// derived from HRV — the condition score — should be presented carefully.
  bool get hrvIsReliable => this == MeasurementQuality.good;
}

class Measurement {
  const Measurement({
    this.id,
    required this.quality,
    required this.measuredAt,
    this.hr,
    this.hrv,
    this.conditionScore,
  });

  /// Null for a guest reading.
  ///
  /// `/api/measurements/analyze` answers without an id because it analyses and
  /// throws the reading away — there is nothing to reference later. This was
  /// `int` and parsed with `json['id'] as int`, so every successful guest
  /// measurement threw a type error the moment the response came back. The
  /// throw was not an ApiException, so the retake handler never saw it and the
  /// screen sat on "분석 중" forever: the server said 200 and the app hung.
  final int? id;

  /// Beats per minute.
  final double? hr;

  /// RMSSD in milliseconds. This is the number shown as "HRV" in the UI.
  /// The server also computes SDNN, but keeps it internal as the score input.
  final double? hrv;

  /// 0–100, **higher is better**. Derived from HRV, so it moves opposite to
  /// heart rate. Needs no personal baseline — it is there on the first reading.
  final double? conditionScore;

  final MeasurementQuality quality;
  final DateTime measuredAt;

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
        id: (json['id'] as num?)?.toInt(),
        hr: (json['hr'] as num?)?.toDouble(),
        hrv: (json['hrv'] as num?)?.toDouble(),
        conditionScore: (json['conditionScore'] as num?)?.toDouble(),
        quality: MeasurementQuality.parse(json['quality'] as String?),
        measuredAt: DateTime.parse(json['measuredAt'] as String).toLocal(),
      );
}
