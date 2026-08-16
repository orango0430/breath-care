import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'breathing_exercise_screen.dart';

/// Breathing Completion Screen (Ritual Feedback - 스크롤 가능한 호흡 종료 피드백 화면)
class BreathingCompletionScreen extends StatefulWidget {
  final String title;
  final String bgImagePath;
  final String durationString;
  final String hrvChange;

  const BreathingCompletionScreen({
    super.key,
    this.title = '4-7-8 호흡',
    this.bgImagePath = 'assets/images/bg_breath_478.png',
    this.durationString = '05:04',
    this.hrvChange = '-8 bpm',
  });

  @override
  State<BreathingCompletionScreen> createState() =>
      _BreathingCompletionScreenState();
}

class _BreathingCompletionScreenState extends State<BreathingCompletionScreen> {
  bool _isSaved = false;

  void _onSaveRecord() {
    setState(() {
      _isSaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ritual 기록이 성공적으로 저장되었습니다!'),
        backgroundColor: AppColors.lightMint,
        duration: Duration(seconds: 2),
      ),
    );
  }

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
              // Top Bar Row (Back Arrow Circle Button)
              _buildTopHeader(context),
              const SizedBox(height: 16),

              // Main Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Page Title: "Ritual Feedback"
                      Text(
                        'Ritual Feedback',
                        style: GoogleFonts.outfit(
                          fontSize: 34,
                          fontWeight: FontWeight.w400,
                          color: AppColors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Center Hero Card with "88 /100" Score Tag
                      _buildHeroCard(context),
                      const SizedBox(height: 20),

                      // 3. Stats Row Cards (진행 시간: 05:04 초 | 사이클: 16 회)
                      _buildStatsRow(),
                      const SizedBox(height: 28),

                      // 4. Section Title: "AI 분석 · 현재 상태"
                      const Text(
                        'AI 분석 · 현재 상태',
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 5. AI Analysis Main Container Card
                      _buildAiAnalysisCard(),
                      const SizedBox(height: 24),

                      // 6. Bottom Disclaimer Subtext
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            '이 결과는 의료 진단·치료·응급 판단을 위한 정보가 아닌 웰빙 참고용입니다.\n심각한 증상이나 응급 상황이라면 의료기관 또는 119에 연락하세요.',
                            style: TextStyle(
                              fontFamily: AppFonts.pretendard,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF6E7178),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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

  /// Top Bar Header Row
  Widget _buildTopHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF2B2C2E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Center Hero Card Component matching screenshot
  Widget _buildHeroCard(BuildContext context) {
    return Container(
      height: 340,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF2B2D32),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(
              widget.bgImagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF384656), Color(0xFF252C36)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(20),
                    Colors.black.withAlpha(120),
                    Colors.black.withAlpha(210),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Top-Left Floating Score Badge: [ 88 /100 ]
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2FFDA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '88',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2019),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '/100',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5A7253),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-Right Bookmark Ribbon Icon
            const Positioned(
              top: 18,
              right: 18,
              child: Icon(
                Icons.bookmark_rounded,
                color: AppColors.white,
                size: 26,
              ),
            ),

            // Bottom Information Overlay & Action Buttons
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '긴장을 천천히 가라앉히는 호흡',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withAlpha(210),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      // Translucent Glass Button: 시작하기
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BreathingExerciseScreen(
                                  title: widget.title,
                                  bgImagePath: widget.bgImagePath,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withAlpha(60),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '시작하기',
                                style: TextStyle(
                                  fontFamily: AppFonts.pretendard,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // White Circle Arrow Button (->)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BreathingExerciseScreen(
                                title: widget.title,
                                bgImagePath: widget.bgImagePath,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.darkBg,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Stats Row Cards (진행 시간: 05:04 초 | 사이클: 16 회)
  Widget _buildStatsRow() {
    return Row(
      children: [
        // Left Card: 진행 시간
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF28292B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '진행 시간',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFACAEB3),
                      ),
                    ),
                    Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFFACAEB3),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.durationString,
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEFF8A8), // Light yellow tint matching screenshot
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '초',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFACAEB3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Right Card: 사이클
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF28292B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '사이클',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFACAEB3),
                      ),
                    ),
                    Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFFACAEB3),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text(
                      '16',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '회',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFACAEB3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 5. AI Analysis Container Card matching screenshots
  Widget _buildAiAnalysisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF28292B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Save Record CTA Button or Saved Indicator
          GestureDetector(
            onTap: _onSaveRecord,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _isSaved ? const Color(0xFF384534) : const Color(0xFFE2FFDA),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSaved) ...[
                      const Icon(Icons.check_rounded, color: AppColors.lightMint, size: 20),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _isSaved ? 'Ritual 기록 저장됨' : 'Ritual 기록 저장',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _isSaved ? AppColors.lightMint : AppColors.darkBg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Subheader line: 심박수가 높아지는 순간, 리추얼이 도움이 될 수 있어요 >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text(
                  '심박수가 높아지는 순간, 리추얼이 도움이 될 수 있어요',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFACAEB3),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rich Paragraph 1
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 13.5,
                color: Color(0xFFBAC0CB),
                height: 1.5,
              ),
              children: [
                TextSpan(text: '오늘의 평균 심박수는 '),
                TextSpan(
                  text: '82 BPM',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white),
                ),
                TextSpan(text: '으로,\n정상 범위 내에서 '),
                TextSpan(
                  text: '안정적인 상태를 유지',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white),
                ),
                TextSpan(text: '하고 있어요.'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Rich Paragraph 2
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 13.5,
                color: Color(0xFFBAC0CB),
                height: 1.5,
              ),
              children: [
                TextSpan(text: '다만, 최고 심박수가 '),
                TextSpan(
                  text: '94 BPM',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white),
                ),
                TextSpan(text: '까지 상승한 순간이 있었어요.\n이는 '),
                TextSpan(
                  text: '일시적인 긴장이나 집중, 혹은 다가오는 일정에 대한 준비 상태',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white),
                ),
                TextSpan(text: '로 볼 수 있어요.'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Rich Paragraph 3
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 13.5,
                color: Color(0xFFBAC0CB),
                height: 1.5,
              ),
              children: [
                TextSpan(text: '최저 심박수는 '),
                TextSpan(
                  text: '68 BPM',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white),
                ),
                TextSpan(text: '으로 관찰되며,\n이는 리추얼 이후 이완된 상태에서 나타나는 '),
                TextSpan(
                  text: '자연스러운 수치',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white),
                ),
                TextSpan(text: '예요.'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Rich Paragraph 4
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 13.5,
                color: Color(0xFFBAC0CB),
                height: 1.5,
              ),
              children: [
                TextSpan(text: '전반적인 컨디션은 양호한 편이며, '),
                TextSpan(
                  text: '심박수가 높아지는 순간',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white),
                ),
                TextSpan(text: '엔\n'),
                TextSpan(
                  text: '짧은 리추얼로 미리 준비',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.white),
                ),
                TextSpan(text: '해보는 걸 추천드려요.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
