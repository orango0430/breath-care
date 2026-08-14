import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../utils/breathing_routine_model.dart';
import 'breathing_completion_screen.dart';

/// Guided Breathing Exercise Screen (호흡 진행 화면 - 사용자 측정 호흡에서 목표 템포로 적응형 유도)
class BreathingExerciseScreen extends StatefulWidget {
  final String title;
  final int totalCycles;
  final int targetDurationMinutes;
  final BreathingRoutineModel? routineModel;
  final double initialInhaleSec;
  final double initialExhaleSec;

  const BreathingExerciseScreen({
    super.key,
    this.title = '긴장 완화 호흡',
    this.totalCycles = 6,
    this.targetDurationMinutes = 5,
    this.routineModel,
    this.initialInhaleSec = 2.2,
    this.initialExhaleSec = 2.2,
  });

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _durationTimer;

  int elapsedSeconds = 80; // Default sample matching screenshot (01:20)
  int currentCycle = 2; // Default sample matching screenshot (2 / 6 사이클)
  bool isPlaying = true;
  int averageHrvBpmChange = -8;

  // Sound / vibration settings toggle
  bool isSoundEnabled = true;
  bool isVibrationEnabled = true;

  @override
  void initState() {
    super.initState();

    // Setup 10-second repeating animation for one full breathing cycle
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _startTimer();
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (isPlaying) {
        setState(() {
          elapsedSeconds++;
          // Cycle progression every 10 seconds
          if (elapsedSeconds % 10 == 0 && currentCycle < widget.totalCycles) {
            currentCycle++;
          }
        });
      }
    });
  }

  void _finishExercise() {
    _durationTimer?.cancel();
    _animController.stop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => BreathingCompletionScreen(
          durationString: _formattedTime,
          hrvChange: '$averageHrvBpmChange bpm',
        ),
      ),
    );
  }

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
      if (isPlaying) {
        _animController.repeat();
      } else {
        _animController.stop();
      }
    });
  }

  void _restartExercise() {
    setState(() {
      elapsedSeconds = 0;
      currentCycle = 1;
      isPlaying = true;
    });
    _animController.reset();
    _animController.repeat();
  }

  String get _formattedTime {
    final mins = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  // Active routine target values or default 4-7-8
  BreathingRoutineModel get _activeRoutine =>
      widget.routineModel ?? BreathingRoutineModel.fromHrv(24.5);

  // Ramp factor from 0.0 (cycle 1) to 1.0 (cycle N)
  double get _rampFactor {
    final n = widget.totalCycles;
    if (n <= 1) return 1.0;
    final k = (currentCycle - 1).clamp(0, n - 1);
    return k / (n - 1).toDouble();
  }

  double get _currentInhaleSec {
    final start = widget.initialInhaleSec;
    final target = _activeRoutine.targetInhale;
    return start + (target - start) * _rampFactor;
  }

  double get _currentHold1Sec {
    const start = 0.0;
    final target = _activeRoutine.targetHold1;
    return start + (target - start) * _rampFactor;
  }

  double get _currentExhaleSec {
    final start = widget.initialExhaleSec;
    final target = _activeRoutine.targetExhale;
    return start + (target - start) * _rampFactor;
  }

  double get _currentHold2Sec {
    const start = 0.0;
    final target = _activeRoutine.targetHold2;
    return start + (target - start) * _rampFactor;
  }

  double get _currentCycleTotalSec {
    return _currentInhaleSec + _currentHold1Sec + _currentExhaleSec + _currentHold2Sec;
  }

  /// Get current breathing phase ('들이마시기', '멈추기', '내쉬기', '휴식')
  String get _currentPhaseLabel {
    final val = _animController.value;
    final total = _currentCycleTotalSec;
    if (total <= 0) return '숨쉬기';

    final tInhale = _currentInhaleSec / total;
    final tHold1 = tInhale + (_currentHold1Sec / total);
    final tExhale = tHold1 + (_currentExhaleSec / total);

    if (val < tInhale) {
      return '들이마시기';
    } else if (val < tHold1) {
      return '멈추기';
    } else if (val < tExhale) {
      return '내쉬기';
    } else {
      return _activeRoutine.targetHold2 > 0 ? '멈추기' : '휴식';
    }
  }

  /// Get current instruction title text
  String get _currentInstructionText {
    final val = _animController.value;
    final total = _currentCycleTotalSec;
    if (total <= 0) return '편안하게 숨을 쉬어보세요';

    final tInhale = _currentInhaleSec / total;
    final tHold1 = tInhale + (_currentHold1Sec / total);
    final tExhale = tHold1 + (_currentExhaleSec / total);

    if (val < tInhale) {
      return '천천히 코로 숨을 들이마셔요 (${_currentInhaleSec.toStringAsFixed(1)}초)';
    } else if (val < tHold1) {
      return '숨을 잠시 멈추세요 (${_currentHold1Sec.toStringAsFixed(1)}초)';
    } else if (val < tExhale) {
      return '천천히 입으로 숨을 내쉬세요 (${_currentExhaleSec.toStringAsFixed(1)}초)';
    } else {
      return _activeRoutine.targetHold2 > 0
          ? '숨을 멈추고 몰입하세요 (${_currentHold2Sec.toStringAsFixed(1)}초)'
          : '편안하게 상태를 유지하세요';
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalCycles = widget.totalCycles;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // App Bar Header: Close Button + Title
              _buildHeader(context),
              const SizedBox(height: 20),

              // Segmented Cycle Progress Bar + "2 / 6 사이클"
              _buildCycleProgress(totalCycles),
              const SizedBox(height: 24),

              // Main Animated Instruction Title: "천천히 코로 숨을 들이마셔요" / "천천히 코로 숨을 내쉬세요"
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _currentInstructionText,
                  key: ValueKey<String>(_currentInstructionText),
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Wave Line & Ball Animation Canvas Area
              Expanded(
                child: Stack(
                  children: [
                    // Interactive Animated Custom Wave Painter
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _BreathingWavePainter(
                              progress: _animController.value,
                              phaseLabel: _currentPhaseLabel,
                            ),
                          );
                        },
                      ),
                    ),

                    // Reset / Restart Button on Bottom Right of Wave Canvas
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: _restartExercise,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.darkCharcoal.withAlpha(220),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.slateDarkGray.withAlpha(100),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.refresh_rounded,
                            color: AppColors.lightGray,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats Box: 소요 시간 (01:20) | 평균 심박 변화 (-8 bpm)
              _buildStatsCard(),
              const SizedBox(height: 20),

              // Bottom Control Bar: 호흡 설정 | Pause/Play | 호흡 종료
              _buildControlToolbar(),
              const SizedBox(height: 16),

              // Bottom Tag Pill: 현재 효과 긴장 완화 · 스트레스 감소
              _buildEffectTagPill(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Top App Bar Header with Close Icon & Screen Title
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.white,
            size: 26,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Text(
          widget.title,
          style: const TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(width: 32), // Spacer to center title
      ],
    );
  }

  /// Segmented Cycle Progress Bar (e.g. 5 segments) + Subtitle "2 / 6 사이클"
  Widget _buildCycleProgress(int totalCycles) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalCycles, (index) {
            final isFilled = index < currentCycle;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isFilled
                    ? AppColors.white
                    : AppColors.slateDarkGray.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          '$currentCycle / $totalCycles 사이클',
          style: const TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.lightGray,
          ),
        ),
      ],
    );
  }

  /// Stats Container Card showing Elapsed Time & Average Heart Rate Change
  Widget _buildStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(60),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Left: Elapsed Time (소요 시간)
          Expanded(
            child: Column(
              children: [
                const Text(
                  '소요 시간',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGray,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formattedTime,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 36,
            color: AppColors.slateDarkGray.withAlpha(80),
          ),

          // Right: Average HR Change (평균 심박 변화)
          Expanded(
            child: Column(
              children: [
                const Text(
                  '평균 심박 변화',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGray,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$averageHrvBpmChange bpm',
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightMint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Control Toolbar: 호흡 설정 | Play/Pause | 호흡 종료
  Widget _buildControlToolbar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Left Action: 호흡 설정
        GestureDetector(
          onTap: _showSettingsBottomSheet,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.slateDarkGray.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.lightGray,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '호흡 설정',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.lightGray,
                ),
              ),
            ],
          ),
        ),

        // Center Action: Large Pause / Play Button
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.slateDarkGray.withAlpha(120),
                width: 1.5,
              ),
            ),
            child: Icon(
              isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: AppColors.white,
              size: 36,
            ),
          ),
        ),

        // Right Action: 호흡 종료
        GestureDetector(
          onTap: _finishExercise,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.darkCharcoal,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.slateDarkGray.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: AppColors.lightGray,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '호흡 종료',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.lightGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bottom Status Tag Pill: 현재 효과 긴장 완화 · 스트레스 감소
  Widget _buildEffectTagPill() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(40),
          width: 0.8,
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '현재 효과  ',
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.lightGray,
            ),
          ),
          Text(
            '긴장 완화 · 스트레스 감소',
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Settings Bottom Sheet for customizing breathing preferences
  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCharcoal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slateDarkGray,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '호흡 가이드 설정',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    activeThumbColor: AppColors.lightMint,
                    title: const Text(
                      '안내 소리 효과',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 15,
                        color: AppColors.white,
                      ),
                    ),
                    value: isSoundEnabled,
                    onChanged: (val) {
                      setSheetState(() => isSoundEnabled = val);
                      setState(() {});
                    },
                  ),
                  SwitchListTile(
                    activeThumbColor: AppColors.lightMint,
                    title: const Text(
                      '진동 박자 알림',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 15,
                        color: AppColors.white,
                      ),
                    ),
                    value: isVibrationEnabled,
                    onChanged: (val) {
                      setSheetState(() => isVibrationEnabled = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightMint,
                        foregroundColor: AppColors.darkBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// CustomPainter that renders Viewport-Tracked Seamless Breathing Wave focused on the ball near screen center
class _BreathingWavePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final String phaseLabel;

  _BreathingWavePainter({
    required this.progress,
    required this.phaseLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final yBottom = h * 0.68;
    final yTop = h * 0.28;

    // Single cycle width (2.2x screen width)
    final cycleW = w * 2.2;

    // 1. Single Cycle Reference Geometry
    final singleCyclePath = Path()
      ..moveTo(0, yBottom)
      ..lineTo(cycleW * 0.12, yBottom)
      ..lineTo(cycleW * 0.38, yTop)    // Inhale
      ..lineTo(cycleW * 0.62, yTop)    // Hold
      ..lineTo(cycleW * 0.88, yBottom) // Exhale
      ..lineTo(cycleW, yBottom);        // Rest (seamlessly connects to next cycle!)

    final singleMetrics = singleCyclePath.computeMetrics().first;
    final singleLength = singleMetrics.length;

    // Calculate ball distance along single cycle
    final ballSingleDist = progress * singleLength;
    final tangent = singleMetrics.getTangentForOffset(ballSingleDist);
    if (tangent == null) return;
    final rawBallPos = tangent.position;

    // Ball target position near center of screen
    final ballScreenX = w * 0.42;
    final cameraOffsetX = ballScreenX - rawBallPos.dx;
    final screenBallPos = Offset(ballScreenX, rawBallPos.dy);

    // 2. Build Seamless Multi-Cycle Continuous Path (Cycle -1, 0, 1, 2)
    final multiCyclePath = Path();
    bool isFirst = true;

    for (int cycle = -1; cycle <= 2; cycle++) {
      final originX = cycle * cycleW;
      final k0 = Offset(originX, yBottom);
      final k1 = Offset(originX + cycleW * 0.12, yBottom);
      final k2 = Offset(originX + cycleW * 0.38, yTop);
      final k3 = Offset(originX + cycleW * 0.62, yTop);
      final k4 = Offset(originX + cycleW * 0.88, yBottom);
      final k5 = Offset(originX + cycleW, yBottom);

      if (isFirst) {
        multiCyclePath.moveTo(k0.dx, k0.dy);
        isFirst = false;
      } else {
        multiCyclePath.lineTo(k0.dx, k0.dy);
      }
      multiCyclePath.lineTo(k1.dx, k1.dy);
      multiCyclePath.lineTo(k2.dx, k2.dy);
      multiCyclePath.lineTo(k3.dx, k3.dy);
      multiCyclePath.lineTo(k4.dx, k4.dy);
      multiCyclePath.lineTo(k5.dx, k5.dy);
    }

    final multiMetrics = multiCyclePath.computeMetrics().first;
    final multiLength = multiMetrics.length;

    // Ball distance in multi-cycle metrics space (Cycle 0 starts at singleLength)
    final ballMultiDist = singleLength + ballSingleDist;

    // Save canvas state for camera tracking transformation
    canvas.save();
    canvas.translate(cameraOffsetX, 0);

    // 3. Draw Faint Seamless Base Track (희미한 전체 가이드 트랙)
    final baseTrackPaint = Paint()
      ..color = const Color(0xFF4A5248).withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(multiCyclePath, baseTrackPaint);

    // 4. Draw Continuous Unbroken Active Glowing Ribbon around the Ball (끊김 없는 매끄러운 빛나는 궤적)
    const backWindow = 280.0;
    const forwardWindow = 200.0;
    final startDist = (ballMultiDist - backWindow).clamp(0.0, multiLength);
    final endDist = (ballMultiDist + forwardWindow).clamp(0.0, multiLength);

    if (endDist > startDist) {
      final activeRibbonPath = multiMetrics.extractPath(startDist, endDist);
      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF5A6657).withAlpha(0),
            const Color(0xFF86AB80).withAlpha(200),
            const Color(0xFFE2FFDA),
            const Color(0xFF86AB80).withAlpha(160),
            const Color(0xFF5A6657).withAlpha(0),
          ],
          stops: const [0.0, 0.35, 0.55, 0.80, 1.0],
        ).createShader(Rect.fromLTWH(
          rawBallPos.dx - backWindow,
          0,
          backWindow + forwardWindow,
          h,
        ));

      canvas.drawPath(activeRibbonPath, activePaint);
    }

    canvas.restore();

    // 5. Draw Outer Halo Glow of Ball (화면 중앙 공)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE2FFDA).withAlpha(230),
          const Color(0xFF98E285).withAlpha(110),
          const Color(0xFF98E285).withAlpha(0),
        ],
      ).createShader(Rect.fromCircle(center: screenBallPos, radius: 28));
    canvas.drawCircle(screenBallPos, 28, glowPaint);

    // 6. Draw Inner Bright Core Ball
    final ballCorePaint = Paint()
      ..color = const Color(0xFFE2FFDA)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(screenBallPos, 10, ballCorePaint);

    // 7. Draw Phase Label Pill Beside Ball ("내쉬기", "들이마시기", etc.)
    final textPainter = TextPainter(
      text: TextSpan(
        text: phaseLabel,
        style: const TextStyle(
          fontFamily: AppFonts.pretendard,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFFE2FFDA),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = textPainter.width + 16;
    final pillHeight = textPainter.height + 8;
    final pillOffset = Offset(screenBallPos.dx + 16, screenBallPos.dy - 10);

    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillOffset.dx, pillOffset.dy, pillWidth, pillHeight),
      const Radius.circular(12),
    );
    final pillBgPaint = Paint()
      ..color = const Color(0xFF1F221E)
      ..style = PaintingStyle.fill;
    final pillBorderPaint = Paint()
      ..color = const Color(0xFF98E285).withAlpha(140)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawRRect(pillRRect, pillBgPaint);
    canvas.drawRRect(pillRRect, pillBorderPaint);

    textPainter.paint(
      canvas,
      Offset(pillOffset.dx + 8, pillOffset.dy + 4),
    );
  }

  @override
  bool shouldRepaint(covariant _BreathingWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phaseLabel != phaseLabel;
  }
}
