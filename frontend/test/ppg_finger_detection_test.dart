import 'package:breath_care/utils/ppg_sensor_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the contact test that decides whether a measurement is running.
///
/// It earns a test because both ways of getting it wrong are silent. Too
/// strict and the screen sits on "손가락을 올려주세요" forever with a perfectly
/// good finger on the lens — which is what shipped. Too loose and the app
/// counts down against a view of the room and uploads noise.
///
/// The numbers below are measurements, not guesses: the room case is what the
/// Pixel_8 emulator's rendered camera actually reported.
void main() {
  late PpgSensorService service;

  setUp(() => service = PpgSensorService());

  /// Feeds one frame repeatedly, the way the camera stream would.
  void feed(
    PpgSensorService s, {
    required double diff,
    required double v,
    required double spread,
    double y = 200,
    int frames = 15,
  }) {
    for (var i = 0; i < frames; i++) {
      s.updateFingerState(diff, v, spread, y);
    }
  }

  test('손가락을 올리면 인식된다', () {
    feed(service, diff: 60, v: 190, spread: 8);
    expect(service.isFingerDetected, isTrue);
  });

  test('AWB가 붉은기를 빼도 인식된다', () {
    // The case that broke on a real phone: auto white balance drags the red
    // cast back toward neutral a second after the torch comes on, and the old
    // `chromDiff > 45 && avgV > 150` test never fired again.
    feed(service, diff: 24, v: 138, spread: 12);
    expect(service.isFingerDetected, isTrue);
  });

  test('방 안 풍경은 붉은기가 있어도 인식되지 않는다', () {
    // Emulator's rendered room, measured: colour alone passes, structure does
    // not. Without the evenness test this counted down with no finger present.
    feed(service, diff: 22.3, v: 140, spread: 45.0, y: 104, frames: 60);
    expect(service.isFingerDetected, isFalse);
  });

  test('토치에 눈부신 손가락도 인식된다', () {
    // The case an absolute spread limit got wrong. A finger right against the
    // torch is bright and blows out in the middle, so the raw spread lands in
    // the forties — the same figure as the emulator's room, at more than twice
    // the brightness. Only the ratio tells them apart.
    feed(service, diff: 40, v: 175, spread: 44.0, y: 230);
    expect(service.isFingerDetected, isTrue);
  });

  test('렌즈를 가리지 않으면 인식되지 않는다', () {
    feed(service, diff: 3, v: 128, spread: 55);
    expect(service.isFingerDetected, isFalse);
  });

  test('짧게 스치는 붉은 물체로는 인식되지 않는다', () {
    // Under the debounce window, so it must not latch.
    feed(service, diff: 60, v: 190, spread: 8, frames: 3);
    expect(service.isFingerDetected, isFalse);
  });

  test('측정 중 잠깐 흔들려도 인식이 풀리지 않는다', () {
    feed(service, diff: 60, v: 190, spread: 8);
    expect(service.isFingerDetected, isTrue);

    // A press that shifts for a few frames. Dropping contact here would throw
    // away the measurement in progress and gap the waveform.
    feed(service, diff: 5, v: 100, spread: 60, frames: 4);
    expect(service.isFingerDetected, isTrue);

    // Back on the lens — the release counter has to reset, not accumulate.
    feed(service, diff: 60, v: 190, spread: 8, frames: 5);
    feed(service, diff: 5, v: 100, spread: 60, frames: 4);
    expect(service.isFingerDetected, isTrue);
  });

  test('손가락을 떼면 인식이 풀린다', () {
    feed(service, diff: 60, v: 190, spread: 8);
    expect(service.isFingerDetected, isTrue);

    feed(service, diff: 3, v: 110, spread: 55, frames: 12);
    expect(service.isFingerDetected, isFalse);
  });
}
