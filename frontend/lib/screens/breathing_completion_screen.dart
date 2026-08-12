import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'breathing_feedback_screen.dart';

/// Breathing Completion Screen (호흡 완료 화면)
class BreathingCompletionScreen extends StatelessWidget {
  final String title;
  final String durationString;
  final String hrvChange;

  const BreathingCompletionScreen({
    super.key,
    this.title = '호흡 완료',
    this.durationString = '05:02',
    this.hrvChange = '-8 bpm',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // App Bar Header: Back Arrow + "호흡 완료"
              _buildHeader(context),
              const Spacer(flex: 1),

              // Large Center Circular Check Icon Graphic
              _buildCheckGraphic(),
              const SizedBox(height: 28),

              // Congratulatory Message: "수고했어요!" / "마음이 조금은 가벼워졌기를 바라요."
              const Text(
                '수고했어요!',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '마음이 조금은\n가벼워졌기를 바라요.',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.lightGray,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 1),

              // Summary Metrics Card: 호흡 시간 (05:02) | 평균 심박 변화 (-8 bpm)
              _buildSummaryCard(),
              const SizedBox(height: 32),

              // Bottom Action Buttons: 완료 | 피드백 보기
              _buildBottomButtons(context),
              const SizedBox(height: 24),
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
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  /// Concentric Circular Checkmark Graphic Component
  Widget _buildCheckGraphic() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFF454D44), // Dark greenish gray circle
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.lightMint, // Light mint stroke
              width: 2.5,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              color: AppColors.lightMint,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  /// Summary Metrics Container Card
  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(60),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Line 1: 호흡 시간  05:02
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '호흡 시간',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.lightGray,
                ),
              ),
              Text(
                durationString,
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Line 2: 평균 심박 변화  -8 bpm (Coral Red)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '평균 심박 변화',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.lightGray,
                ),
              ),
              Text(
                hrvChange,
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.coralRed, // Reddish pastel matching image
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bottom Action Buttons ("완료" and "피드백 보기")
  Widget _buildBottomButtons(BuildContext context) {
    return Column(
      children: [
        // Button 1: 완료 (Filled Light Mint Button)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              // Pop back to home screen root
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
              '완료',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBg,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Button 2: 피드백 보기 (Dark Outlined Button)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BreathingFeedbackScreen(
                    completionTime: durationString,
                    hrvChange: hrvChange,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.darkCharcoal,
              foregroundColor: AppColors.white,
              side: BorderSide(
                color: AppColors.slateDarkGray.withAlpha(120),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: const Text(
              '피드백 보기',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
