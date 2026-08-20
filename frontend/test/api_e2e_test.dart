@Tags(['e2e'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:breath_care/models/measurement.dart';
import 'package:breath_care/services/api_client.dart';
import 'package:breath_care/services/api_config.dart';
import 'package:breath_care/services/api_exception.dart';
import 'package:breath_care/services/auth_service.dart';
import 'package:breath_care/services/calendar_service.dart';
import 'package:breath_care/models/session.dart';
import 'package:breath_care/services/measurement_service.dart';
import 'package:breath_care/services/report_service.dart';
import 'package:breath_care/services/session_service.dart';
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

  test('일정을 만들면 서버에 남고 기간 조회로 다시 읽힌다', () async {
    await AuthService.instance
        .signup(email: email, password: 'password123', nickname: '일정');
    await AuthService.instance.login(email: email, password: 'password123');

    final startAt = DateTime.now().add(const Duration(days: 3));
    final created = await CalendarService.instance.create(
      title: '중앙해커톤 본선 피칭',
      eventType: EventType.presentation,
      startAt: startAt,
    );

    expect(created.id, greaterThan(0));
    expect(created.title, '중앙해커톤 본선 피칭');
    expect(created.eventType, EventType.presentation);

    // The month window the 일정관리 screen asks for.
    final month = DateTime(startAt.year, startAt.month, 1);
    final events = await CalendarService.instance.events(
      from: month,
      to: DateTime(month.year, month.month + 1, 1),
    );

    expect(events.map((e) => e.id), contains(created.id),
        reason: '앱이 그리는 월 범위 안에 저장한 일정이 들어와야 한다');
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('직접 만든 카테고리는 ETC + customCategory로 저장된다', () async {
    await AuthService.instance
        .signup(email: email, password: 'password123', nickname: '커스텀');
    await AuthService.instance.login(email: email, password: 'password123');

    // 모달에서 사용자가 새 카테고리를 추가한 경우
    final mapped = EventType.fromCategory('동아리');
    expect(mapped.type, EventType.etc);
    expect(mapped.custom, '동아리');

    final created = await CalendarService.instance.create(
      title: '동아리 정기 모임',
      eventType: mapped.type,
      startAt: DateTime.now().add(const Duration(days: 1)),
      customCategory: mapped.custom,
    );

    expect(created.displayCategory, '동아리',
        reason: '서버가 커스텀 이름을 그대로 돌려줘야 화면에 그 이름이 뜬다');
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('기본 카테고리 3종은 서버 enum으로 정확히 매핑된다', () {
    expect(EventType.fromCategory('발표').type, EventType.presentation);
    expect(EventType.fromCategory('시험').type, EventType.exam);
    expect(EventType.fromCategory('면접').type, EventType.interview);
    expect(EventType.fromCategory('발표').custom, isNull);
  });

  test('비회원은 일정을 저장할 수 없다', () async {
    await ApiClient.instance.setToken(null);

    expect(
      () => CalendarService.instance.create(
        title: '비회원 일정',
        eventType: EventType.etc,
        startAt: DateTime.now().add(const Duration(days: 1)),
      ),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', ApiException.unauthorized)),
    );
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('호흡 세션이 전후 측정을 묶고 변화량을 돌려준다', () async {
    await AuthService.instance
        .signup(email: email, password: 'password123', nickname: '세션');
    await AuthService.instance.login(email: email, password: 'password123');

    final before = await MeasurementService.instance.submit(
      samples: _pulseWave(bpm: 78, fps: fps, durationSec: durationSec),
      fps: fps,
      durationSec: durationSec,
    );

    final session = await SessionService.instance.start(
      preMeasurementId: before.id,
      preset: BreathingPreset.fourSevenEight,
    );
    expect(session.isCompleted, isFalse, reason: '시작 직후에는 아직 안 끝난 세션이다');
    expect(session.change, isNull);

    // 호흡 뒤 느려진 맥박.
    final after = await MeasurementService.instance.submit(
      samples: _pulseWave(bpm: 64, fps: fps, durationSec: durationSec),
      fps: fps,
      durationSec: durationSec,
    );

    final done = await SessionService.instance
        .complete(sessionId: session.id, postMeasurementId: after.id);

    expect(done.isCompleted, isTrue);
    expect(done.duration, isNotNull);
    // 78 → 64로 넣었으니 서버가 내려간 폭을 음수로 돌려줘야 한다.
    expect(done.change?.hr, lessThan(0));
    expect(done.before?.hr, closeTo(78, 5));
    expect(done.after?.hr, closeTo(64, 5));

    final history = await SessionService.instance.history();
    expect(history.map((s) => s.id), contains(done.id));
  }, timeout: const Timeout(Duration(seconds: 120)));

  test('이미 끝난 세션은 다시 끝낼 수 없다', () async {
    await AuthService.instance
        .signup(email: email, password: 'password123', nickname: '중복');
    await AuthService.instance.login(email: email, password: 'password123');

    final before = await MeasurementService.instance.submit(
      samples: _pulseWave(bpm: 72, fps: fps, durationSec: durationSec),
      fps: fps,
      durationSec: durationSec,
    );
    final session =
        await SessionService.instance.start(preMeasurementId: before.id);
    await SessionService.instance
        .complete(sessionId: session.id, postMeasurementId: before.id);

    // 타임아웃 뒤 무턱대고 재시도하면 안 되는 이유.
    expect(
      () => SessionService.instance
          .complete(sessionId: session.id, postMeasurementId: before.id),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'SESSION_ALREADY_COMPLETED')),
    );
  }, timeout: const Timeout(Duration(seconds: 120)));

  test('일정 완료 체크가 서버에 남고 해제도 된다', () async {
    await AuthService.instance
        .signup(email: email, password: 'password123', nickname: '완료');
    await AuthService.instance.login(email: email, password: 'password123');

    final created = await CalendarService.instance.create(
      title: '완료 체크 대상',
      eventType: EventType.exam,
      startAt: DateTime.now().add(const Duration(days: 2)),
    );
    expect(created.completed, isFalse, reason: '새 일정은 완료가 아니다');

    final ticked = await CalendarService.instance.setCompleted(created.id, true);
    expect(ticked.completed, isTrue);

    // 화면을 다시 그릴 때 서버에서 읽어오는 값이 진짜인지.
    final reread = await CalendarService.instance.events(
      from: DateTime.now().subtract(const Duration(days: 1)),
      to: DateTime.now().add(const Duration(days: 5)),
    );
    expect(reread.firstWhere((e) => e.id == created.id).completed, isTrue);

    final cleared =
        await CalendarService.instance.setCompleted(created.id, false);
    expect(cleared.completed, isFalse);
  }, timeout: const Timeout(Duration(seconds: 120)));

  test('측정이 모자라면 리포트는 INSUFFICIENT_DATA, 채우면 만들어진다', () async {
    await AuthService.instance
        .signup(email: email, password: 'password123', nickname: '리포트');
    await AuthService.instance.login(email: email, password: 'password123');

    // 아직 만든 적이 없으면 조회는 null이다. 화면은 이때 "AI 분석 받기"를 띄운다.
    expect(await ReportService.instance.weekly(), isNull);

    // 서버 정책상 이번 주 측정이 3회는 있어야 한다. 두 번만 넣어 두고 확인한다.
    for (final bpm in [70.0, 74.0]) {
      await MeasurementService.instance.submit(
        samples: _pulseWave(bpm: bpm, fps: fps, durationSec: durationSec),
        fps: fps,
        durationSec: durationSec,
      );
    }
    expect(
      () => ReportService.instance.generate(),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', ApiException.insufficientData)),
    );

    // 세 번째를 채우면 모델이 실제로 글을 쓴다.
    await MeasurementService.instance.submit(
      samples: _pulseWave(bpm: 66, fps: fps, durationSec: durationSec),
      fps: fps,
      durationSec: durationSec,
    );

    final report = await ReportService.instance.generate();
    expect(report.summary, isNotEmpty);
    expect(report.disclaimer, isNotEmpty, reason: '의학적 진단이 아니라는 문구는 항상 붙는다');
    expect(report.cached, isFalse, reason: '처음 만든 것은 캐시가 아니다');

    // 두 번째 조회는 저장된 것을 그대로 준다. 모델을 다시 부르지 않는다.
    final again = await ReportService.instance.weekly();
    expect(again?.summary, report.summary);
  }, timeout: const Timeout(Duration(seconds: 180)));

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
