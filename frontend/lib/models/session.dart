/// The breathing techniques the server knows by name.
///
/// The app's own catalogue is larger and carries images and copy; this enum is
/// only the wire value, so a session can be filed under the right technique.
enum BreathingPreset {
  fourSevenEight('FOUR_SEVEN_EIGHT', '4-7-8 호흡'),
  box('BOX', '4-4-4-4 박스 호흡'),
  resonance('RESONANCE', '5.5-5.5 공진 호흡'),
  physiologicalSigh('PHYSIOLOGICAL_SIGH', '생리학적 한숨'),
  relaxFourSix('RELAX_FOUR_SIX', '4-6 릴랙스 호흡'),
  semiBox('SEMI_BOX', '4-2-4-2 세미 박스 호흡'),
  diaphragmatic('DIAPHRAGMATIC', '2-1-4-1 횡격막 복식호흡'),
  awakening('AWAKENING', '4-1-2-1 각성 호흡');

  const BreathingPreset(this.wire, this.label);

  final String wire;
  final String label;

  /// Matches a routine title from the app's catalogue to a server preset.
  ///
  /// Titles do not line up exactly — the app says "5-5 공진 호흡" where the
  /// server says "5.5-5.5 공진 호흡" — so this matches on the distinctive part
  /// rather than the whole string. Returns null for a technique the server has
  /// no name for; the session is still recorded, just without a preset.
  static BreathingPreset? fromTitle(String title) {
    if (title.contains('4-7-8')) return fourSevenEight;
    if (title.contains('박스') && title.contains('4-2-4-2')) return semiBox;
    if (title.contains('박스')) return box;
    if (title.contains('공명') || title.contains('공진')) return resonance;
    if (title.contains('한숨')) return physiologicalSigh;
    if (title.contains('4-6')) return relaxFourSix;
    if (title.contains('횡격막')) return diaphragmatic;
    if (title.contains('각성')) return awakening;
    return null;
  }

  static BreathingPreset? parse(String? raw) {
    if (raw == null) return null;
    for (final preset in values) {
      if (preset.wire == raw) return preset;
    }
    return null;
  }
}

/// The three metrics at one moment.
class MetricSnapshot {
  const MetricSnapshot({this.hr, this.hrv, this.conditionScore});

  final double? hr;
  final double? hrv;
  final double? conditionScore;

  factory MetricSnapshot.fromJson(Map<String, dynamic> json) => MetricSnapshot(
        hr: (json['hr'] as num?)?.toDouble(),
        hrv: (json['hrv'] as num?)?.toDouble(),
        conditionScore: (json['conditionScore'] as num?)?.toDouble(),
      );
}

/// How much each metric moved over the session.
///
/// **The metrics do not agree on which direction is good.** A falling heart
/// rate is an improvement; falling HRV or condition score is not. Do not paint
/// them all with one rule when showing increase/decrease.
class MetricChange {
  const MetricChange({
    this.hr,
    this.hrPercent,
    this.hrv,
    this.hrvPercent,
    this.conditionScore,
    this.conditionScorePercent,
  });

  final double? hr;
  final double? hrPercent;
  final double? hrv;
  final double? hrvPercent;
  final double? conditionScore;
  final double? conditionScorePercent;

  /// True when the session left the user calmer: slower pulse, steadier HRV.
  bool get improved => (hr ?? 0) < 0 || (hrv ?? 0) > 0;

  factory MetricChange.fromJson(Map<String, dynamic> json) => MetricChange(
        hr: (json['hr'] as num?)?.toDouble(),
        hrPercent: (json['hrPercent'] as num?)?.toDouble(),
        hrv: (json['hrv'] as num?)?.toDouble(),
        hrvPercent: (json['hrvPercent'] as num?)?.toDouble(),
        conditionScore: (json['conditionScore'] as num?)?.toDouble(),
        conditionScorePercent:
            (json['conditionScorePercent'] as num?)?.toDouble(),
      );
}

/// One breathing session, bracketed by a measurement at each end.
class BreathingSession {
  const BreathingSession({
    required this.id,
    required this.startedAt,
    this.preset,
    this.calendarEventId,
    this.endedAt,
    this.before,
    this.after,
    this.change,
  });

  final int id;
  final BreathingPreset? preset;
  final int? calendarEventId;
  final DateTime startedAt;

  /// Null while the session is still open — the user started breathing but has
  /// not taken the closing measurement.
  final DateTime? endedAt;

  final MetricSnapshot? before;
  final MetricSnapshot? after;

  /// Only present once the session has ended.
  final MetricChange? change;

  bool get isCompleted => endedAt != null;

  /// How long the session ran. Null while it is still open.
  Duration? get duration => endedAt?.difference(startedAt);

  factory BreathingSession.fromJson(Map<String, dynamic> json) =>
      BreathingSession(
        id: json['id'] as int,
        preset: BreathingPreset.parse(json['preset'] as String?),
        calendarEventId: json['calendarEventId'] as int?,
        startedAt: DateTime.parse(json['startedAt'] as String).toLocal(),
        endedAt: json['endedAt'] == null
            ? null
            : DateTime.parse(json['endedAt'] as String).toLocal(),
        before: json['before'] == null
            ? null
            : MetricSnapshot.fromJson(json['before'] as Map<String, dynamic>),
        after: json['after'] == null
            ? null
            : MetricSnapshot.fromJson(json['after'] as Map<String, dynamic>),
        change: json['change'] == null
            ? null
            : MetricChange.fromJson(json['change'] as Map<String, dynamic>),
      );
}
