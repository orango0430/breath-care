import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// Breathing Feedback Screen (호흡 완료 피드백 화면)
class BreathingFeedbackScreen extends StatelessWidget {
  final int score;
  final String hrvChange;
  final String consistency;
  final String pace;
  final String completionTime;
  final String insightMessage;

  const BreathingFeedbackScreen({
    super.key,
    this.score = 78,
    this.hrvChange = '-8 bpm',
    this.consistency = '82%',
    this.pace = '6.2 회/분',
    this.completionTime = '05:02',
    this.insightMessage =
        '지금 이 순간, 스트레스를 돌보는 시간을 가진 잔잔한 마음으로 함께하고 있어요.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // App Bar Header: Back Arrow + "호흡 완료"
              _buildHeader(context),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Circular Score Meter (78 / 100)
                      _buildCircularScoreMeter(),
                      const SizedBox(height: 18),

                      // Feedback Title & Subtitle: "잘했어요!" / "꾸준한 연습이 더 이로워질 거예요."
                      const Text(
                        '잘했어요!',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '꾸준한 연습이 더 이로워질 거예요.',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.lightGray,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2x2 Grid Metric Cards
                      _buildMetricsGrid(),
                      const SizedBox(height: 14),

                      // 오늘의 한마디 (Insight Card)
                      _buildInsightCard(),
                      const SizedBox(height: 24),

                      // 기록 저장 (Save Record Button)
                      _buildSaveButton(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// App Bar Header with Back Arrow and Title
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.white,
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 14),
        const Text(
          '호흡 완료',
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  /// Circular Arc Score Meter displaying Score (78 / 100)
  Widget _buildCircularScoreMeter() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular Arc Painter
          CustomPaint(
            size: const Size(160, 160),
            painter: _ScoreArcPainter(
              score: score,
              maxScore: 100,
            ),
          ),

          // Center Text: 78 /100
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 38,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                '/100',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.lightGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2x2 Grid of Performance Metrics
  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: '평균 심박 변화',
                value: hrvChange,
                valueColor: AppColors.lightMint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                label: '호흡 일관성',
                value: consistency,
                valueColor: AppColors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: '호흡 속도',
                value: pace,
                valueColor: AppColors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                label: '완료 시간',
                value: completionTime,
                valueColor: AppColors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Individual Tile inside Metrics Grid
  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
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
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Card Component for "오늘의 한마디"
  Widget _buildInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(50),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 한마디',
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insightMessage,
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.lightGray.withAlpha(220),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Save Button ("기록 저장")
  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('호흡 운동 기록이 저장되었습니다!'),
              duration: Duration(seconds: 2),
            ),
          );
          // Pop to root home screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightMint,
          foregroundColor: AppColors.darkBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: const Text(
          '기록 저장',
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.darkBg,
          ),
        ),
      ),
    );
  }
}

/// CustomPainter that draws the circular progress arc for the score meter
class _ScoreArcPainter extends CustomPainter {
  final int score;
  final int maxScore;

  _ScoreArcPainter({
    required this.score,
    required this.maxScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;

    // Track Background Arc (Dark Gray)
    final bgPaint = Paint()
      ..color = const Color(0xFF383B3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Active Progress Arc (Light Mint)
    final sweepAngle = (score / maxScore) * 2 * math.pi;
    const startAngle = -math.pi / 2; // Top 12 o'clock

    final activePaint = Paint()
      ..color = AppColors.lightMint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreArcPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.maxScore != maxScore;
  }
}
