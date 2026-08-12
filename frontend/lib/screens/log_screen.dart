import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/bpace_logo.dart';
import 'home_screen.dart';
import 'condition_measurement_screen.dart';

class LogScreen extends StatefulWidget {
  final int initialSubTab;

  const LogScreen({
    super.key,
    this.initialSubTab = 0,
  });

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  // Selected sub-tab: 0: 일정관리, 1: 기록, 2: 분석결과
  int _selectedSubTab = 0;

  // Toggle calendar view mode: false = 주간 요약(Weekly), true = 월간 펼침(Monthly)
  bool _isMonthlyView = false;

  // Dynamic Today & Selected Date
  final DateTime _today = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  // Month names for English header matching design ("August 2026")
  final List<String> _monthNames = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  // Korean Weekdays list for today's date display ("2026년 8월 11일 화요일")
  final List<String> _koreanWeekdays = const [
    '월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'
  ];

  // Selected bottom navigation index (1 = Log)
  int _selectedNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _selectedSubTab = widget.initialSubTab;
    _selectedDate = _today;
  }

  void _onBottomNavTap(int index) {
    if (index == _selectedNavIndex) return;

    if (index == 0 || index == 2) {
      // Navigate to Home or Breath Screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(initialIndex: index),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      setState(() {
        _selectedNavIndex = index;
      });
    }
  }

  // Format dynamic today date with weekday (e.g. "2026년 8월 11일 화요일")
  String get _fullTodayDateWithWeekday {
    final now = DateTime.now();
    final weekdayStr = _koreanWeekdays[now.weekday - 1];
    return '${now.year}년 ${now.month}월 ${now.day}일 $weekdayStr';
  }

  // Format dynamic today datetime (e.g. "2026년 8월 11일 화요일 12:34 기준")
  String get _fullTodayDateTimeWithWeekday {
    final now = DateTime.now();
    final weekdayStr = _koreanWeekdays[now.weekday - 1];
    final hourStr = now.hour.toString().padLeft(2, '0');
    final minuteStr = now.minute.toString().padLeft(2, '0');
    return '${now.year}년 ${now.month}월 ${now.day}일 $weekdayStr $hourStr:$minuteStr 기준';
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
              // Main Scrollable Body
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 12.0, bottom: 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Header
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      'Time For\nYour Ritual',
                      style: TextStyle(
                        fontFamily: AppFonts.gmarketSans,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        height: 1.2,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sub-Navigation Tabs: [일정관리, 기록, 분석결과]
                    _buildSubTabBar(),
                    const SizedBox(height: 20),

                    // Render Content Based on Selected Sub-Tab
                    if (_selectedSubTab == 0) ...[
                      // 일정관리 View
                      _buildScheduleManagementContent(),
                    ] else if (_selectedSubTab == 1) ...[
                      // 기록 View (메인화면_기록화면_3)
                      _buildRecordTabContent(),
                    ] else ...[
                      // 분석결과 View (메인화면_기록화면_4)
                      _buildAnalysisResultTabContent(),
                    ],
                  ],
                ),
              ),

              // Bottom Floating Navigation Bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: _buildBottomFloatingNav(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Top Header Row
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const BpaceLogo(
          iconSize: 24,
          fontSize: 18,
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.white,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 14),

            // Guest Pictogram Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.slateDarkGray.withAlpha(150),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.slateDarkGray,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.lightGray,
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 2. Sub-Navigation Segment Tabs: [일정관리, 기록, 분석결과]
  Widget _buildSubTabBar() {
    final subTabs = ['일정관리', '기록', '분석결과'];

    return Row(
      children: List.generate(subTabs.length, (index) {
        final isSelected = _selectedSubTab == index;
        return Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSubTab = index;
              });
            },
            borderRadius: BorderRadius.circular(24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.white
                    : AppColors.slateDarkGray.withAlpha(100),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                subTabs[index],
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.darkBg : AppColors.slateGray,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ===========================================================================
  // SUB-TAB 0: 일정관리 CONTENT
  // ===========================================================================
  Widget _buildScheduleManagementContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarSection(),
        const SizedBox(height: 28),
        _buildScheduleSection(),
      ],
    );
  }

  Widget _buildCalendarSection() {
    final monthName = '${_monthNames[_today.month - 1]} ${_today.year}';
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(60),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isMonthlyView = !_isMonthlyView;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 28),
                Text(
                  monthName,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                Icon(
                  _isMonthlyView
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.lightGray,
                  size: 26,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              return SizedBox(
                width: 32,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slateGray,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          if (!_isMonthlyView) _buildWeeklyCalendar() else _buildMonthlyCalendar(),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    final monday = _today.subtract(Duration(days: _today.weekday - 1));
    final weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDates.map((date) {
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.lightMint : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.darkBg : AppColors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyCalendar() {
    final firstDayOfMonth = DateTime(_today.year, _today.month, 1);
    final daysInMonth = DateTime(_today.year, _today.month + 1, 0).day;
    final int offset = firstDayOfMonth.weekday - 1;
    final totalCells = offset + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 4,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        if (index < offset) return const SizedBox.shrink();

        final dayNumber = index - offset + 1;
        final date = DateTime(_today.year, _today.month, dayNumber);
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.lightMint : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? AppColors.darkBg : AppColors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '오늘의 일정',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  children: [
                    Text(
                      '일정 추가하기',
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

        _buildScheduleItem(
          title: '전공 세미나 발표',
          time: '오전 9:00',
          isCompleted: true,
        ),
        const SizedBox(height: 10),

        _buildScheduleItem(
          title: '졸업논문 심사',
          time: '오전 10:00',
          isCompleted: true,
        ),
        const SizedBox(height: 10),

        _buildScheduleItem(
          title: '프로젝트 회의 일정',
          time: '오후 2:30',
          isCompleted: false,
        ),
        const SizedBox(height: 10),

        _buildScheduleItem(
          title: '중앙해커톤 본선 피칭',
          time: '오후 6:30',
          isCompleted: false,
        ),
      ],
    );
  }

  Widget _buildScheduleItem({
    required String title,
    required String time,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(50),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? AppColors.lightGray : AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.slateGray,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.slateGray,
                    ),
                  ),
                ],
              ),
            ],
          ),

          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted
                  ? AppColors.slateDarkGray.withAlpha(120)
                  : AppColors.lightMint,
              foregroundColor:
                  isCompleted ? AppColors.slateGray : AppColors.darkBg,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              isCompleted ? '준비완료' : '준비하기',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 13,
                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUB-TAB 1: 기록 CONTENT (메인화면_기록화면_3)
  // ===========================================================================
  Widget _buildRecordTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWeeklyAvgConditionCard(),
        const SizedBox(height: 28),
        _buildTodayRecordSection(),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightMint,
              foregroundColor: AppColors.darkBg,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Ritual 시작하기',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyAvgConditionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(60),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 주 평균 컨디션 지수',
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '78',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
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
                  _buildRecordBarChart(),
                  const SizedBox(height: 8),
                  Text(
                    _fullTodayDateWithWeekday,
                    style: const TextStyle(
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
        ],
      ),
    );
  }

  Widget _buildRecordBarChart() {
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
            boxShadow: isHighlight
                ? const [
                    BoxShadow(
                      color: Color(0x66E2FFDA),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildTodayRecordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 기록',
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 14),

        _buildRecordCardItem(
          title: '전공 세미나 발표',
          time: '오전 8:45',
          statusTag: '보통',
          statusTagBgColor: const Color(0xFF535639),
          statusTagTextColor: const Color(0xFFF8F8AA),
          score: 57,
          isEvaluated: true,
        ),
        const SizedBox(height: 10),

        _buildRecordCardItem(
          title: '졸업논문 심사',
          time: '오전 9:30',
          statusTag: '좋음',
          statusTagBgColor: const Color(0xFF434A56),
          statusTagTextColor: const Color(0xFFD6E2F6),
          score: 81,
          isEvaluated: true,
        ),
        const SizedBox(height: 10),

        _buildRecordCardItem(
          title: '프로젝트 회의 일정',
          time: '진행 전',
          isEvaluated: false,
        ),
        const SizedBox(height: 10),

        _buildRecordCardItem(
          title: '중앙해커톤 본선 피칭',
          time: '진행 전',
          isEvaluated: false,
        ),
      ],
    );
  }

  Widget _buildRecordCardItem({
    required String title,
    required String time,
    String? statusTag,
    Color? statusTagBgColor,
    Color? statusTagTextColor,
    int score = 0,
    required bool isEvaluated,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(50),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.slateGray,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.slateGray,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              if (isEvaluated && statusTag != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusTagBgColor ?? AppColors.slateDarkGray,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusTag,
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusTagTextColor ?? AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const Text(
                      '/100',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.slateGray,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Text(
                  '0',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slateGray,
                  ),
                ),
                const Text(
                  '/100',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.slateGray,
                  ),
                ),
              ],
              const SizedBox(width: 12),

              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF383A3E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUB-TAB 2: 분석결과 CONTENT (메인화면_기록화면_4 - 1페이지 전체 스크롤)
  // ===========================================================================
  Widget _buildAnalysisResultTabContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 호흡 전후 변화 카드
        _buildBreathBeforeAfterCard(),
        const SizedBox(height: 28),

        // 2. HR 심박수 섹션 (통계 + 라인 차트)
        _buildHrSection(),
        const SizedBox(height: 28),

        // 3. HRV 심박변이도 섹션 (통계 + 요일별 막대 차트)
        _buildHrvSection(),
        const SizedBox(height: 28),

        // 4. AI 분석 · 현재 상태 카드
        _buildAiAnalysisCard(),
        const SizedBox(height: 24),

        // 5. 의료 참고용 하단 안내 문구
        _buildMedicalDisclaimerText(),
      ],
    );
  }

  /// 1. 호흡 전후 변화 카드
  Widget _buildBreathBeforeAfterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(60),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '호흡 전후 변화',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),

              // Legend: Ritual 전 / Ritual 후
              Row(
                children: [
                  _buildLegendItem(color: AppColors.slateGray, label: 'Ritual 전'),
                  const SizedBox(width: 10),
                  _buildLegendItem(color: AppColors.lightMint, label: 'Ritual 후'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Metric 1: HR 심박수 (88 -> 74, -16%)
          _buildBeforeAfterMetricRow(
            label: 'HR',
            subLabel: '심박수',
            beforeVal: '88',
            afterVal: '74',
            changeText: '-16%',
            beforeRatio: 0.85,
            afterRatio: 0.65,
          ),
          const SizedBox(height: 18),

          // Metric 2: HRV 심박변이도 (24 -> 29, +21%)
          _buildBeforeAfterMetricRow(
            label: 'HRV',
            subLabel: '심박변이도',
            beforeVal: '24',
            afterVal: '29',
            changeText: '+21%',
            beforeRatio: 0.60,
            afterRatio: 0.85,
          ),
          const SizedBox(height: 16),

          // Timestamp Footer
          Text(
            _fullTodayDateTimeWithWeekday,
            style: const TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.slateGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.lightGray,
          ),
        ),
      ],
    );
  }

  Widget _buildBeforeAfterMetricRow({
    required String label,
    required String subLabel,
    required String beforeVal,
    required String afterVal,
    required String changeText,
    required double beforeRatio,
    required double afterRatio,
  }) {
    return Row(
      children: [
        // Label (HR 심박수)
        SizedBox(
          width: 76,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              Text(
                subLabel,
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.slateGray,
                ),
              ),
            ],
          ),
        ),

        // Values: 88 -> 74
        Row(
          children: [
            Text(
              beforeVal,
              style: const TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: AppColors.slateGray,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.slateGray,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              afterVal,
              style: const TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),

        // Progress Bar Pair Graphic
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Before Bar (Gray)
              FractionallySizedBox(
                widthFactor: beforeRatio,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.slateGray,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // After Bar (Mint)
              FractionallySizedBox(
                widthFactor: afterRatio,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Change Percentage (-16%, +21%)
        Text(
          changeText,
          style: const TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.lightMint,
          ),
        ),
      ],
    );
  }

  /// 2. HR 심박수 섹션 (통계 + 라인 차트)
  Widget _buildHrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'HR 심박수',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            InkWell(
              onTap: () {},
              child: const Row(
                children: [
                  Text(
                    '전체보기',
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
          ],
        ),
        const SizedBox(height: 14),

        // 3-Column Metric Box (평균 82 bpm, 최고 94 bpm, 최소 68 bpm)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.darkCharcoal,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.slateDarkGray.withAlpha(50),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              _buildStatColumn(label: '평균', value: '82', unit: 'bpm'),
              _buildVerticalDivider(),
              _buildStatColumn(
                label: '최고',
                value: '94',
                unit: 'bpm',
                valueColor: AppColors.pastelYellow,
              ),
              _buildVerticalDivider(),
              _buildStatColumn(label: '최소', value: '68', unit: 'bpm'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // "이번 주 HR 추이" Line Chart Card
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
              const Text(
                '이번 주 HR 추이',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightGray,
                ),
              ),
              const SizedBox(height: 16),

              // Custom Line Chart Container
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CustomPaint(
                  painter: _HrLineChartPainter(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 3. HRV 심박변이도 섹션 (통계 + 요일별 막대 차트)
  Widget _buildHrvSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'HRV 심박변이도',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            InkWell(
              onTap: () {},
              child: const Row(
                children: [
                  Text(
                    '전체보기',
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
          ],
        ),
        const SizedBox(height: 14),

        // 3-Column Metric Box (평균 22 ms, 최고 32 ms, 최소 16 ms)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.darkCharcoal,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.slateDarkGray.withAlpha(50),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              _buildStatColumn(label: '평균', value: '22', unit: 'ms'),
              _buildVerticalDivider(),
              _buildStatColumn(
                label: '최고',
                value: '32',
                unit: 'ms',
                valueColor: AppColors.lightMint,
              ),
              _buildVerticalDivider(),
              _buildStatColumn(label: '최소', value: '16', unit: 'ms'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // "요일별 평균 HRV" Bar Chart Card
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
              const Text(
                '요일별 평균 HRV',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightGray,
                ),
              ),
              const SizedBox(height: 24),

              // 7 Vertical Bars for HRV (월~일)
              _buildHrvBarChart(),
            ],
          ),
        ),
      ],
    );
  }

  /// 7 Vertical Rounded Bars Chart for HRV (월~일 matching 디자인_4 하단)
  Widget _buildHrvBarChart() {
    final hrvData = [
      {'day': '월', 'val': 22, 'height': 50.0, 'color': AppColors.slateDarkGray.withAlpha(150), 'textColor': AppColors.slateGray},
      {'day': '화', 'val': 26, 'height': 75.0, 'color': AppColors.slateDarkGray.withAlpha(150), 'textColor': AppColors.slateGray},
      {'day': '수', 'val': 32, 'height': 110.0, 'color': AppColors.lightMint, 'textColor': AppColors.lightMint, 'hasDot': true},
      {'day': '목', 'val': 24, 'height': 68.0, 'color': AppColors.slateDarkGray.withAlpha(150), 'textColor': AppColors.slateGray},
      {'day': '금', 'val': 19, 'height': 45.0, 'color': AppColors.pastelYellow, 'textColor': AppColors.pastelYellow, 'hasDot': true},
      {'day': '토', 'val': 29, 'height': 90.0, 'color': AppColors.slateDarkGray.withAlpha(150), 'textColor': AppColors.slateGray},
      {'day': '일', 'val': null, 'height': 10.0, 'color': AppColors.slateDarkGray.withAlpha(80), 'textColor': AppColors.slateGray},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: hrvData.map((item) {
        final val = item['val'];
        final color = item['color'] as Color;
        final textColor = item['textColor'] as Color;
        final height = item['height'] as double;
        final hasDot = item['hasDot'] == true;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Dot or Value
            if (hasDot) ...[
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: textColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              val != null ? '$val' : '-',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 13,
                fontWeight: hasDot ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            // Bar
            Container(
              width: 26,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 10),

            // X-axis Day Label
            Text(
              item['day'].toString(),
              style: const TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.slateGray,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required String unit,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.lightGray,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.white,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(
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
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.slateDarkGray.withAlpha(60),
    );
  }

  /// 4. AI 분석 · 현재 상태 카드
  Widget _buildAiAnalysisCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI 분석 · 현재 상태',
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
          padding: const EdgeInsets.all(22),
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
              // Header title with chevron
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '심박수가 높아지는 순간, 리추얼이 도움이 될 수 있어요',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.lightGray,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rich Text Insights matching design paragraph
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGray,
                    height: 1.6,
                  ),
                  children: [
                    TextSpan(text: '오늘의 평균 심박수는 '),
                    TextSpan(
                      text: '82 BPM',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    TextSpan(text: '으로,\n정상 범위 내에서 '),
                    TextSpan(
                      text: '안정적인 상태를 유지',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    TextSpan(text: '하고 있어요.\n\n'),
                    TextSpan(text: '다만, 최고 심박수가 '),
                    TextSpan(
                      text: '94 BPM',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    TextSpan(text: '까지 상승한 순간이 있었어요.\n이는 '),
                    TextSpan(
                      text: '일시적인 긴장이나 집중, 혹은 다가오는 일정에 대한 준비 상태',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    TextSpan(text: '로 볼 수 있어요.\n\n'),
                    TextSpan(text: '최저 심박수는 '),
                    TextSpan(
                      text: '68 BPM',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    TextSpan(text: '으로 관찰되며,\n이는 리추얼 이후 이완된 상태에서 나타나는 '),
                    TextSpan(
                      text: '자연스러운 수치',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    TextSpan(text: '예요.\n\n'),
                    TextSpan(text: '전반적인 컨디션은 양호한 편이며, '),
                    TextSpan(
                      text: '심박수가 높아지는 순간',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    TextSpan(text: '엔 '),
                    TextSpan(
                      text: '짧은 리추얼로 미리 준비',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    TextSpan(text: '해보는 걸 추천드려요.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 5. 의료 참고용 하단 안내 문구
  Widget _buildMedicalDisclaimerText() {
    return const Padding(
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
    );
  }

  /// 6. Floating Bottom Navigation Bar (Matching Design Log active)
  Widget _buildBottomFloatingNav() {
    return Row(
      children: [
        // "Ritual" Circular Action Button
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ConditionMeasurementScreen(),
              ),
            );
          },
          child: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: AppColors.lightMint,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x4DE2FFDA),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  color: AppColors.darkBg,
                  size: 22,
                ),
                SizedBox(height: 1),
                Text(
                  'Ritual',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBg,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Navigation Bar Container
        Expanded(
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.slateDarkGray.withAlpha(100),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.calendar_today_rounded,
                  label: 'Log',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.air_rounded,
                  label: 'Breath',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Single Navigation Item
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () => _onBottomNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.slateDarkGray.withAlpha(128)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.slateGray,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// CustomPainter for "이번 주 HR 추이" Line Chart
class _HrLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grid Labels and Lines (20 to 120)
    const yLabels = ['120', '100', '80', '60', '40', '20'];
    const textStyle = TextStyle(
      fontFamily: AppFonts.pretendard,
      fontSize: 10,
      color: AppColors.slateGray,
    );

    final gridPaint = Paint()
      ..color = AppColors.slateDarkGray.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const double startX = 30.0;
    final double chartW = w - startX;
    final double rowH = (h - 24) / (yLabels.length - 1);

    // Draw Y-axis grid lines and labels
    for (int i = 0; i < yLabels.length; i++) {
      final y = i * rowH;
      final textSpan = TextSpan(text: yLabels[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));

      // Dashed grid line
      canvas.drawLine(Offset(startX, y), Offset(w, y), gridPaint);
    }

    // X-axis day labels (월 화 수 목 금 토 일)
    final xDays = ['월', '화', '수', '목', '금', '토', '일'];
    final double colW = chartW / (xDays.length - 1);

    for (int i = 0; i < xDays.length; i++) {
      final x = startX + i * colW;
      final textSpan = TextSpan(text: xDays[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, h - 14));
    }

    // HR Line Path Data Points (mapped to chart area)
    // Points across the week matching the wave in design_4
    final points = [
      Offset(startX + 0 * colW, h - 24 - 45),
      Offset(startX + 0.5 * colW, h - 24 - 65),
      Offset(startX + 1.0 * colW, h - 24 - 60),
      Offset(startX + 1.5 * colW, h - 24 - 70),
      Offset(startX + 2.0 * colW, h - 24 - 55),
      Offset(startX + 2.5 * colW, h - 24 - 75),
      Offset(startX + 3.0 * colW, h - 24 - 82),
      Offset(startX + 3.5 * colW, h - 24 - 68),
      Offset(startX + 4.0 * colW, h - 24 - 88),
      Offset(startX + 4.5 * colW, h - 24 - 62),
      Offset(startX + 5.0 * colW, h - 24 - 85),
      Offset(startX + 5.5 * colW, h - 24 - 105), // Peak tooltip at 78
    ];

    // Smooth Line Path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Gradient Fill Path under curve
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, h - 24);
    fillPath.lineTo(points.first.dx, h - 24);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.lightMint.withAlpha(70),
          AppColors.lightMint.withAlpha(0),
        ],
      ).createShader(Rect.fromLTRB(startX, 0, w, h - 24));

    canvas.drawPath(fillPath, fillPaint);

    // Draw Smooth Line Stroke
    final linePaint = Paint()
      ..color = AppColors.lightMint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Point Dot & Badge Tooltip on Last Highlight Point (78 score badge)
    final peakPoint = points.last;

    // Outer glow dot
    canvas.drawCircle(
      peakPoint,
      5.0,
      Paint()..color = AppColors.white,
    );

    // Badge Container ("78") above peak point
    const badgeWidth = 36.0;
    const badgeHeight = 22.0;
    final badgeOffset = Offset(
      peakPoint.dx - badgeWidth / 2,
      peakPoint.dy - badgeHeight - 8,
    );

    final badgeRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        badgeOffset.dx,
        badgeOffset.dy,
        badgeWidth,
        badgeHeight,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(
      badgeRRect,
      Paint()..color = AppColors.white,
    );

    // Badge Text "78"
    const badgeTextSpan = TextSpan(
      text: '78',
      style: TextStyle(
        fontFamily: AppFonts.pretendard,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.darkBg,
      ),
    );
    final badgePainter = TextPainter(
      text: badgeTextSpan,
      textDirection: TextDirection.ltr,
    );
    badgePainter.layout();
    badgePainter.paint(
      canvas,
      Offset(
        badgeOffset.dx + (badgeWidth - badgePainter.width) / 2,
        badgeOffset.dy + (badgeHeight - badgePainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
