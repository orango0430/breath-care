import '../models/session.dart';
import 'api_client.dart';

/// Breathing sessions.
///
/// A session is bracketed by two measurements — one before the breathing, one
/// after — and the server works out the change between them. That is the whole
/// point of the record: "이 호흡을 하고 나서 심박수가 이만큼 내려갔다".
///
/// Both ends are required by the server, so [start] needs the reading that led
/// the user here and [complete] needs a fresh one taken afterwards. A session
/// that is started and never completed is left open rather than deleted; the
/// user did do the breathing, they just did not measure again.
class SessionService {
  const SessionService();

  static const SessionService instance = SessionService();

  ApiClient get _client => ApiClient.instance;

  /// Opens a session. [preMeasurementId] is the reading the user just took.
  Future<BreathingSession> start({
    required int preMeasurementId,
    BreathingPreset? preset,
    int? calendarEventId,
  }) async {
    final data = await _client.post('/api/sessions', body: {
      'preMeasurementId': preMeasurementId,
      if (preset != null) 'preset': preset.wire,
      if (calendarEventId != null) 'calendarEventId': calendarEventId,
    });
    return BreathingSession.fromJson(data as Map<String, dynamic>);
  }

  /// Closes a session with the measurement taken after the breathing.
  ///
  /// Throws `SESSION_ALREADY_COMPLETED` if it has been closed once already, so
  /// do not retry blindly on a timeout.
  Future<BreathingSession> complete({
    required int sessionId,
    required int postMeasurementId,
  }) async {
    final data = await _client.patch(
      '/api/sessions/$sessionId/complete',
      body: {'postMeasurementId': postMeasurementId},
    );
    return BreathingSession.fromJson(data as Map<String, dynamic>);
  }

  /// Newest first. Includes sessions that were never completed.
  Future<List<BreathingSession>> history({DateTime? from, DateTime? to}) async {
    final data = await _client.get('/api/sessions', query: {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    return (data as List)
        .map((e) => BreathingSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
