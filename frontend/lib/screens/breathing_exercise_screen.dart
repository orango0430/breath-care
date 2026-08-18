import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../utils/breathing_routine_model.dart';
import 'breathing_completion_screen.dart';

/// Guided Breathing Exercise Screen with 1-Minute Scientific Adaptive Entrainment Engine (카메라 측정 템포 -> 1분간 4-7-8 점진 유도)
class BreathingExerciseScreen extends StatefulWidget {
  final String title;
  final int totalCycles;
  final int targetDurationMinutes;
  final BreathingRoutineModel? routineModel;
  final double initialInhaleSec;
  final double initialExhaleSec;
  final String bgImagePath;

  const BreathingExerciseScreen({
    super.key,
    this.title = '4-7-8 호흡',
    this.bgImagePath = 'assets/images/bg_breath_478.png',
    this.totalCycles = 6,
    this.targetDurationMinutes = 5,
    this.routineModel,
    this.initialInhaleSec = 2.0, // Measured initial inhale tempo
    this.initialExhaleSec = 2.0, // Measured initial exhale tempo
  });

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _durationTimer;

  int elapsedSeconds = 0; // Starts from 00:00
  int currentCycle = 1;
  bool isPlaying = true;
  int averageHrvBpmChange = -8;

  // 1-Minute Scientific Transition Duration (60 Seconds)
  static const double _adaptiveRampSeconds = 60.0;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_currentCycleTotalSec * 1000).round()),
    );

    _runCycleAnimation();
    _startTimer();
  }

  /// Run continuous repeating cycle animation dynamically updating duration per cycle
  void _runCycleAnimation() {
    final cycleDurationMs = (_currentCycleTotalSec * 1000).round();
    _animController.duration = Duration(milliseconds: cycleDurationMs);
    _animController.forward(from: 0.0).then((_) {
      if (mounted && isPlaying) {
        _runCycleAnimation();
      }
    });
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (isPlaying) {
        setState(() {
          elapsedSeconds++;
          final cycleSec = _currentCycleTotalSec.round();
          if (cycleSec > 0 && elapsedSeconds % cycleSec == 0 && currentCycle < widget.totalCycles) {
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
          title: widget.title,
          bgImagePath: widget.bgImagePath,
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
        _runCycleAnimation();
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
    _runCycleAnimation();
  }

  String get _formattedTime {
    final mins = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  /// 60-Second Linear Progress Ratio (0.0 at 0s -> 1.0 at 60s)
  double get _adaptiveProgress {
    return (elapsedSeconds / _adaptiveRampSeconds).clamp(0.0, 1.0);
  }

  /// Real-time Inhale Duration (Starts at initialInhaleSec e.g. 2.0s -> Ramps to 4.0s over 60s)
  double get _currentInhaleSec {
    const targetInhale = 4.0;
    return widget.initialInhaleSec + (targetInhale - widget.initialInhaleSec) * _adaptiveProgress;
  }

  /// Real-time Hold Duration (Starts at 0.0s -> Ramps to 7.0s over 60s)
  double get _currentHoldSec {
    const targetHold = 7.0;
    return 0.0 + (targetHold - 0.0) * _adaptiveProgress;
  }

  /// Real-time Exhale Duration (Starts at initialExhaleSec e.g. 2.0s -> Ramps to 8.0s over 60s)
  double get _currentExhaleSec {
    const targetExhale = 8.0;
    return widget.initialExhaleSec + (targetExhale - widget.initialExhaleSec) * _adaptiveProgress;
  }

  /// Current Total Cycle Duration (Starts at ~4.0s -> Ramps to 19.0s)
  double get _currentCycleTotalSec {
    return _currentInhaleSec + _currentHoldSec + _currentExhaleSec;
  }

  /// Get current phase label matching 4-7-8 stages ("들숨", "참기", "날숨")
  String get _currentPhaseLabel {
    final val = _animController.value;
    final total = _currentCycleTotalSec;
    if (total <= 0) return '들숨';

    final rInhale = _currentInhaleSec / total;
    final rHold = (_currentInhaleSec + _currentHoldSec) / total;

    if (val < rInhale) {
      return '들숨';
    } else if (val < rHold) {
      return '참기';
    } else {
      return '날숨';
    }
  }

  /// Subtext Guide message changing dynamically after 60s transition
  String get _guideSubtext {
    if (elapsedSeconds < 60) {
      return '회원님의 컨디션에 맞춰 1분간 조율 중이에요';
    } else {
      return '안정적인 4-7-8 호흡이 진행 중이에요';
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
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image
          Image.asset(
            widget.bgImagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C3440), Color(0xFF1E2228)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              );
            },
          ),

          // 2. Dark Overlay for contrast & readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withAlpha(120),
                  Colors.black.withAlpha(170),
                  Colors.black.withAlpha(220),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 3. Screen Layout Content
          SafeArea(
            child: ResponsiveContainer(
              maxWidth: 600,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                children: [
                  // Top Header Row (Back Circle Button | Title | Refresh Circle Button)
                  _buildHeader(context),
                  const SizedBox(height: 16),

                  // Middle Animated Wave Canvas (1-Minute Adaptive Entrainment Calibrated Wave)
                  Expanded(
                    child: Stack(
                      children: [
                        // Vertical Stage Dotted Lines & Labels
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _StageDottedLinesPainter(
                              inhaleSec: _currentInhaleSec,
                              holdSec: _currentHoldSec,
                              exhaleSec: _currentExhaleSec,
                            ),
                          ),
                        ),

                        // Exact Calibrated Wave & Glowing Ball Painter
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: _BreathingWavePainter(
                                  progress: _animController.value,
                                  phaseLabel: _currentPhaseLabel,
                                  inhaleSec: _currentInhaleSec,
                                  holdSec: _currentHoldSec,
                                  exhaleSec: _currentExhaleSec,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Subtext Guide: "회원님의 컨디션에 맞춰 1분간 조율 중이에요" -> "안정적인 4-7-8 호흡이 진행 중이에요"
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _guideSubtext,
                      key: ValueKey<String>(_guideSubtext),
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFB0B4BC),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Timer Display: 00:00
                  Text(
                    _formattedTime,
                    style: GoogleFonts.outfit(
                      fontSize: 38,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Bottom Controls Toolbar: [ Center Translucent Pause Circle ] + [ Right 종료하기 ]
                  _buildBottomToolbar(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Header Bar
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Translucent Circle Back Button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),

        // Title: 4-7-8 호흡
        Text(
          widget.title,
          style: const TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            letterSpacing: 0.2,
          ),
        ),

        // Right Translucent Circle Restart Button
        GestureDetector(
          onTap: _restartExercise,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom Control Toolbar
  Widget _buildBottomToolbar() {
    return SizedBox(
      height: 64,
      child: Stack(
        children: [
          // Center Large Translucent Pause/Play Circle Button
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(60),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withAlpha(80),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
            ),
          ),

          // Right End Text Button: 종료하기
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _finishExercise,
              child: const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Text(
                  '종료하기',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical Stage Dotted Lines & Labels Painter
class _StageDottedLinesPainter extends CustomPainter {
  final double inhaleSec;
  final double holdSec;
  final double exhaleSec;

  _StageDottedLinesPainter({
    required this.inhaleSec,
    required this.holdSec,
    required this.exhaleSec,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final total = inhaleSec + holdSec + exhaleSec;
    if (total <= 0) return;

    final x1 = w * (inhaleSec / total);
    final x2 = w * ((inhaleSec + holdSec) / total);

    final linePaint = Paint()
      ..color = Colors.white.withAlpha(50)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical Dotted Lines at stage transitions
    _drawDottedVerticalLine(canvas, Offset(x1, h * 0.12), h * 0.70, linePaint);
    _drawDottedVerticalLine(canvas, Offset(x2, h * 0.12), h * 0.70, linePaint);

    const textStyleHeader = TextStyle(
      fontFamily: AppFonts.pretendard,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    const textStyleSub = TextStyle(
      fontFamily: AppFonts.pretendard,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: Color(0xFFD0D4DC),
    );

    // Header Stage Labels ("4초 들이마시기", "7초 멈추기")
    final inhaleText = '${inhaleSec.toStringAsFixed(0)}초 들이마시기';
    final tpInhale = TextPainter(
      text: TextSpan(text: inhaleText, style: textStyleHeader),
      textDirection: TextDirection.ltr,
    )..layout();
    tpInhale.paint(canvas, Offset((x1 - tpInhale.width / 2).clamp(10, w - tpInhale.width - 10), h * 0.22));

    final holdText = '${holdSec.toStringAsFixed(0)}초 멈추기';
    final tpHold = TextPainter(
      text: TextSpan(text: holdText, style: textStyleSub),
      textDirection: TextDirection.ltr,
    )..layout();
    tpHold.paint(canvas, Offset((x2 + 12).clamp(10, w - tpHold.width - 10), h * 0.22));

    // Bottom Dotted Stage Labels ("4초", "7초")
    final tp4s = TextPainter(
      text: TextSpan(text: '${inhaleSec.toStringAsFixed(0)}초', style: textStyleSub),
      textDirection: TextDirection.ltr,
    )..layout();
    tp4s.paint(canvas, Offset(x1 - tp4s.width / 2, h * 0.62));

    final tp7s = TextPainter(
      text: TextSpan(text: '${holdSec.toStringAsFixed(0)}초', style: textStyleSub),
      textDirection: TextDirection.ltr,
    )..layout();
    tp7s.paint(canvas, Offset(x2 + 10, h * 0.62));
  }

  void _drawDottedVerticalLine(Canvas canvas, Offset start, double height, Paint paint) {
    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = start.dy;
    final endY = start.dy + height;

    while (startY < endY) {
      canvas.drawLine(
        Offset(start.dx, startY),
        Offset(start.dx, (startY + dashHeight).clamp(startY, endY)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _StageDottedLinesPainter oldDelegate) {
    return oldDelegate.inhaleSec != inhaleSec ||
        oldDelegate.holdSec != holdSec ||
        oldDelegate.exhaleSec != exhaleSec;
  }
}

/// 1-Minute Scientific Adaptive Wave & Glowing Ball Painter
class _BreathingWavePainter extends CustomPainter {
  final double progress;
  final String phaseLabel;
  final double inhaleSec;
  final double holdSec;
  final double exhaleSec;

  _BreathingWavePainter({
    required this.progress,
    required this.phaseLabel,
    required this.inhaleSec,
    required this.holdSec,
    required this.exhaleSec,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final yBottom = h * 0.68;
    final yTop = h * 0.28;
    final cycleW = w * 2.0;

    final total = inhaleSec + holdSec + exhaleSec;
    if (total <= 0) return;

    final rInhale = inhaleSec / total;
    final rHold = (inhaleSec + holdSec) / total;

    // Single Cycle Reference Path
    final singleCyclePath = Path()
      ..moveTo(0, yBottom)
      ..lineTo(cycleW * rInhale, yTop)
      ..lineTo(cycleW * rHold, yTop)
      ..lineTo(cycleW, yBottom);

    final singleMetrics = singleCyclePath.computeMetrics().first;
    final singleLength = singleMetrics.length;

    final ballSingleDist = progress * singleLength;
    final tangent = singleMetrics.getTangentForOffset(ballSingleDist);
    if (tangent == null) return;
    final rawBallPos = tangent.position;

    final ballScreenX = w * 0.42;
    final cameraOffsetX = ballScreenX - rawBallPos.dx;
    final screenBallPos = Offset(ballScreenX, rawBallPos.dy);

    // Multi-Cycle Path
    final multiCyclePath = Path();
    bool isFirst = true;

    for (int cycle = -1; cycle <= 2; cycle++) {
      final originX = cycle * cycleW;
      final k0 = Offset(originX, yBottom);
      final k1 = Offset(originX + cycleW * rInhale, yTop);
      final k2 = Offset(originX + cycleW * rHold, yTop);
      final k3 = Offset(originX + cycleW, yBottom);

      if (isFirst) {
        multiCyclePath.moveTo(k0.dx, k0.dy);
        isFirst = false;
      } else {
        multiCyclePath.lineTo(k0.dx, k0.dy);
      }
      multiCyclePath.lineTo(k1.dx, k1.dy);
      multiCyclePath.lineTo(k2.dx, k2.dy);
      multiCyclePath.lineTo(k3.dx, k3.dy);
    }

    final multiMetrics = multiCyclePath.computeMetrics().first;
    final multiLength = multiMetrics.length;
    final ballMultiDist = singleLength + ballSingleDist;

    canvas.save();
    canvas.translate(cameraOffsetX, 0);

    // Base Track Paint
    final baseTrackPaint = Paint()
      ..color = const Color(0xFF4A5248).withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(multiCyclePath, baseTrackPaint);

    // Active Glowing Ribbon
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

    // Outer Radial Halo Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE2FFDA).withAlpha(230),
          const Color(0xFF98E285).withAlpha(110),
          const Color(0xFF98E285).withAlpha(0),
        ],
      ).createShader(Rect.fromCircle(center: screenBallPos, radius: 28));
    canvas.drawCircle(screenBallPos, 28, glowPaint);

    // Inner Bright Core Ball
    final ballCorePaint = Paint()
      ..color = const Color(0xFFE2FFDA)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(screenBallPos, 10, ballCorePaint);

    // Phase Label Pill Beside Ball
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
        oldDelegate.phaseLabel != phaseLabel ||
        oldDelegate.inhaleSec != inhaleSec ||
        oldDelegate.holdSec != holdSec ||
        oldDelegate.exhaleSec != exhaleSec;
  }
}
