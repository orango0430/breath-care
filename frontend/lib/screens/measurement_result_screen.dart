import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../utils/ppg_sensor_service.dart';
import '../utils/breathing_routine_model.dart';
import 'breathing_exercise_screen.dart';
import 'log_screen.dart';

class MeasurementResultScreen extends StatelessWidget {
  final PpgMeasurementResult? result;
  final BreathingRoutineModel? routine;

  const MeasurementResultScreen({
    super.key,
    this.result,
    this.routine,
  });

  @override
  Widget build(BuildContext context) {
    final activeResult = result ?? PpgMeasurementResult.defaultSample();
    final activeRoutine =
        routine ?? BreathingRoutineModel.fromHrv(activeResult.hrvSdnnMs);
    final conditionScore =
        (activeResult.hrvSdnnMs * 1.4 + 40).clamp(50.0, 96.0).round();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Top Header Row (Back button)
              Row(
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
                ],
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 12.0, bottom: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. AAC Event Schedule Card
                      _buildScheduleCard(),
                      const SizedBox(height: 16),

                      // 2. Condition Score Card
                      _buildConditionScoreCard(conditionScore),
                      const SizedBox(height: 24),

                      // 3. Measurement Result Cards Row (HR Soft Blue & HRV Pastel Yellow)
                      _buildMeasurementResultSection(context, activeResult),
                      const SizedBox(height: 24),

                      // 4. AI Analysis Card
                      _buildAiAnalysisSection(conditionScore, activeRoutine),
                      const SizedBox(height: 28),

                      // 5. "맞춤 호흡 시작하기" Full CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BreathingExerciseScreen(
                                  title: activeRoutine.title,
                                  routineModel: activeRoutine,
                                  initialInhaleSec: activeResult.measuredInhaleSec,
                                  initialExhaleSec: activeResult.measuredExhaleSec,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lightMint,
                            foregroundColor: AppColors.darkBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            '${activeRoutine.title} 시작하기',
                            style: const TextStyle(
                              fontFamily: AppFonts.pretendard,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 6. Medical Disclaimer Footer Text
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          '이 결과는 의료 진단·치료·응급 판단을 위한 정보가 아닌 웰빙 참고용입니다.\n심각한 증상이나 응급 상황이라면 의료기관 또는 119에 연락하세요.',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.slateGray,
                            height: 1.5,
                          ),
                        ),
                      ),
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

  /// 1. AAC Event Schedule Card
  Widget _buildScheduleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(50),
          width: 0.8,
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'AAC 해커톤 면접 일정',
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: AppColors.lightGray,
                size: 14,
              ),
              SizedBox(width: 4),
              Text(
                '오후 2:30',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 13,
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

  /// 2. Condition Score Card
  Widget _buildConditionScoreCard(int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(50),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '컨디션 지수',
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '/100',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: AppColors.slateGray,
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildWeeklyBarChart(),
                  const SizedBox(height: 6),
                  const Text(
                    '이번 주',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.slateGray,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text(
            score >= 80
                ? '최상의 컨디션이에요! 루틴으로 유지해보세요.'
                : (score >= 65
                    ? '안정적인 흐름이에요. Ritual로 완벽히 리프레시해보세요.'
                    : '피로도가 다소 누적되었습니다. 호흡으로 이완해보세요.'),
            style: const TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '지난주 평균보다 ${score >= 75 ? (score - 72) : 3}점 ${score >= 72 ? "높아요" : "낮아요"}',
            style: const TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.slateGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart() {
    final barHeights = [18.0, 24.0, 30.0, 48.0, 36.0, 22.0, 28.0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final isHighlight = index == 3;
        return Container(
          margin: EdgeInsets.only(left: index == 0 ? 0 : 5.0),
          width: 12,
          height: barHeights[index],
          decoration: BoxDecoration(
            color: isHighlight
                ? AppColors.lightMint
                : AppColors.slateDarkGray.withAlpha(150),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  /// 3. Measurement Result Section (HR Soft Blue & HRV Pastel Yellow)
  Widget _buildMeasurementResultSection(
      BuildContext context, PpgMeasurementResult res) {
    final hrStatus = res.bpm > 85
        ? '↑ 약간 높음'
        : (res.bpm < 65 ? '↓ 안정적' : '✓ 정상 범위');

    final hrvVal = res.hrvSdnnMs.toStringAsFixed(1);
    final hrvStatus = res.hrvSdnnMs > 35.0
        ? '✓ 매우 우수'
        : (res.hrvSdnnMs > 22.0 ? '✓ 정상 범위' : '↓ 피로도 높음');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with "자세히보기 >"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '측정 결과',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LogScreen(initialSubTab: 2),
                  ),
                  (route) => false,
                );
              },
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    Text(
                      '자세히보기',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.lightGray,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.lightGray,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2 Side-by-Side Highlighted Cards
        Row(
          children: [
            // Left Card: HR Soft Blue Card
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(20),
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
                              'HR',
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF222224),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '심박수',
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF53565C),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.favorite_border_rounded,
                          color: Color(0xFF222224),
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
                          '${res.bpm}',
                          style: const TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF222224),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'bpm',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF53565C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hrStatus,
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222224),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Right Card: HRV Pastel Yellow Card
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.pastelYellow,
                  borderRadius: BorderRadius.circular(20),
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
                              'HRV',
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF222224),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '심박변이도',
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF53565C),
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.monitor_heart_outlined,
                          color: Color(0xFF222224),
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
                          hrvVal,
                          style: const TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF222224),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'ms',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF53565C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hrvStatus,
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222224),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 4. AI Analysis Card
  Widget _buildAiAnalysisSection(int score, BreathingRoutineModel routine) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI 분석',
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
              Text(
                '$score점 컨디션에 맞춰 ${routine.totalDurationMinutes}분, ${routine.intensity} 강도로 조정했어요',
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '오늘 일정을 종합 분석한 결과입니다.\n지금 컨디션에 맞춰 "${routine.title}"(으)로 리듬을 정돈해보세요.',
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.lightGray,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
