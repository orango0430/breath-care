@Tags(['e2e'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:breath_care/models/measurement.dart';
import 'package:breath_care/services/api_client.dart';
import 'package:breath_care/services/api_config.dart';
import 'package:breath_care/services/api_exception.dart';
import 'package:breath_care/services/auth_service.dart';
import 'package:breath_care/services/measurement_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signs up, logs in and submits a measurement against a **real running
/// server**, so it proves the client and the backend agree on the wire format
/// — something a mocked test cannot do.
///
/// It is tagged `e2e` and excluded from `flutter test` by `dart_test.yaml`,
/// because it needs the network and it leaves a user behind on whichever
/// server it points at. Run it deliberately:
///
/// ```
/// flutter test --tags e2e --run-skipped
/// flutter test --tags e2e --run-skipped --dart-define=API_BASE_URL=http://localhost:8080
/// ```
///
/// `--run-skipped` is not optional: the skip lives in `dart_test.yaml`, and a
/// skip there outranks `--tags` on its own.
void main() {
  // Needed so SharedPreferences can be mocked. It also installs an HttpClient
  // that answers 400 to everything without touching the network, which would
  // make every assertion below meaningless — so put the real one back.
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  const fps = 30;
  const durationSec = 30;

  late String email;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ApiClient.instance.setToken(null);
    // A fresh address per run. Reusing one would fail the second time with
    // DUPLICATE_EMAIL and tell us nothing about the code under test.
    email = 'e2e-${DateTime.now().millisecondsSinceEpoch}@test.com';
  });

  test('가입 → 로그인 → 측정 전송 → 이력 조회가 실제 서버에서 이어진다', () async {
    final user = await AuthService.instance
        .signup(email: email, password: 'password123', nickname: '연동테스트');
    expect(user.email, email);
    expect(user.nickname, '연동테스트', reason: '한글 닉네임이 깨지지 않아야 한다');

    expect(ApiClient.instance.isLoggedIn, isFalse,
        reason: '가입은 토큰을 주지 않는다. 로그인을 따로 해야 한다');

    final loggedIn =
        await AuthService.instance.login(email: email, password: 'password123');
    expect(loggedIn.id, user.id);
    expect(ApiClient.instance.isLoggedIn, isTrue);

    final measurement = await MeasurementService.instance.submit(
      samples: _pulseWave(bpm: 72, fps: fps, durationSec: durationSec),
      fps: fps,
      durationSec: durationSec,
    );

    // The waveform was built at 72 bpm. The server has to find it again.
    expect(measurement.hr, closeTo(72, 5));
    expect(measurement.quality, isNot(MeasurementQuality.poor));
    expect(measurement.hrv, isNotNull);
    expect(measurement.conditionScore, isNotNull,
        reason: '컨디션 지수는 기준선이 없어도 첫 측정부터 나와야 한다');
    expect(measurement.conditionScore, inInclusiveRange(50, 96));

    final history = await MeasurementService.instance.history();
    expect(history, hasLength(1));
    expect(history.first.id, measurement.id);
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('맥동 없는 신호는 POOR_SIGNAL_QUALITY로 돌아온다', () async {
    await AuthService.instance
        .signup(email: email, password: 'password123', nickname: 'poor');
    await AuthService.instance.login(email: email, password: 'password123');

    // A finger that never touched the lens: no pulse, only sensor noise.
    final flat = List<double>.generate(
        fps * durationSec, (_) => 120.0 + (math.Random(3).nextDouble() - 0.5) * 0.05);

    expect(
      () => MeasurementService.instance
          .submit(samples: flat, fps: fps, durationSec: durationSec),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', ApiException.poorSignalQuality)),
    );
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('틀린 비밀번호는 INVALID_CREDENTIALS이고 토큰이 남지 않는다', () async {
    await AuthService.instance.signup(email: email, password: 'password123');

    expect(
      () => AuthService.instance.login(email: email, password: 'wrongpassword'),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', ApiException.invalidCredentials)),
    );
    expect(ApiClient.instance.isLoggedIn, isFalse);
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('토큰 없이 이력을 조회하면 UNAUTHORIZED', () async {
    await ApiClient.instance.setToken(null);

    expect(
      () => MeasurementService.instance.history(),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', ApiException.unauthorized)
          .having((e) => e.requiresLogin, 'requiresLogin', isTrue)),
    );
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('서버 주소가 https인지 확인 — 평문이면 릴리즈 APK에서 차단된다', () {
    expect(ApiConfig.baseUrl, startsWith('https://'),
        reason: 'Android 9+는 network_security_config 없이는 http를 막는다');
  });
}

/// Builds a camera-PPG-shaped signal: a slow baseline with one narrow pulse
/// per beat, the way a fingertip actually looks to the lens.
///
/// A plain sine would also pass, but it would not exercise the peak detector
/// the way a real pulse does — real beats are asymmetric and narrow.
List<double> _pulseWave({
  required double bpm,
  required int fps,
  required int durationSec,
}) {
  final periodSec = 60.0 / bpm;
  final count = fps * durationSec;
  final noise = math.Random(7);

  return List<double>.generate(count, (i) {
    final t = i / fps;
    var value = 180.0;
    for (var beat = 0; beat * periodSec < durationSec + periodSec; beat++) {
      final offset = (t - beat * periodSec) / 0.05;
      if (offset > -6 && offset < 6) {
        value += 5.0 * math.exp(-offset * offset);
      }
    }
    return value + (noise.nextDouble() - 0.5) * 0.2;
  });
}
