import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../utils/ppg_sensor_service.dart';
import '../utils/breathing_routine_model.dart';
import '../utils/schedule_storage_service.dart';
import 'breathing_exercise_screen.dart';
import 'log_screen.dart';

class MeasurementResultScreen extends StatefulWidget {
  final PpgMeasurementResult? result;
  final BreathingRoutineModel? routine;
  final String? targetScheduleId;

  const MeasurementResultScreen({
    super.key,
    this.result,
    this.routine,
    this.targetScheduleId,
  });

  @override
  State<MeasurementResultScreen> createState() =>
      _MeasurementResultScreenState();
}

class _MeasurementResultScreenState extends State<MeasurementResultScreen> {
  int? _pastAvgScore;
  int? _pastAvgHr;
  int? _pastAvgHrv;
  Map<String, dynamic>? _upcomingSchedule;

  @override
  void initState() {
    super.initState();
    _loadScheduleAndSavePrefs();
  }

  Future<void> _loadScheduleAndSavePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final activeResult = widget.result ?? PpgMeasurementResult.defaultSample();
    final score = (activeResult.hrvSdnnMs * 1.4 + 40).clamp(50.0, 96.0).round();

    // 1. Calculate past score average from condition_score_history
    final history = prefs.getStringList('condition_score_history') ?? ['72', '76', '70', '74'];
    if (history.isNotEmpty) {
      final int sum = history.map((e) => int.tryParse(e) ?? 72).reduce((a, b) => a + b);
      _pastAvgScore = (sum / history.length).round();
    } else {
      _pastAvgScore = 72;
    }

    // Calculate past HR average from hr_history
    final hrHistory = prefs.getStringList('hr_history') ?? ['74', '80', '76'];
    if (hrHistory.isNotEmpty) {
      final int sumHr = hrHistory.map((e) => int.tryParse(e) ?? 75).reduce((a, b) => a + b);
      _pastAvgHr = (sumHr / hrHistory.length).round();
    } else {
      _pastAvgHr = 75;
    }

    // Calculate past HRV average from hrv_history_v2
    final hrvHistory = prefs.getStringList('hrv_history_v2') ?? [];
    if (hrvHistory.isNotEmpty) {
      final List<int> vals = [];
      for (final item in hrvHistory) {
        final parts = item.split(':');
        if (parts.length >= 2) {
          final v = int.tryParse(parts[1]);
          if (v != null) vals.add(v);
        }
      }
      if (vals.isNotEmpty) {
        _pastAvgHrv = (vals.reduce((a, b) => a + b) / vals.length).round();
      } else {
        _pastAvgHrv = 24;
      }
    } else {
      _pastAvgHrv = 24;
    }

    // Save current score into history
    history.add(score.toString());
    await prefs.setStringList('condition_score_history', history);
    await prefs.setInt('latest_condition_score', score);
    await prefs.setInt('latest_bpm', activeResult.bpm);
    await prefs.setInt('latest_hrv', activeResult.hrvSdnnMs.round());

    hrHistory.add(activeResult.bpm.toString());
    await prefs.setStringList('hr_history', hrHistory);

    final weekday = DateTime.now().weekday;
    final hrvVal = activeResult.hrvSdnnMs.round();
    final newHrvHistory = List<String>.from(hrvHistory);
    newHrvHistory.add('$weekday:$hrvVal');
    await prefs.setStringList('hrv_history_v2', newHrvHistory);

    // 2. Load today's upcoming schedule closest to current time (irrespective of isCompleted)
    final now = DateTime.now();
    final allSchedules = await ScheduleStorageService.loadSchedules();

    // Filter schedules for today
    final todaySchedules = allSchedules.where((s) {
      DateTime sDate;
      if (s['date'] is DateTime) {
        sDate = s['date'] as DateTime;
      } else if (s['date'] is String) {
        try {
          sDate = DateTime.parse(s['date'] as String);
        } catch (_) {
          sDate = now;
        }
      } else {
        sDate = now;
      }
      return sDate.year == now.year && sDate.month == now.month && sDate.day == now.day;
    }).toList();

    // Filter upcoming schedules where parsed schedule time is in the future relative to current time
    final upcomingList = <Map<String, dynamic>>[];
    for (var s in todaySchedules) {
      final dt = _parseScheduleTime(s['date'], s['time'] as String?);
      if (dt != null) {
        // Allow a 5-min grace window so if user arrives right at schedule time it still shows
        if (dt.isAfter(now.subtract(const Duration(minutes: 5)))) {
          upcomingList.add({
            'schedule': s,
            'dateTime': dt,
          });
        }
      }
    }

    if (upcomingList.isNotEmpty) {
      // Sort upcoming schedules ascending by time (closest upcoming first!)
      upcomingList.sort((a, b) => (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime));
      _upcomingSchedule = upcomingList.first['schedule'] as Map<String, dynamic>;
    } else {
      // If no upcoming schedule left today, do not display schedule box
      _upcomingSchedule = null;
    }

    if (mounted) {
      setState(() {});
    }
  }

  DateTime? _parseScheduleTime(dynamic dateVal, String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;

    DateTime baseDate;
    if (dateVal is DateTime) {
      baseDate = dateVal;
    } else if (dateVal is String) {
      try {
        baseDate = DateTime.parse(dateVal);
      } catch (_) {
        baseDate = DateTime.now();
      }
    } else {
      baseDate = DateTime.now();
    }

    try {
      final isPm = timeStr.contains('오후');
      final cleanStr = timeStr.replaceAll('오전', '').replaceAll('오후', '').trim();
      final parts = cleanStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0].trim());
        int minute = int.parse(parts[1].trim());

        if (isPm && hour < 12) {
          hour += 12;
        } else if (!isPm && hour == 12 && timeStr.contains('오전')) {
          hour = 0;
        }

        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          hour,
          minute,
        );
      }
    } catch (_) {}

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final activeResult = widget.result ?? PpgMeasurementResult.defaultSample();
    final activeRoutine = widget.routine ??
        BreathingRoutineModel.fromMeasurement(
          bpm: activeResult.bpm,
          hrvSdnn: activeResult.hrvSdnnMs,
        );
    final conditionScore =
        (activeResult.hrvSdnnMs * 1.4 + 40).clamp(50.0, 96.0).round();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Stack(
            children: [
              // Scrollable Content (Scrolls beneath floating bottom buttons, matching Image 1)
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 48.0, bottom: 80.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Schedule Card (Only displayed if an upcoming schedule exists today)
                    if (_upcomingSchedule != null) ...[
                      _buildScheduleCard(),
                      const SizedBox(height: 16),
                    ],

                    // 2. Condition Score Card
                    _buildConditionScoreCard(conditionScore, _pastAvgScore),
                    const SizedBox(height: 24),

                    // 3. Measurement Result Cards Row (HR Soft Blue & HRV Pastel Yellow)
                    _buildMeasurementResultSection(context, activeResult),
                    const SizedBox(height: 24),

                    // 4. AI Analysis Card
                    _buildAiAnalysisSection(conditionScore, activeRoutine, activeResult),
                    const SizedBox(height: 24),

                    // 5. Medical Disclaimer Footer Text
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Top Header Row (Back button floating on top left)
              Positioned(
                top: 12,
                left: 0,
                child: IconButton(
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
              ),

              // Bottom Floating Action Row (Floating without solid background block, matching Image 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: _buildFixedBottomNavigationBar(
                  context,
                  activeRoutine,
                  activeResult,
                  conditionScore,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Schedule Header Box (Displays closest upcoming schedule today; hidden if none)
  Widget _buildScheduleCard() {
    if (_upcomingSchedule == null) return const SizedBox.shrink();

    final title = _upcomingSchedule!['title'] as String? ?? '프로젝트 회의 일정';
    final time = _upcomingSchedule!['time'] as String? ?? '오후 2:30';

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.white,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: AppColors.lightGray,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(
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
  Widget _buildConditionScoreCard(int score, int? pastAvg) {
    // 1st Subtext Line: Recommendation based on score
    final String headlineText;
    if (score >= 80) {
      headlineText = '최상의 컨디션이에요! Ritual로 유지해보세요.';
    } else if (score >= 65) {
      headlineText = '안정적인 흐름이에요. Ritual로 완성해보세요';
    } else {
      headlineText = '피로도가 다소 누적되었습니다. 호흡으로 이완해보세요.';
    }

    // 2nd Subtext Line: Comparison with past average
    final String comparisonText;
    if (pastAvg != null) {
      final diff = score - pastAvg;
      if (diff > 0) {
        comparisonText = '지난주 평균보다 $diff점 높아요';
      } else if (diff < 0) {
        comparisonText = '지난주 평균보다 ${diff.abs()}점 낮아요';
      } else {
        comparisonText = '지난주 평균과 동일한 점수예요';
      }
    } else {
      comparisonText = '오늘 첫 컨디션을 측정했어요';
    }

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
              fontWeight: FontWeight.w400,
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
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
                      fontWeight: FontWeight.w400,
                      color: AppColors.lightMint,
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

          // 1st Line: Recommendation based on score
          Text(
            headlineText,
            style: const TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),

          // 2nd Line: Past average comparison
          Text(
            comparisonText,
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
    // Dynamic comparison for HR (bpm)
    final avgHr = _pastAvgHr ?? 75;
    final String hrStatus;
    if (res.bpm > avgHr + 3) {
      hrStatus = '↑ 평균 이상';
    } else if (res.bpm < avgHr - 3) {
      hrStatus = '↓ 평균 이하';
    } else {
      hrStatus = '✓ 평균 수준';
    }

    // Dynamic comparison for HRV (ms)
    final avgHrv = _pastAvgHrv ?? 24;
    final hrvInt = res.hrvSdnnMs.round();
    final String hrvStatus;
    if (hrvInt > avgHrv + 2) {
      hrvStatus = '↑ 평균 이상';
    } else if (hrvInt < avgHrv - 2) {
      hrvStatus = '↓ 평균 이하';
    } else {
      hrvStatus = '✓ 평균 수준';
    }

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
                fontWeight: FontWeight.w400,
                color: AppColors.white,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LogScreen(initialSubTab: 2),
                  ),
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
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF222224),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '심박수',
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
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
                            fontWeight: FontWeight.w400,
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
                            fontWeight: FontWeight.w400,
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
                        fontWeight: FontWeight.w400,
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
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF222224),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '심박변이도',
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
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
                          '$hrvInt',
                          style: const TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 32,
                            fontWeight: FontWeight.w400,
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
                            fontWeight: FontWeight.w400,
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
                        fontWeight: FontWeight.w400,
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
  Widget _buildAiAnalysisSection(int score, BreathingRoutineModel routine, PpgMeasurementResult res) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI 분석 · 호흡 추천',
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 17,
            fontWeight: FontWeight.w400,
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
                  fontWeight: FontWeight.w400,
                  color: AppColors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '오늘 일정을 종합 분석한 결과입니다.\n지금 컨디션에 맞춰 '),
                    TextSpan(
                      text: routine.title,
                      style: const TextStyle(
                        color: AppColors.lightMint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const TextSpan(text: '(으)로 리듬을 정돈해보세요.'),
                  ],
                ),
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

  /// Fixed Bottom Navigation Bar Area (Circular Home Button with Nav Home Icon + Ritual 시작하기 Mint Pill Button)
  Widget _buildFixedBottomNavigationBar(
    BuildContext context,
    BreathingRoutineModel activeRoutine,
    PpgMeasurementResult activeResult,
    int conditionScore,
  ) {
    return Row(
      children: [
          // Left: Circular Home Icon Button (Navigates to Home using exact nav_home.png icon)
          InkWell(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFF2B2D32),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/nav_home.png',
                  width: 22,
                  height: 22,
                  color: AppColors.white,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.home_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right: Ritual 시작하기 Full Mint Green Pill Button
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BreathingExerciseScreen(
                        title: activeRoutine.title,
                        routineModel: activeRoutine,
                        initialInhaleSec: activeResult.measuredInhaleSec,
                        initialExhaleSec: activeResult.measuredExhaleSec,
                        isAdaptiveRamp: true,
                        targetScheduleId: widget.targetScheduleId,
                      ),
                    ),
                  );
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
                  'Ritual 시작하기',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1E221E),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
  }
}
