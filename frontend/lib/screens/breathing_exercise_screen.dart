import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../utils/breathing_routine_model.dart';
import 'breathing_completion_screen.dart';

/// Guided Breathing Exercise Screen: 100% Exact Original Ball & Wave Animation Engine (from Image 1 git history) + Image 2 UI Layout
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

  int elapsedSeconds = 4; // Default sample (00:04)
  int currentCycle = 1;
  bool isPlaying = true;
  int averageHrvBpmChange = -8;

  @override
  void initState() {
    super.initState();

    // Exact original 10-second repeating animation controller
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

  /// Get current phase label for ball tag
  String get _currentPhaseLabel {
    final val = _animController.value;
    if (val < 0.38) {
      return '들이마시기';
    } else if (val < 0.62) {
      return '멈추기';
    } else {
      return '내쉬기';
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
          // 1. Serene Frosted Background Image (matching Image 2)
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

                  // Middle Animated Wave Canvas (100% Exact Original Ball Animation + Image 2 Stage Dotted Lines)
                  Expanded(
                    child: Stack(
                      children: [
                        // Vertical Stage Dotted Lines & Labels from Image 2 (4초 들이마시기 / 7초 멈추기 / 8초 내쉬기)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _StageDottedLinesPainter(),
                          ),
                        ),

                        // 100% Exact Original Ball & Wave Animation Engine
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
                      ],
                    ),
                  ),

                  // Subtext Guide: "회원님의 컨디션에 맞춰 조정된 속도예요"
                  const Text(
                    '회원님의 컨디션에 맞춰 조정된 속도예요',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFB0B4BC),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),

                  // Timer Display: 00:04
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

  /// Top Header Bar matching Image 2
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

  /// Bottom Control Toolbar matching Image 2
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

/// Vertical Stage Dotted Lines Painter matching Image 2
class _StageDottedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final x1 = w * 0.25;
    final x2 = w * 0.70;

    final linePaint = Paint()
      ..color = Colors.white.withAlpha(50)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical Dotted Lines
    _drawDottedVerticalLine(canvas, Offset(x1, h * 0.10), h * 0.75, linePaint);
    _drawDottedVerticalLine(canvas, Offset(x2, h * 0.10), h * 0.75, linePaint);

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

    // Header Stage Labels
    final tpInhale = TextPainter(
      text: const TextSpan(text: '4초 들이마시기', style: textStyleHeader),
      textDirection: TextDirection.ltr,
    )..layout();
    tpInhale.paint(canvas, Offset(x1 - tpInhale.width / 2, h * 0.22));

    final tpHold = TextPainter(
      text: const TextSpan(text: '7초 멈추기', style: textStyleSub),
      textDirection: TextDirection.ltr,
    )..layout();
    tpHold.paint(canvas, Offset(x2 + 16, h * 0.22));

    // Bottom Dotted Stage Labels
    final tp4s = TextPainter(
      text: const TextSpan(text: '4초', style: textStyleSub),
      textDirection: TextDirection.ltr,
    )..layout();
    tp4s.paint(canvas, Offset(x1 - tp4s.width / 2, h * 0.62));

    final tp7s = TextPainter(
      text: const TextSpan(text: '7초', style: textStyleSub),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 100% EXACT ORIGINAL Viewport-Tracked Seamless Breathing Wave & Glowing Ball Painter (from Image 1 git history)
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

    // 4. Draw Continuous Unbroken Active Glowing Ribbon around the Ball with Shader Gradient
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

    // 5. Draw Outer Radial Halo Glow of Ball (Screen Center)
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
