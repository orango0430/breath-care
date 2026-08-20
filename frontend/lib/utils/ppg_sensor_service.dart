import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

/// PPG Sensor Measurement Data Result
class PpgMeasurementResult {
  final int bpm;
  final double hrvSdnnMs;
  final int breathRpm;
  final double measuredInhaleSec;
  final double measuredExhaleSec;
  final String signalQuality;

  /// Set when the reading came back from the server. The server owns this
  /// number, so when it is present the local formula below must not be used —
  /// two answers on one screen is worse than either answer alone.
  final double? serverConditionScore;

  PpgMeasurementResult({
    required this.bpm,
    required this.hrvSdnnMs,
    required this.breathRpm,
    required this.measuredInhaleSec,
    required this.measuredExhaleSec,
    this.signalQuality = 'Good',
    this.serverConditionScore,
  });

  /// Builds a result from an analysed server reading.
  ///
  /// Breathing pace is still derived here because the server does not return
  /// it — it is a presentation detail, not a measurement.
  factory PpgMeasurementResult.fromServer({
    required double hr,
    required double hrv,
    required double? conditionScore,
    required String quality,
  }) {
    final bpm = hr.round();
    final breathRpm = (bpm / 5.2).round().clamp(10, 20);
    return PpgMeasurementResult(
      bpm: bpm,
      hrvSdnnMs: double.parse(hrv.toStringAsFixed(1)),
      breathRpm: breathRpm,
      measuredInhaleSec:
          double.parse((60.0 / breathRpm * 0.42).clamp(1.8, 4.5).toStringAsFixed(1)),
      measuredExhaleSec:
          double.parse((60.0 / breathRpm * 0.58).clamp(2.0, 6.0).toStringAsFixed(1)),
      signalQuality: quality,
      serverConditionScore: conditionScore,
    );
  }

  /// Prefers the server's number. The local formula is a fallback for the web
  /// simulation samples, which never reach the server.
  int get conditionScore =>
      serverConditionScore?.round() ??
      (hrvSdnnMs * 1.4 + 40).clamp(50.0, 96.0).round();

  int get stressIndex =>
      ((bpm / 1.3) + (50 - hrvSdnnMs * 0.7)).clamp(15.0, 95.0).round();

  String get stressStatusText {
    if (stressIndex < 35) return '낮음';
    if (stressIndex < 65) return '보통';
    return '높음';
  }

  factory PpgMeasurementResult.defaultSample() {
    return PpgMeasurementResult(
      bpm: 76,
      hrvSdnnMs: 28.5,
      breathRpm: 14,
      measuredInhaleSec: 2.2,
      measuredExhaleSec: 2.2,
      signalQuality: 'Good',
    );
  }

  /// 5대 카테고리 시뮬레이션용 랜덤 결과 생성기 (웹/노트북 테스트용)
  factory PpgMeasurementResult.randomSample() {
    final rng = math.Random();
    final categoryIndex = rng.nextInt(5); // 0 ~ 4 (5대 카테고리 랜덤 생성)

    switch (categoryIndex) {
      case 0:
        // 1. 긴급 대처 (BPM 98~106, HRV 16~22ms) -> 생리학적 한숨
        return PpgMeasurementResult(
          bpm: 98 + rng.nextInt(9),
          hrvSdnnMs: 16.0 + rng.nextDouble() * 6.0,
          breathRpm: 22,
          measuredInhaleSec: 1.8,
          measuredExhaleSec: 2.0,
          signalQuality: 'Good',
        );
      case 1:
        // 2. 심리 이완 (BPM 85~92, HRV 18~28ms) -> 4-7-8 호흡
        return PpgMeasurementResult(
          bpm: 85 + rng.nextInt(8),
          hrvSdnnMs: 18.0 + rng.nextDouble() * 10.0,
          breathRpm: 16,
          measuredInhaleSec: 2.0,
          measuredExhaleSec: 2.2,
          signalQuality: 'Good',
        );
      case 2:
        // 3. 집중·몰입 (BPM 72~82, HRV 34~48ms) -> 4-4-4-4 박스 호흡
        return PpgMeasurementResult(
          bpm: 72 + rng.nextInt(11),
          hrvSdnnMs: 34.0 + rng.nextDouble() * 14.0,
          breathRpm: 14,
          measuredInhaleSec: 2.2,
          measuredExhaleSec: 2.2,
          signalQuality: 'Good',
        );
      case 3:
        // 4. 회복·밸런스 (BPM 64~72, HRV 58~72ms) -> 5.5-5.5 공진 호흡
        return PpgMeasurementResult(
          bpm: 64 + rng.nextInt(9),
          hrvSdnnMs: 58.0 + rng.nextDouble() * 14.0,
          breathRpm: 12,
          measuredInhaleSec: 2.6,
          measuredExhaleSec: 2.6,
          signalQuality: 'Good',
        );
      case 4:
      default:
        // 5. 에너지 각성 (BPM 52~58, HRV 42~58ms) -> 4-1-2-1 각성 호흡
        return PpgMeasurementResult(
          bpm: 52 + rng.nextInt(7),
          hrvSdnnMs: 42.0 + rng.nextDouble() * 16.0,
          breathRpm: 10,
          measuredInhaleSec: 2.8,
          measuredExhaleSec: 2.2,
          signalQuality: 'Good',
        );
    }
  }
}

/// PpgSensorService (카메라 PPG 센싱 및 실시간 붉은빛 명도 분석 서비스)
class PpgSensorService {
  static PpgMeasurementResult? latestResult;
  CameraController? _cameraController;
  bool _isInitializing = false;
  bool _isCameraAvailable = false;
  bool isFingerDetected = false;
  bool _isDisposed = false;

  double debugAvgY = 0.0;
  double debugAvgU = 0.0;
  double debugAvgV = 0.0;
  double debugDiff = 0.0;
  double debugSpread = 0.0;
  DateTime? _lastDebugLogAt;

  final StreamController<double> _ppgValueController =
      StreamController<double>.broadcast();
  final StreamController<bool> _fingerStateController =
      StreamController<bool>.broadcast();

  Stream<double> get ppgStream => _ppgValueController.stream;
  Stream<bool> get fingerStateStream => _fingerStateController.stream;

  double _prevY = 0.0;
  double _prevPrevY = 0.0;
  final List<double> _yHistory = [];

  /// Consecutive frames on either side of the contact test. See
  /// [updateFingerState] for why contact is debounced in both directions.
  int _contactFrames = 0;
  int _releaseFrames = 0;

  /// Exposure is frozen once, on first contact. See [_lockExposureOnContact].
  bool _exposureLocked = false;

  final List<DateTime> _peakTimestamps = [];
  final List<double> _rrIntervalsMs = [];
  Timer? _simulationTimer;

  /// One unbroken stretch of contact, and the time it took.
  ///
  /// Samples are kept raw: no smoothing, no trimming. The server's filter
  /// expects the untouched signal, and the stored copy is what we replay
  /// later when tuning the algorithm.
  final List<_ContactRun> _runs = [_ContactRun()];
  DateTime? _lastSampleAt;

  /// The run currently being filled. Always the last one.
  _ContactRun get _current => _runs.last;

  /// The longest unbroken run — the one we upload.
  ///
  /// Samples either side of a break are **not** adjacent in time, but the
  /// server reads the array as evenly spaced. Concatenating across a break
  /// puts a step where no step happened, and a step is exactly what the peak
  /// detector is built to find: it reads as a giant heartbeat, corrupts the
  /// intervals around it, and lands in the HRV that the condition score is
  /// computed from. One 20-second reading with three breaks came back with
  /// an HRV of 125 ms against a true 31 ms.
  ///
  /// So a broken measurement contributes only its best piece. If that piece
  /// is too short the server says so, which is the honest answer — better
  /// than a confident number derived from a signal that was never continuous.
  _ContactRun get _longestRun {
    var best = _runs.first;
    for (final run in _runs) {
      if (run.samples.length > best.samples.length) best = run;
    }
    return best;
  }

  /// The samples to upload. Empty until a finger is detected.
  List<double> get waveform => List.unmodifiable(_longestRun.samples);

  /// What the phone actually collected, in one line, for the retake message.
  ///
  /// The person who can retry a failed measurement is holding a phone with no
  /// debugger attached, and "신호 품질이 낮습니다" gives them nothing to act on
  /// and us nothing to diagnose with. These four numbers say which of the
  /// server's gates the reading could not clear:
  ///
  /// - `n` below `fps × 18` never had a chance on length alone
  /// - `fps` at exactly 10 means the real rate was lower and got clamped
  /// - `runs` above 1 means contact broke, so only a fragment was sent
  String get captureSummary {
    final total = _runs.fold<int>(0, (sum, run) => sum + run.samples.length);
    return 'n=${waveform.length}/$total fps=$capturedFps '
        '${capturedDurationSec}s runs=${_runs.length}';
  }

  /// Seconds of actual contact behind [waveform].
  ///
  /// Not wall-clock: the countdown pauses whenever the finger lifts, so a
  /// 20-second measurement can span a minute. Charging that idle time to the
  /// waveform would halve the reported frame rate, and the server derives
  /// heart rate straight from that number — a 72 bpm pulse would come back
  /// as 36.
  int get capturedDurationSec => _longestRun.millis ~/ 1000;

  /// Frames actually delivered per second, measured rather than assumed.
  ///
  /// The camera does not honour a requested rate — it drops frames under load
  /// and slows down in dim light. Sending a nominal 30 when the real rate was
  /// 22 would stretch every interval the server computes and skew the heart
  /// rate by the same ratio.
  /// Divides by the elapsed milliseconds, not by [capturedDurationSec].
  ///
  /// That getter floors to whole seconds, and dividing by a floored figure
  /// reports a rate higher than the camera actually managed — 274 frames over
  /// 20.8s came out as 14 fps instead of 13.2. Two things broke. The server
  /// asks for `fps × 20` samples before it will look at a reading, and an
  /// inflated fps put that bar above the number of frames we actually had, so
  /// a perfectly good 20-second measurement came back "신호 품질이 낮습니다".
  /// The same inflation also stretched every interval, skewing the heart rate
  /// by whatever the rounding error happened to be.
  int get capturedFps {
    final run = _longestRun;
    if (run.millis <= 0 || run.samples.isEmpty) return 30;
    final rate = run.samples.length * 1000 / run.millis;
    return rate.round().clamp(10, 240);
  }

  bool get isCameraAvailable => _isCameraAvailable;

  /// True when the camera could not be opened on a real device. The screen
  /// should say so rather than pretending a measurement is running.
  bool cameraInitFailed = false;

  Future<void> initializeCamera() async {
    _isDisposed = false;
    isFingerDetected = false;
    if (!_fingerStateController.isClosed) {
      _fingerStateController.add(false);
    }
    _peakTimestamps.clear();
    _rrIntervalsMs.clear();
    _yHistory.clear();
    _contactFrames = 0;
    _releaseFrames = 0;
    _runs
      ..clear()
      ..add(_ContactRun());
    _lastSampleAt = null;
    _prevY = 0.0;
    _prevPrevY = 0.0;

    if (_isInitializing || _cameraController != null) return;
    _isInitializing = true;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _startSimulationFallback();
        return;
      }

      final rearCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        rearCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Focus only. Autofocus hunts against a lens with a finger pressed to it
      // and never settles, and nothing about a covered lens needs refocusing.
      //
      // Exposure is *not* frozen here. It used to be, 400ms after the torch
      // came on — which is before the finger is on the lens. The sensor locked
      // to a bright, uncovered scene, then the finger blocked the light and
      // the frames went black and stayed black: 20 seconds of 0.0 uploaded as
      // a waveform. Auto-exposure flattening the pulse was the worry; killing
      // the picture outright is worse. It is locked once contact is real, in
      // [_lockExposureOnContact].
      try {
        await _cameraController!.setFocusMode(FocusMode.locked);
      } catch (e) {
        // Some devices refuse to lock. Detection still works, it just drifts.
        debugPrint('Focus lock unavailable: $e');
      }

      _isCameraAvailable = true;
      await _cameraController!.startImageStream(_processCameraFrame);

      // The torch goes on **after** the stream is running, and again a moment
      // later.
      //
      // Starting an image stream rebuilds the Android capture session, and the
      // rebuild drops the flash. Setting it beforehand — which is what this
      // did — leaves the lamp off for the whole measurement. With a finger
      // sealing the lens there is then no light at all, and every frame comes
      // back black: the waveform uploaded as 599 samples of `0.0` and the
      // server rightly called it "관류부족 0.00000".
      //
      // The second attempt covers devices that reconfigure once more as the
      // first frames arrive.
      await _enableTorch();
      Future<void>.delayed(const Duration(milliseconds: 700), _enableTorch);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      // Only fake a pulse where there is no camera to begin with. On a real
      // phone this path is reached by a denied permission or a camera another
      // app is holding, and the fallback reports isFingerDetected = true with
      // invented intervals — the user would see a clean "measurement" and the
      // made-up numbers would be uploaded as a genuine reading.
      if (kIsWeb || kDebugMode) {
        _startSimulationFallback();
      } else {
        cameraInitFailed = true;
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Process individual camera frame image with Bulletproof YUV Finger Contact Detection
  void _processCameraFrame(CameraImage image) {
    if (_isDisposed || _cameraController == null) return;

    double ySum = 0;
    double ySqSum = 0;
    double uSum = 0;
    double vSum = 0;
    int sampleCount = 0;

    // Sample a grid of real pixels, addressed by row and column.
    //
    // This used to walk the Y plane as a flat byte array — `for (i = 0;
    // i < bytes.length; i += step)`. That is only correct when a row of
    // pixels is exactly `width` bytes long, and on most phones it is not:
    // the camera pads each row out to an alignment boundary, so a large
    // part of the buffer is padding that reads as zero. Averaging over it
    // dragged the brightness down toward nothing — the uploaded waveform
    // came back as 599 samples of `0.0`, which the server correctly called
    // "관류부족 0.00000". No amount of threshold tuning could have fixed a
    // signal that was never there.
    final int width = image.width;
    final int height = image.height;
    final yPlane = image.planes[0];
    final int yRowStride = yPlane.bytesPerRow;
    final int yPixelStride = yPlane.bytesPerPixel ?? 1;
    final Uint8List yBytes = yPlane.bytes;

    // Roughly 200 points, the same budget as before, but spread over the
    // frame as a grid rather than along the raw buffer.
    const int gridSide = 14;
    final int colStep = math.max(1, width ~/ gridSide);
    final int rowStep = math.max(1, height ~/ gridSide);

    for (int row = 0; row < height; row += rowStep) {
      for (int col = 0; col < width; col += colStep) {
        final int yIndex = row * yRowStride + col * yPixelStride;
        if (yIndex >= yBytes.length) continue;

        final double y = yBytes[yIndex].toDouble();
        final _Chroma chroma = _chromaAt(image, col, row);

        ySum += y;
        ySqSum += y * y;
        uSum += chroma.u;
        vSum += chroma.v;
        sampleCount++;
      }
    }

    if (sampleCount == 0) return;

    final avgY = ySum / sampleCount;
    final avgU = uSum / sampleCount;
    final avgV = vSum / sampleCount;
    final chromDiff = avgV - avgU;
    // How much the frame varies across itself. A finger pressed to the lens is
    // a flat wash of one colour; anything the camera can actually see is not.
    final variance = math.max(0.0, ySqSum / sampleCount - avgY * avgY);
    final spread = math.sqrt(variance);

    debugAvgY = avgY;
    debugAvgU = avgU;
    debugAvgV = avgV;
    debugDiff = chromDiff;
    debugSpread = spread;

    if (kDebugMode) {
      final now = DateTime.now();
      if (_lastDebugLogAt == null ||
          now.difference(_lastDebugLogAt!).inMilliseconds > 1000) {
        _lastDebugLogAt = now;
        debugPrint('PPG Y=${avgY.toStringAsFixed(1)} '
            'diff=${chromDiff.toStringAsFixed(1)} '
            'spread=${spread.toStringAsFixed(1)} '
            'finger=$isFingerDetected');
      }
    }

    updateFingerState(chromDiff, avgV, spread, avgY);

    if (isFingerDetected && !_ppgValueController.isClosed && !_isDisposed) {
      final now = DateTime.now();
      _ppgValueController.add(avgY);

      // A gap this wide is not a slow frame — the camera stalled or the app
      // went to the background, and the samples either side are not adjacent
      // in time. Start a new run rather than counting the gap.
      //
      // The bar is deliberately high. Splitting on every hiccup chops a good
      // measurement into pieces, and only the longest piece is uploaded, so an
      // over-eager split fails the reading outright. A whole second is long
      // enough that no frame rate we accept (10 fps and up) can produce it.
      final since = _lastSampleAt == null
          ? 0
          : now.difference(_lastSampleAt!).inMilliseconds;
      if (since >= 1000) {
        _startNewRun();
      } else if (since > 0) {
        _current.millis += since;
      }
      _lastSampleAt = now;
      // The server rejects anything past 30,000 samples, so stop growing at the
      // cap instead of building a request that is guaranteed to be refused.
      if (_current.samples.length < 30000) {
        _current.samples.add(avgY);
      }

      // Track moving average of avgY
      _yHistory.add(avgY);
      if (_yHistory.length > 20) _yHistory.removeAt(0);
      final movingAvgY =
          _yHistory.reduce((a, b) => a + b) / _yHistory.length;

      // Local maximum peak detection (rising -> falling transition) above moving average
      final bool isPeak =
          _prevY > _prevPrevY && _prevY > avgY && _prevY > (movingAvgY + 0.08);

      if (_peakTimestamps.isNotEmpty) {
        final diffMs = now.difference(_peakTimestamps.last).inMilliseconds;
        if (diffMs > 500 && diffMs < 1200 && isPeak) {
          _peakTimestamps.add(now);
          _rrIntervalsMs.add(diffMs.toDouble());
        } else if (diffMs >= 1200) {
          // Update reference timestamp when finger released for >= 1200ms
          _peakTimestamps.add(now);
        }
      } else if (isPeak) {
        _peakTimestamps.add(now);
      }

      _prevPrevY = _prevY;
      _prevY = avgY;
    }
  }

  /// Decides whether a finger is on the lens, with separate thresholds for
  /// latching on and dropping off.
  ///
  /// The old test — `chromDiff > 45 && avgV > 150` — was written against one
  /// phone with its torch already settled. Two things break it elsewhere:
  /// auto white balance pulls the red cast back toward neutral within a second
  /// of the torch coming on, dragging chromDiff down into the twenties, and a
  /// thin or cold fingertip is simply less red to begin with. Both give a
  /// signal that is perfectly measurable while never once meeting the bar, so
  /// the screen sat on "손가락을 올려주세요" forever.
  ///
  /// A single threshold also made contact flicker frame by frame, and since
  /// samples are only kept while contact holds, the waveform came out full of
  /// holes — which the server sees as a broken pulse and rejects.
  @visibleForTesting
  void updateFingerState(
      double chromDiff, double avgV, double spread, double avgY) {
    if (kIsWeb) {
      if (!isFingerDetected) _setFingerDetected(true);
      return;
    }

    // Room light and skin are far apart even after AWB has done its worst: an
    // uncovered lens sits near chromDiff 0-10, a covered one at 20 and up.
    //
    // Colour alone is not enough though — a warm-lit room passes it. What
    // separates the two is structure: covering the lens leaves a flat field,
    // while any real view has edges and shading. On the emulator, whose fake
    // camera renders a furnished room, colour alone latched on with no finger
    // anywhere near the device.
    //
    // The evenness test is a ratio, not a raw spread. A finger lit by the torch
    // is *bright*, and brightness scales the spread with it — the middle of the
    // frame is blown out while the edges fall away, so a perfectly good reading
    // can measure a raw spread in the forties. Dividing by the mean cancels
    // that out: the emulator's room sits at 0.43 (45 over 104) while a covered
    // lens stays well under 0.2 however bright it is.
    // Measured on a real fingertip against the torch: 붉은기 97, V 245,
    // evenness 0.27. The emulator's room, the nearest thing to a false
    // positive anyone has produced: 22, 140, 0.43.
    //
    // So colour decides. The two cases are four times apart on 붉은기 and the
    // thresholds sit in the gap with room on both sides. Evenness is kept only
    // as a loose sanity check — it was doing the deciding at 0.28, which a real
    // finger cleared by a hundredth, so contact flickered frame to frame and
    // the measurement never held.
    final evenness = avgY <= 0 ? 1.0 : spread / avgY;
    // Brightness has to be there at all. A finger lit by the torch is bright;
    // a dark frame is not a finger, it is a lens in the dark. Without this the
    // app happily counted down against black frames and uploaded a waveform
    // of zeros — the server had to be the one to notice, twenty seconds later.
    final litUp = avgY > 25.0;
    final looksLikeSkin =
        litUp && chromDiff > 35.0 && avgV > 150.0 && evenness < 0.45;
    // Deliberately looser than the entry bar. Once contact is established, a
    // momentary dip from pressure or a shifting finger should not throw away
    // the measurement in progress.
    final clearlyGone =
        avgY < 15.0 || chromDiff < 20.0 || avgV < 135.0 || evenness > 0.60;

    if (!isFingerDetected) {
      _contactFrames = looksLikeSkin ? _contactFrames + 1 : 0;
      // Roughly a fifth of a second. Long enough to ignore a red object
      // passing the lens, short enough that the user does not feel a lag.
      if (_contactFrames >= 5) {
        _releaseFrames = 0;
        _setFingerDetected(true);
      }
      return;
    }

    _releaseFrames = clearlyGone ? _releaseFrames + 1 : 0;
    if (_releaseFrames >= 10) {
      _contactFrames = 0;
      _setFingerDetected(false);
    }
  }

  /// Turns the torch on, quietly. Safe to call more than once.
  Future<void> _enableTorch() async {
    if (_isDisposed || _cameraController == null) return;
    try {
      await _cameraController!.setFlashMode(FlashMode.torch);
    } catch (e) {
      debugPrint('Flash torch unavailable: $e');
    }
  }

  /// Freezes exposure a moment after contact is established.
  ///
  /// By then the sensor has settled on the covered lens, so the lock holds the
  /// picture we actually want to measure rather than the room. That stops
  /// auto-exposure from riding out the pulse, which is a fraction of a percent
  /// of brightness and looks to the camera like an error to correct.
  ///
  /// Failures are ignored: some devices refuse, and drifting exposure is a far
  /// smaller problem than the black frames that locking too early produced.
  Future<void> _lockExposureOnContact() async {
    if (_exposureLocked || _isDisposed || _cameraController == null) return;
    _exposureLocked = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (_isDisposed || _cameraController == null) return;
      await _cameraController!.setExposureMode(ExposureMode.locked);
    } catch (e) {
      debugPrint('Exposure lock unavailable: $e');
    }
  }

  void _setFingerDetected(bool detected) {
    if (detected) {
      _lockExposureOnContact();
    }
    // Losing contact ends the run. Whatever comes back is a separate stretch
    // of signal, however quickly the finger returns.
    if (!detected && isFingerDetected) {
      _startNewRun();
    }
    isFingerDetected = detected;
    if (!_fingerStateController.isClosed && !_isDisposed) {
      _fingerStateController.add(detected);
    }
  }

  /// Closes the run in progress and opens a fresh one.
  ///
  /// An empty run is reused rather than piling up, so repeated contact loss
  /// before any sample arrives does not grow the list.
  void _startNewRun() {
    if (_current.samples.isEmpty) return;
    _runs.add(_ContactRun());
    _lastSampleAt = null;
  }

  /// Chroma at a pixel, addressed properly rather than guessed at.
  ///
  /// Chroma planes are half resolution in both directions, so the pixel at
  /// (col, row) reads from (col ~/ 2, row ~/ 2) of the chroma plane — and that
  /// plane has its own row stride and pixel stride. The old code took
  /// `bytes[(i ~/ 4) * bytesPerPixel]` off a flat index, which lands on an
  /// unrelated pixel as soon as either stride is not what it assumed.
  _Chroma _chromaAt(CameraImage image, int col, int row) {
    final planes = image.planes;
    if (planes.length < 2) {
      return _Chroma.neutral;
    }

    final int halfCol = col ~/ 2;
    final int halfRow = row ~/ 2;

    if (planes.length >= 3) {
      final u = planes[1];
      final v = planes[2];
      final int uIndex =
          halfRow * u.bytesPerRow + halfCol * (u.bytesPerPixel ?? 1);
      final int vIndex =
          halfRow * v.bytesPerRow + halfCol * (v.bytesPerPixel ?? 1);
      if (uIndex >= u.bytes.length || vIndex >= v.bytes.length) {
        return _Chroma.neutral;
      }
      return _Chroma(u.bytes[uIndex].toDouble(), v.bytes[vIndex].toDouble());
    }

    // Two planes: chroma is interleaved. bytesPerPixel is 2 for those, and the
    // pair order is V then U on Android's NV21.
    final uv = planes[1];
    final int base = halfRow * uv.bytesPerRow + halfCol * (uv.bytesPerPixel ?? 2);
    if (base + 1 >= uv.bytes.length) {
      return _Chroma.neutral;
    }
    return _Chroma(uv.bytes[base + 1].toDouble(), uv.bytes[base].toDouble());
  }

  void _startSimulationFallback() {
    _isCameraAvailable = false;
    isFingerDetected = true;
    if (!_fingerStateController.isClosed && !_isDisposed) {
      _fingerStateController.add(true);
    }
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      final now = DateTime.now();
      if (_peakTimestamps.isNotEmpty) {
        final diffMs = now.difference(_peakTimestamps.last).inMilliseconds;
        if (diffMs >= 550) {
          _peakTimestamps.add(now);
          _rrIntervalsMs.add(550.0 + (math.Random().nextDouble() * 180.0));
        }
      } else {
        _peakTimestamps.add(now);
      }
      if (!_ppgValueController.isClosed && !_isDisposed) {
        _ppgValueController.add(120.0 + math.sin(now.millisecondsSinceEpoch / 200.0) * 15.0);
      }
    });
  }

  PpgMeasurementResult computeResults() {
    int bpm = 75;
    double hrvSdnn = 28.5;
    int breathRpm = 14;

    if (_rrIntervalsMs.length >= 3) {
      final avgIntervalMs =
          _rrIntervalsMs.reduce((a, b) => a + b) / _rrIntervalsMs.length;
      bpm = (60000 / avgIntervalMs).round().clamp(55, 130);

      final mean = avgIntervalMs;
      final variance = _rrIntervalsMs
              .map((x) => math.pow(x - mean, 2))
              .reduce((a, b) => a + b) /
          _rrIntervalsMs.length;
      hrvSdnn = math.sqrt(variance).clamp(12.0, 65.0);
      breathRpm = (bpm / 5.2).round().clamp(10, 20);
    }

    final inhaleSec = (60.0 / breathRpm * 0.42).clamp(1.8, 4.5);
    final exhaleSec = (60.0 / breathRpm * 0.58).clamp(2.0, 6.0);

    final result = PpgMeasurementResult(
      bpm: bpm,
      hrvSdnnMs: double.parse(hrvSdnn.toStringAsFixed(1)),
      breathRpm: breathRpm,
      measuredInhaleSec: double.parse(inhaleSec.toStringAsFixed(1)),
      measuredExhaleSec: double.parse(exhaleSec.toStringAsFixed(1)),
      signalQuality: _rrIntervalsMs.length >= 3 ? 'Good' : 'Measuring',
    );

    latestResult = result;
    return result;
  }

  Future<void> stopCamera() async {
    _isDisposed = true;
    _simulationTimer?.cancel();
    if (_cameraController != null) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
      try {
        await _cameraController!.setFlashMode(FlashMode.off);
      } catch (_) {}
      await _cameraController!.dispose();
      _cameraController = null;
    }
    isFingerDetected = false;
    if (!_fingerStateController.isClosed) {
      _fingerStateController.add(false);
    }
  }

  void dispose() {
    stopCamera();
    if (!_ppgValueController.isClosed) _ppgValueController.close();
    if (!_fingerStateController.isClosed) _fingerStateController.close();
  }
}

/// One unbroken stretch of contact.
///
/// [millis] is the time the samples actually span, summed frame to frame, so
/// it is the honest denominator for the frame rate. It is not the difference
/// between the first and last timestamp — that would include any stall.
/// The two chroma values at one pixel. 128 each means "no colour information",
/// which is what a single-plane frame gets.
class _Chroma {
  const _Chroma(this.u, this.v);
  final double u;
  final double v;

  static const _Chroma neutral = _Chroma(128, 128);
}

class _ContactRun {
  final List<double> samples = [];
  int millis = 0;
}
