import '../models/measurement.dart';
import 'api_client.dart';
import 'api_exception.dart';

/// Sends the raw camera waveform up and gets the analysed reading back.
///
/// **The app does no signal processing.** Bandpass filtering, peak detection,
/// RR outlier rejection and the HRV maths all happen on the server, so the
/// numbers stay identical across phones and the algorithm can be corrected
/// without shipping a new APK. Send the samples exactly as the sensor produced
/// them — do not smooth or trim them first.
class MeasurementService {
  const MeasurementService();

  static const MeasurementService instance = MeasurementService();

  ApiClient get _client => ApiClient.instance;

  /// The server refuses anything longer than this, and a longer take gains
  /// nothing: it caps the sample list at 30,000 entries.
  static const int maxSamples = 30000;

  /// Below this the server cannot fit enough beats to judge variability.
  static const int minDurationSec = 10;

  /// Records a measurement for the signed-in user.
  ///
  /// Throws `POOR_SIGNAL_QUALITY` when the take is unusable — a lifted finger,
  /// motion, or light leaking past the fingertip. That is the expected way for
  /// a bad reading to come back, not an error to hide: show the retake prompt.
  Future<Measurement> submit({
    required List<double> samples,
    required int fps,
    required int durationSec,
  }) async {
    _validate(samples, fps, durationSec);

    final data = await _client.post('/api/measurements', body: {
      'samples': samples,
      'fps': fps,
      'durationSec': durationSec,
    });
    return Measurement.fromJson(data as Map<String, dynamic>);
  }

  /// Same analysis without an account and without storing anything. Use it for
  /// a "try it first" flow — the result cannot appear in history later.
  Future<Measurement> analyzeAsGuest({
    required List<double> samples,
    required int fps,
    required int durationSec,
  }) async {
    _validate(samples, fps, durationSec);

    final data = await _client.post('/api/measurements/analyze', body: {
      'samples': samples,
      'fps': fps,
      'durationSec': durationSec,
    });
    return Measurement.fromJson(data as Map<String, dynamic>);
  }

  /// History, newest first. Both bounds are optional.
  Future<List<Measurement>> history({DateTime? from, DateTime? to}) async {
    final data = await _client.get('/api/measurements', query: {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    return (data as List)
        .map((e) => Measurement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Catches the mistakes the server would reject anyway, before spending a
  /// round trip and the user's data on a request that cannot succeed.
  void _validate(List<double> samples, int fps, int durationSec) {
    if (samples.isEmpty) {
      throw const ApiException(
          ApiException.invalidInput, '측정된 신호가 없어요. 손가락을 카메라에 대고 다시 측정해 주세요.');
    }
    if (samples.length > maxSamples) {
      throw const ApiException(
          ApiException.invalidInput, '측정이 너무 길어요. 조금 짧게 다시 측정해 주세요.');
    }
    if (durationSec < minDurationSec) {
      throw const ApiException(
          ApiException.invalidInput, '측정이 너무 짧아요. 조금 더 길게 측정해 주세요.');
    }
    if (fps < 10 || fps > 240) {
      throw const ApiException(
          ApiException.invalidInput, '카메라 상태가 불안정해요. 다시 측정해 주세요.');
    }
  }
}
