import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../utils/ppg_sensor_service.dart';
import '../utils/breathing_routine_model.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/measurement_service.dart';
import '../utils/schedule_storage_service.dart';
import 'measurement_result_screen.dart';

/// `analyzing` covers the round trip to the server: the take is finished but
/// the numbers are not back yet.
enum MeasurementStatus { waiting, measuring, analyzing, completed }

class ConditionMeasurementScreen extends StatefulWidget {
  final String? scheduleTitle;

  const ConditionMeasurementScreen({
    super.key,
    this.scheduleTitle,
  });

  @override
  State<ConditionMeasurementScreen> createState() =>
      _ConditionMeasurementScreenState();
}

class _ConditionMeasurementScreenState
    extends State<ConditionMeasurementScreen>
    with SingleTickerProviderStateMixin {
  // Whether to display the preparation guide modal overlay (Default false on entry)
  bool _showGuideSheet = false;

  // PageController for guide modal slides (0..2)
  final PageController _guidePageController = PageController();
  int _currentGuidePage = 0;

  // 3 Measurement Statuses: waiting (대기 중), measuring (측정 중), completed (측정 완료)
  MeasurementStatus _status = MeasurementStatus.waiting;
  double _progress = 0.0;
  int _secondsLeft = 20;

  // Animation controller for live continuous PPG waveform
  late AnimationController _waveAnimationController;
  Timer? _measurementTimer;

  // PpgSensorService & 3 Breathing Routines Mapping
  final PpgSensorService _ppgService = PpgSensorService();
  PpgMeasurementResult? _lastResult;
  BreathingRoutineModel? _recommendedRoutine;
  bool _isFingerCovered = true;

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _guidePageController.dispose();
    _waveAnimationController.dispose();
    _measurementTimer?.cancel();
    _ppgService.dispose();
    super.dispose();
  }

  void _closeGuideSheet() {
    setState(() {
      _showGuideSheet = false;
    });
  }

  void _openGuideSheet() {
    setState(() {
      _showGuideSheet = true;
      _currentGuidePage = 0;
    });
  }

  // Handle bottom action button click to cycle between waiting -> measuring -> completed -> Navigate to Analysis Result
  void _onBottomActionButtonPressed() async {
    if (_status == MeasurementStatus.waiting) {
      _checkCameraPermissionAndStart();
    } else if (_status == MeasurementStatus.measuring) {
      // Do not force completion on tap during measurement while waiting for finger
    } else if (_status == MeasurementStatus.completed) {
      final res = _lastResult ?? PpgMeasurementResult.randomSample();
      final routine = _recommendedRoutine ??
          BreathingRoutineModel.fromMeasurement(
            bpm: res.bpm,
            hrvSdnn: res.hrvSdnnMs,
          );

      // Complete schedule in storage
      await ScheduleStorageService.completeSchedule(widget.scheduleTitle ?? '');

      // Navigate to MeasurementResultScreen (측정 결과 화면) with result & routine
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MeasurementResultScreen(
            result: res,
            routine: routine,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  Future<void> _checkCameraPermissionAndStart() async {
    if (kIsWeb) {
      _startMeasurementProcess();
      return;
    }

    final status = await Permission.camera.status;

    if (status.isGranted) {
      _startMeasurementProcess();
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        _startMeasurementProcess();
      } else {
        _showPermissionDeniedDialog();
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    } else {
      _startMeasurementProcess();
    }
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCharcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '카메라 권한 필요',
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: AppColors.white,
          ),
        ),
        content: const Text(
          '손가락 맥박 측정을 위해 카메라 권한이 필요합니다.\n설정 화면에서 카메라 권한을 허용해 주세요.',
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.lightGray,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '취소',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                color: AppColors.slateGray,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightMint,
              foregroundColor: AppColors.darkBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '설정으로 이동',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startMeasurementProcess() {
    if (!mounted) return;
    setState(() {
      _status = MeasurementStatus.measuring;
      _secondsLeft = 20;
      _progress = 0.0;
      _isFingerCovered = kIsWeb;
    });
    if (!kIsWeb) {
      _ppgService.initializeCamera();
      _ppgService.fingerStateStream.listen((covered) {
        if (mounted) {
          setState(() {
            _isFingerCovered = covered;
            if (_isFingerCovered) {
              if (!_waveAnimationController.isAnimating) {
                _waveAnimationController.repeat();
              }
            } else {
              if (_waveAnimationController.isAnimating) {
                _waveAnimationController.stop();
              }
            }
          });
        }
      });
    } else {
      if (!_waveAnimationController.isAnimating) {
        _waveAnimationController.repeat();
      }
    }
    _startTimerSimulation();
  }

  void _startTimerSimulation() {
    _measurementTimer?.cancel();
    _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (!_isFingerCovered) {
        // Pause countdown while finger is not properly touching camera & flash!
        return;
      }
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
          _progress = (20 - _secondsLeft) / 20.0;
          if (kIsWeb) {
            // Live web simulation sample update. On a device there is nothing
            // to show yet — the numbers only exist once the server has seen
            // the waveform, and computing a preview here would put a second,
            // different answer on screen a moment before the real one.
            _lastResult = _ppgService.computeResults();
          }
        } else {
          _secondsLeft = 0;
          _progress = 1.0;
          _setCompletedState();
        }
      });
    });
  }

  Future<void> _setCompletedState() async {
    _measurementTimer?.cancel();

    final waveform = _ppgService.waveform;
    final fps = _ppgService.capturedFps;
    final durationSec = _ppgService.capturedDurationSec;
    _ppgService.stopCamera(); // Turn off LED flash torch automatically after 20s!

    if (kIsWeb) {
      // 웹(크롬) 시뮬레이션: 5대 카테고리 중 하나가 랜덤으로 반환되도록 설정!
      _applyResult(PpgMeasurementResult.randomSample());
      return;
    }

    setState(() => _status = MeasurementStatus.analyzing);

    // The phone only carries the waveform. Heart rate, HRV and the condition
    // score are all worked out server side, so every phone gets the same
    // answer and the algorithm can be corrected without shipping a new build.
    try {
      final measurement = ApiClient.instance.isLoggedIn
          ? await MeasurementService.instance
              .submit(samples: waveform, fps: fps, durationSec: durationSec)
          : await MeasurementService.instance
              .analyzeAsGuest(samples: waveform, fps: fps, durationSec: durationSec);

      if (!mounted) return;
      _applyResult(PpgMeasurementResult.fromServer(
        hr: measurement.hr ?? 0,
        hrv: measurement.hrv ?? 0,
        conditionScore: measurement.conditionScore,
        quality: measurement.quality.name.toUpperCase(),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      // POOR_SIGNAL_QUALITY is the expected outcome of a bad take, not a
      // crash. Send the user back to measure again instead of inventing a
      // number — a made-up reading is worse than no reading in a health app.
      _showRetakePrompt(e.message);
    }
  }

  void _applyResult(PpgMeasurementResult result) {
    _lastResult = result;
    _recommendedRoutine = BreathingRoutineModel.fromMeasurement(
      bpm: result.bpm,
      hrvSdnn: result.hrvSdnnMs,
    );
    if (!mounted) return;
    setState(() {
      _status = MeasurementStatus.completed;
      _secondsLeft = 0;
      _progress = 1.0; // 100% complete
    });
  }

  void _showRetakePrompt(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.coralRed,
        duration: const Duration(seconds: 4),
      ),
    );
    setState(() {
      _status = MeasurementStatus.waiting;
      _secondsLeft = 20;
      _progress = 0.0;
      _lastResult = null;
      _recommendedRoutine = null;
    });
  }

  void _resetToWaitingState() {
    _measurementTimer?.cancel();
    setState(() {
      _status = MeasurementStatus.waiting;
      _secondsLeft = 20;
      _progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Stack(
            children: [
              // Main Measurement Screen Body
              Column(
                children: [
                  const SizedBox(height: 12),
                  // Header Row: Back Arrow + Guide Icon
                  _buildHeaderRow(),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          if (_status == MeasurementStatus.measuring && !_isFingerCovered) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.coralRed.withAlpha(230),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 1.2),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '손가락이 렌즈에서 떨어졌습니다!\n후면 카메라와 플래시에 손가락을 밀착해 주세요.',
                                      style: TextStyle(
                                        fontFamily: AppFonts.pretendard,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Center Timer Arc & Ring (20 sec / 7 sec left / 0 sec left)
                          _buildTimerArcRing(),
                          const SizedBox(height: 16),

                          // Instruction Subtext (대기 중 vs 측정 중 vs 측정 완료)
                          Text(
                            _getInstructionText(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: AppFonts.pretendard,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.lightGray,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sensor Data Cards Row: HR & Signal
                          _buildSensorCardsRow(),
                          const SizedBox(height: 16),

                          // Waveform Chart / Live PPG Waveform Box
                          _buildWaveformGraphBox(),
                          const SizedBox(height: 24),

                          // Bottom Action Button (대기 중 / 측정 중... 67% / 측정 완료)
                          _buildBottomActionButton(),
                          const SizedBox(height: 12),

                          // Cancel Button
                          TextButton(
                            onPressed: () {
                              if (_status != MeasurementStatus.waiting) {
                                _resetToWaitingState();
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text(
                              '취소',
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.slateGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Preparation Guide Sheet Modal Overlay (컨디션 측정_측정 전)
              if (_showGuideSheet) _buildPreparationGuideOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  String _getInstructionText() {
    switch (_status) {
      case MeasurementStatus.waiting:
        return '카메라와 플래시 위에\n손가락을 가만히 올려주세요';
      case MeasurementStatus.measuring:
        return _isFingerCovered
            ? '손을 떼지 말고\n그대로 유지해주세요'
            : '카메라와 플래시 위에\n손가락을 살포시 덮어주세요';
      case MeasurementStatus.analyzing:
        return '측정한 파형을 분석하고 있어요\n잠시만 기다려주세요';
      case MeasurementStatus.completed:
        return '측정이 끝났어요\n결과 화면으로 이동할게요';
    }
  }

  /// 1. Top Header Row: Back Arrow + Guide Icon
  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.white,
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.darkCharcoal,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.slateDarkGray.withAlpha(60),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: _openGuideSheet,
            icon: const Icon(
              Icons.collections_bookmark_outlined,
              color: AppColors.lightGray,
              size: 20,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  /// 2. Center Timer Arc & Ring Graphic (20 sec vs 7 sec left vs 0 sec left)
  Widget _buildTimerArcRing() {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dotted Arc Painter (0 to 100 with mint progress highlights)
          CustomPaint(
            size: const Size(240, 240),
            painter: _DottedArcPainter(
              status: _status,
              progress: _status == MeasurementStatus.waiting ? 0.0 : _progress,
            ),
          ),

          // Inner Dark Circle Container with Circular Line passing through White Dot
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.darkBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circular Ring Track & Progress Painter (Line passes through white dot)
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _TimerProgressRingPainter(
                    status: _status,
                    progress: _progress,
                    isCompleted: _status == MeasurementStatus.completed,
                  ),
                ),

                // Center Timer Text (20 vs 7 sec left vs 0 sec left)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      _status == MeasurementStatus.waiting
                          ? '20'
                          : '$_secondsLeft',
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 44,
                        fontWeight: FontWeight.w400,
                        color: AppColors.lightMint,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _status == MeasurementStatus.waiting ? 'sec' : 'sec left',
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Sensor Cards Row: HR & Signal (Real BPM & Good)
  Widget _buildSensorCardsRow() {
    final hasRealBpm = _status != MeasurementStatus.waiting &&
        _isFingerCovered &&
        _lastResult != null &&
        _lastResult!.signalQuality == 'Good';

    final isMeasuring = _status != MeasurementStatus.waiting && _isFingerCovered;

    return Row(
      children: [
        // HR Card (Real measured bpm only, -- when calibrating or detached)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.slateDarkGray.withAlpha(50),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          'HR',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '심박수',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.slateGray,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.favorite_rounded,
                      color: hasRealBpm ? AppColors.coralRed : AppColors.slateGray,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hasRealBpm ? '${_lastResult!.bpm}' : '--',
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'bpm',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.slateGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Signal Card (Good when measuring or completed)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.slateDarkGray.withAlpha(50),
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Signal',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '신호 품질',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.slateGray,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.signal_cellular_alt_rounded,
                      color: AppColors.slateGray,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  isMeasuring ? (hasRealBpm ? 'Good' : '측정 중') : '-',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: hasRealBpm ? 22 : 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 4. Waveform Chart / Live PPG Waveform Box
  Widget _buildWaveformGraphBox() {
    return Container(
      width: double.infinity,
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(50),
          width: 0.8,
        ),
      ),
      child: AnimatedBuilder(
        animation: _waveAnimationController,
        builder: (context, child) {
          return CustomPaint(
            painter: _PpgWaveformPainter(
              showWave: _status != MeasurementStatus.waiting && _isFingerCovered,
              animationValue: _waveAnimationController.value,
            ),
          );
        },
      ),
    );
  }

  /// 5. Bottom Action Button (손가락 인식 대기 중... / 측정 중... (67%) / 측정 완료)
  Widget _buildBottomActionButton() {
    String buttonText;
    Color buttonBgColor;
    Color buttonTextColor;

    switch (_status) {
      case MeasurementStatus.waiting:
        buttonText = '손가락 인식 대기 중... (터치하여 측정 시작)';
        buttonBgColor = AppColors.darkCharcoal;
        buttonTextColor = AppColors.slateGray;
        break;
      case MeasurementStatus.measuring:
        buttonText = '측정 중... (${(_progress * 100).toInt()}%)';
        buttonBgColor = AppColors.darkCharcoal;
        buttonTextColor = AppColors.lightMint;
        break;
      case MeasurementStatus.analyzing:
        buttonText = '분석 중...';
        buttonBgColor = AppColors.darkCharcoal;
        buttonTextColor = AppColors.lightMint;
        break;
      case MeasurementStatus.completed:
        buttonText = '측정 완료';
        buttonBgColor = const Color(0xFF455747); // Dark mint green filled matching design
        buttonTextColor = AppColors.white;
        break;
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: InkWell(
        onTap: _onBottomActionButtonPressed,
        borderRadius: BorderRadius.circular(27),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: buttonBgColor,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: AppColors.slateDarkGray.withAlpha(50),
              width: 0.8,
            ),
          ),
          child: Stack(
            children: [
              // Progress Fill background when measuring
              if (_status == MeasurementStatus.measuring)
                FractionallySizedBox(
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF455747),
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                ),

              // Button Text
              Center(
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: buttonTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 6. Preparation Guide Sheet Overlay (컨디션 측정_측정 전)
  Widget _buildPreparationGuideOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _closeGuideSheet,
        child: Container(
          color: Colors.black.withAlpha(170),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // Prevent tap through
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: double.infinity,
                height: 430,
                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF27292D),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.slateDarkGray.withAlpha(60),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xB3000000), // Rich dark drop shadow
                      blurRadius: 36,
                      spreadRadius: 4,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 1. Full Bleed Grey Background Image PageView (Matching screenshot)
                    PageView(
                      controller: _guidePageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentGuidePage = index;
                        });
                      },
                      children: [
                        _buildGuideSlide(
                          imagePath: 'assets/images/guide_1.png',
                          title: '손끝으로 카메라와\n플래시를 완전히 덮어주세요',
                          subtitle: '검지 또는 중지 손가락 끝으로\n렌즈 전체를 부드럽게 덮어주세요.',
                        ),
                        _buildGuideSlide(
                          imagePath: 'assets/images/guide_2.png',
                          title: '플래시가\n자동으로 켜집니다',
                          subtitle: '밝은 빛이 손가락 속 혈류에\n반사되는 정도를 감지해요.',
                        ),
                        _buildGuideSlide(
                          imagePath: 'assets/images/guide_3.png',
                          title: '20초 동안 손가락을\n고정하세요',
                          subtitle: '손가락이 이탈하거나 흔들리면\n측정에 중단될 수 있어요.',
                          isScaledDown: true,
                        ),
                      ],
                    ),

                    // 2. Fixed Top Header Title: "준비 방법" (Fixed at top center)
                    const Positioned(
                      top: 22,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          '준비 방법',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),

                    // 3. Fixed Bottom Right: "건너뛰기" Button (Positioned at bottom right like screenshot)
                    Positioned(
                      right: 24,
                      bottom: 18,
                      child: InkWell(
                        onTap: _closeGuideSheet,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 6.0),
                          child: Text(
                            '건너뛰기',
                            style: TextStyle(
                              fontFamily: AppFonts.pretendard,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.white.withAlpha(140),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSlide({
    required String imagePath,
    required String title,
    required String subtitle,
    bool isScaledDown = false,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Solid Dark Grey Base Color matching attached screenshot
        Container(
          color: const Color(0xFF27292D),
        ),

        // Background Guide Image
        Transform.scale(
          scale: isScaledDown ? 0.85 : 1.0,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF27292D),
                alignment: Alignment.center,
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white.withAlpha(60),
                  size: 64,
                ),
              );
            },
          ),
        ),

        // Grey Vignette Gradient Overlay (Matching attached screenshot)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF27292D).withAlpha(180),
                Colors.transparent,
                const Color(0xFF27292D).withAlpha(170),
                const Color(0xFF27292D).withAlpha(235),
              ],
              stops: const [0.0, 0.28, 0.60, 1.0],
            ),
          ),
        ),

        // Text & Dots Content Overlay vertically centered over the middle of the photo!
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 24, right: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),

                // Title: 손끝으로 카메라와 플래시를 완전히 덮어주세요
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle: 검지 또는 중지 손가락 끝으로 렌즈 전체를 부드럽게 덮어주세요.
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withAlpha(185),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),

                // 3 Page Dots Indicator centered horizontally below subtitle!
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isSelected = _currentGuidePage == index;
                    return GestureDetector(
                      onTap: () {
                        _guidePageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4.0, vertical: 4.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 8 : 6,
                          height: isSelected ? 8 : 6,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.white.withAlpha(90),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// CustomPainter for Circular Ring Track Line and Traveling White Dot (Line passes directly through the white dot)
class _TimerProgressRingPainter extends CustomPainter {
  final MeasurementStatus status;
  final double progress;
  final bool isCompleted;

  _TimerProgressRingPainter({
    required this.status,
    required this.progress,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8.0;

    // 1. Background Circular Track Line (Passing directly through the white dot center)
    final trackPaint = Paint()
      ..color = AppColors.slateDarkGray.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, radius, trackPaint);

    const startAngle = -math.pi / 2; // 12 o'clock top position

    if (status == MeasurementStatus.waiting) {
      // 2. Default Waiting State: Draw White Dot at 12 o'clock directly ON the circle line
      final dotX = center.dx + radius * math.cos(startAngle);
      final dotY = center.dy + radius * math.sin(startAngle);

      final dotPaint = Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), 4.5, dotPaint);
    } else {
      // 3. Measuring or Completed State: Draw Arc + Traveling White Dot
      final sweepAngle = 2 * math.pi * progress;

      final arcPaint = Paint()
        ..color = isCompleted ? AppColors.lightMint : AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );

      // Tip Dot on progress ring
      final endX = center.dx + radius * math.cos(startAngle + sweepAngle);
      final endY = center.dy + radius * math.sin(startAngle + sweepAngle);

      final dotPaint = Paint()
        ..color = isCompleted ? AppColors.lightMint : AppColors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(endX, endY), 4.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerProgressRingPainter oldDelegate) =>
      oldDelegate.status != status ||
      oldDelegate.progress != progress ||
      oldDelegate.isCompleted != isCompleted;
}

/// CustomPainter for Outer Dotted Arc with Mint Progress Glow (all 19 dots mint when completed)
class _DottedArcPainter extends CustomPainter {
  final MeasurementStatus status;
  final double progress;

  _DottedArcPainter({required this.status, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const arcRadius = 104.0;
    const totalDots = 19;

    const startAngle = math.pi * 0.86;
    const sweepAngle = math.pi * 1.28;

    double firstX = 0;
    double firstY = 0;
    double lastX = 0;
    double lastY = 0;

    final darkDotPaint = Paint()
      ..color = const Color(0xFF5A5C63)
      ..style = PaintingStyle.fill;

    final whiteDotPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;

    final mintDotPaint = Paint()
      ..color = AppColors.lightMint
      ..style = PaintingStyle.fill;

    final int activeDotCount = status == MeasurementStatus.completed
        ? totalDots
        : (status == MeasurementStatus.measuring ? (progress * (totalDots - 1)).round() : 0);

    for (int i = 0; i < totalDots; i++) {
      final angle = startAngle + (i / (totalDots - 1)) * sweepAngle;
      final x = center.dx + arcRadius * math.cos(angle);
      final y = center.dy + arcRadius * math.sin(angle);

      if (i == 0) {
        firstX = x;
        firstY = y;
      }
      if (i == totalDots - 1) {
        lastX = x;
        lastY = y;
      }

      final isTopDot = i == 9;
      final isProgressActive = status == MeasurementStatus.completed || (status == MeasurementStatus.measuring && i <= activeDotCount);

      Paint paintToUse;
      if (isProgressActive) {
        paintToUse = mintDotPaint;
      } else if (isTopDot) {
        paintToUse = whiteDotPaint;
      } else {
        paintToUse = darkDotPaint;
      }

      canvas.drawCircle(
        Offset(x, y),
        isProgressActive ? 3.5 : (isTopDot ? 3.8 : 2.8),
        paintToUse,
      );
    }

    const textStyle = TextStyle(
      fontFamily: AppFonts.pretendard,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFF5A5C63),
    );

    final zeroPainter = TextPainter(
      text: const TextSpan(text: '0', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    zeroPainter.layout();
    zeroPainter.paint(
      canvas,
      Offset(firstX - zeroPainter.width / 2, firstY + 12),
    );

    final hundredPainter = TextPainter(
      text: const TextSpan(text: '100', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    hundredPainter.layout();
    hundredPainter.paint(
      canvas,
      Offset(lastX - hundredPainter.width / 2, lastY + 12),
    );
  }

  @override
  bool shouldRepaint(covariant _DottedArcPainter oldDelegate) =>
      oldDelegate.status != status || oldDelegate.progress != progress;
}

/// CustomPainter for PPG Sensor Waveform Box Dotted Grid & Live Continuous ECG Wave Animation
class _PpgWaveformPainter extends CustomPainter {
  final bool showWave;
  final double animationValue;

  _PpgWaveformPainter({
    required this.showWave,
    required this.animationValue,
  });

  // Normalized Keypoints (normX: 0.0 .. 1.0, normY: 0.0 .. 1.0)
  // Exact 1-cycle heartbeat complex matching the reference design image!
  static const List<Offset> _normKeypoints = [
    Offset(0.00, 0.50), // Start baseline
    Offset(0.07, 0.50),
    Offset(0.12, 0.72), // 1st Dip down (gridLine 6)
    Offset(0.16, 0.27), // 1st High Peak up (gridLine 2)
    Offset(0.20, 0.50), // Back to baseline
    Offset(0.31, 0.50), // Flat
    Offset(0.35, 0.38), // 2nd Peak up (gridLine 3)
    Offset(0.39, 0.64), // 2nd Dip down (gridLine 5)
    Offset(0.43, 0.50), // Back to baseline
    Offset(0.48, 0.50), // Flat
    Offset(0.52, 0.64), // 3rd Dip down (gridLine 5)
    Offset(0.56, 0.38), // 3rd Peak up (gridLine 3)
    Offset(0.60, 0.50), // Back to baseline
    Offset(0.68, 0.50), // Flat
    Offset(0.72, 0.83), // 4th Deep Valley Dip down (gridLine 7 - lowest!)
    Offset(0.76, 0.27), // 4th Highest Peak up (gridLine 2 - highest!)
    Offset(0.80, 0.50), // Back to baseline
    Offset(0.86, 0.50), // Flat
    Offset(0.90, 0.38), // 5th Peak up (gridLine 3)
    Offset(0.94, 0.65), // 5th Dip down (gridLine 5)
    Offset(0.97, 0.50), // Back to baseline
    Offset(1.00, 0.50), // End baseline (seamlessly connects to 0.00!)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Dotted Grid Lines (EXACTLY 6 horizontal dotted lines matching design image)
    final gridPaint = Paint()
      ..color = const Color(0xFF5A5F69).withAlpha(130)
      ..style = PaintingStyle.fill;

    const lineCount = 6;
    final lineSpacing = h / (lineCount + 1);
    const dotRadius = 1.1;
    const dotSpacing = 7.0;

    for (int i = 1; i <= lineCount; i++) {
      final y = i * lineSpacing;
      for (double x = 12; x <= w - 12; x += dotSpacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, gridPaint);
      }
    }

    if (!showWave) return;

    // 2. Seamless Infinite Repeating Waveform with Gradient Glow & Butter-Smooth Jitter-Free Path
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF566253), // Left: Muted olive slate
          Color(0xFF8BB57F), // Transition
          Color(0xFFD6F5BD), // Center / Peak: Glowing bright sage mint
          Color(0xFFA1C694), // Right: Soft green
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path();
    const cycleW = 330.0;
    // Subpixel continuous smooth leftward shift
    final shiftX = -animationValue * cycleW;

    bool isFirst = true;
    for (double cycleStart = -cycleW; cycleStart <= w + cycleW; cycleStart += cycleW) {
      for (final kp in _normKeypoints) {
        final x = cycleStart + kp.dx * cycleW + shiftX;
        final y = h * kp.dy;

        if (isFirst) {
          path.moveTo(x, y);
          isFirst = false;
        } else {
          path.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _PpgWaveformPainter oldDelegate) =>
      oldDelegate.showWave != showWave ||
      oldDelegate.animationValue != animationValue;
}
