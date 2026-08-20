import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/calendar_service.dart';
import '../services/statistics_service.dart';
import '../models/statistics.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/bpace_logo.dart';
import 'home_screen.dart';
import 'condition_measurement_screen.dart';
import 'my_page_screen.dart';
import 'add_schedule_modal.dart';

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
  /// This week's aggregates, straight from the server. Null until the request
  /// finishes, and it stays null when it fails — the screen shows a dash in
  /// that case rather than a number nobody measured.
  StatisticsSummary? _summary;

  /// One entry per day of the week, including days with no reading.
  List<DailyMetric> _daily = [];

  /// A placeholder that reads as "no reading yet" instead of a plausible
  /// number. This screen used to fall back to 82 bpm and a 78 score, which on
  /// a health app is indistinguishable from a real measurement.
  static const String _noData = '–';

  String _metric(double? value) => value == null ? _noData : value.round().toString();

  String get _avgHrStr => _metric(_summary?.hr.avg);
  String get _maxHrStr => _metric(_summary?.hr.max);
  String get _minHrStr => _metric(_summary?.hr.min);

  String get _avgHrvStr => _metric(_summary?.hrv.avg);
  String get _maxHrvStr => _metric(_summary?.hrv.max);
  String get _minHrvStr => _metric(_summary?.hrv.min);

  /// Null when nothing has been measured this week.
  int? get _weeklyAvgConditionScore => _summary?.conditionScore.avg?.round();

  // Selected sub-tab: 0: 일정관리, 1: 기록, 2: 분석결과
  int _selectedSubTab = 0;

  // Toggle calendar view mode: false = 주간 요약(Weekly), true = 월간 펼침(Monthly)
  bool _isMonthlyView = false;

  // Dynamic Today & Selected Date
  DateTime _selectedDate = DateTime.now();
  DateTime _currentDisplayMonth = DateTime.now();

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

  /// Schedules for the visible month, loaded from the server and local storage.
  List<Map<String, dynamic>> _schedules = [];

  bool _isLoadingSchedules = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedSubTab = widget.initialSubTab;
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentDisplayMonth = DateTime(now.year, now.month, 1);
    _loadSchedules();
    _loadStatistics();
  }

  /// Fetches the displayed month. The server treats `to` as exclusive, so the
  /// first day of the next month is the right upper bound.
  Future<void> _loadSchedules() async {
    if (!ApiClient.instance.isLoggedIn) {
      // Guests have no schedules by design — nothing is stored for them.
      setState(() => _schedules = []);
      return;
    }

    setState(() => _isLoadingSchedules = true);
    final month = DateTime(_currentDisplayMonth.year, _currentDisplayMonth.month, 1);

    try {
      final events = await CalendarService.instance.events(
        from: month,
        to: DateTime(month.year, month.month + 1, 1),
      );
      if (!mounted) return;
      setState(() {
        _schedules = events.map(_toRow).toList();
        _isLoadingSchedules = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSchedules = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.coralRed),
      );
    }
  }

  Map<String, dynamic> _toRow(CalendarEvent event) => {
        'id': event.id,
        'title': event.title,
        'category': event.displayCategory ?? event.eventType.label,
        'date': DateTime(event.startAt.year, event.startAt.month, event.startAt.day),
        'time': _formatTime(event.startAt),
        'isCompleted': event.completed,
      };

  /// Ticks a schedule off. The state is written server side, so it survives a
  /// reinstall and shows on the user's other devices.
  Future<void> _setCompleted(int eventId, bool completed) async {
    // Move the tick straight away — waiting on the round trip makes the
    // checkbox feel broken on a slow connection.
    setState(() {
      for (final row in _schedules) {
        if (row['id'] == eventId) row['isCompleted'] = completed;
      }
    });

    try {
      await CalendarService.instance.setCompleted(eventId, completed);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        for (final row in _schedules) {
          if (row['id'] == eventId) row['isCompleted'] = !completed;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.coralRed),
      );
    }
  }

  static String _formatTime(DateTime at) {
    final period = at.hour < 12 ? '오전' : '오후';
    final hour = at.hour == 0 ? 12 : (at.hour > 12 ? at.hour - 12 : at.hour);
    return '$period $hour:${at.minute.toString().padLeft(2, '0')}';
  }

  /// Loads this week's numbers for the 기록 and 분석결과 tabs.
  ///
  /// The server aggregates rather than the app, so the weekly average matches
  /// whatever the reports say. Failures are swallowed on purpose: the screen
  /// already renders dashes, and a red banner over a chart the user did not
  /// ask to refresh is noise.
  Future<void> _loadStatistics() async {
    if (!ApiClient.instance.isLoggedIn) return;

    try {
      final summary = await StatisticsService.instance.summary();
      final daily = await StatisticsService.instance.daily();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _daily = daily;
      });
    } on ApiException {
      // Leave the dashes in place.
    }
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
                padding: const EdgeInsets.only(top: 12.0, bottom: 90.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Header
                    _buildHeader(),
                    const SizedBox(height: 18),

                    // Title
                    Text(
                      'Time For\nYour Ritual',
                      style: GoogleFonts.outfit(
                        fontSize: 38,
                        fontWeight: FontWeight.w400,
                        color: AppColors.white,
                        height: 1.14,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 18),

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
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyPageScreen(),
                  ),
                );
              },
              child: Container(
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
                  fontWeight: isSelected ? FontWeight.w400 : FontWeight.w400,
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
    final monthName = '${_monthNames[_currentDisplayMonth.month - 1]} ${_currentDisplayMonth.year}';
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF28292D),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          // Calendar Month Navigation Row (< August 2026 >)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentDisplayMonth = DateTime(
                      _currentDisplayMonth.year,
                      _currentDisplayMonth.month - 1,
                      1,
                    );
                  });
                  _loadSchedules();
                },
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF90939A),
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isMonthlyView = !_isMonthlyView;
                  });
                },
                child: Text(
                  monthName,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentDisplayMonth = DateTime(
                      _currentDisplayMonth.year,
                      _currentDisplayMonth.month + 1,
                      1,
                    );
                  });
                  _loadSchedules();
                },
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF90939A),
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (!_isMonthlyView)
            _buildWeeklyCalendar()
          else ...[
            // Weekday Headers for Monthly View (Tap any weekday to toggle back)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isMonthlyView = false;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekDays.map((day) {
                  return SizedBox(
                    width: 36,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF90939A),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            _buildMonthlyCalendar(),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    final monday = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weekDates = List.generate(7, (i) => monday.add(Duration(days: i)));
    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final date = weekDates[i];
        final dayLetter = weekDays[i];
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE4FBCB) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Weekday Letter (Tap to Toggle Monthly View)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isMonthlyView = !_isMonthlyView;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                  child: Text(
                    dayLetter,
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w400 : FontWeight.w400,
                      color: isSelected ? const Color(0xFF1E1E20) : const Color(0xFF90939A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Bottom Date Number (Tap to Select Date)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w400 : FontWeight.w400,
                      color: isSelected ? const Color(0xFF1E1E20) : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMonthlyCalendar() {
    final firstDayOfMonth = DateTime(_currentDisplayMonth.year, _currentDisplayMonth.month, 1);
    final daysInMonth = DateTime(_currentDisplayMonth.year, _currentDisplayMonth.month + 1, 0).day;
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
        final date = DateTime(_currentDisplayMonth.year, _currentDisplayMonth.month, dayNumber);
        final isSelected = date.year == _selectedDate.year &&
            date.month == _selectedDate.month &&
            date.day == _selectedDate.day;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE4FBCB) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w400 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF1E1E20) : Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleSection() {
    final daySchedules = _schedules.where((s) {
      final d = s['date'] as DateTime;
      return d.year == _selectedDate.year &&
          d.month == _selectedDate.month &&
          d.day == _selectedDate.day;
    }).toList();

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
                fontWeight: FontWeight.w400,
                color: AppColors.white,
              ),
            ),
            InkWell(
              onTap: () {
                AddScheduleModal.show(
                  context,
                  initialDate: _selectedDate,
                  onScheduleAdded: (newSchedule) {
                    // The modal already saved it. Jump to the day it landed on
                    // so the user sees what they just created, then refetch.
                    setState(() {
                      final newDate = newSchedule['date'] as DateTime?;
                      if (newDate != null) {
                        _selectedDate = newDate;
                        _currentDisplayMonth = DateTime(newDate.year, newDate.month, 1);
                      }
                    });
                    _loadSchedules();
                  },
                );
              },
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

        if (_isLoadingSchedules)
          // Distinct from the empty state below: "still fetching" must not look
          // like "you have nothing planned".
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.lightGray),
              ),
            ),
          )
        else if (daySchedules.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.darkCharcoal,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.slateDarkGray.withAlpha(50),
                width: 0.8,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.slateGray,
                  size: 28,
                ),
                SizedBox(height: 10),
                Text(
                  '선택한 날짜에 등록된 일정이 없습니다.',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 14,
                    color: AppColors.lightGray,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '상단의 "일정 추가하기"를 눌러 새 일정을 추가해 보세요.',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 12,
                    color: AppColors.slateGray,
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(daySchedules.length, (index) {
            final schedule = daySchedules[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildScheduleItem(
                schedule: schedule,
                title: schedule['title'] ?? '',
                time: schedule['time'] ?? '',
                isCompleted: schedule['isCompleted'] ?? false,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildScheduleItem({
    required Map<String, dynamic> schedule,
    required String title,
    required String time,
    required bool isCompleted,
  }) {
    return GestureDetector(
      onLongPress: () {
        _showScheduleOptionsModal(schedule);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF28292D),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Tick a schedule off once it is over. Kept separate from
            // "준비하기": preparing is doing the breathing, completing is the
            // event itself being done, and either can happen without the other.
            GestureDetector(
              onTap: () {
                final id = schedule['id'];
                if (id is int) _setCompleted(id, !isCompleted);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: isCompleted
                      ? AppColors.lightMint
                      : const Color(0xFF555860),
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isCompleted ? const Color(0xFF8B8F98) : Colors.white,
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFF8B8F98),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_outlined,
                      color: Color(0xFF90939A),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF90939A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),

            ElevatedButton(
              onPressed: isCompleted
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ConditionMeasurementScreen(
                            scheduleTitle: schedule['title'] as String?,
                          ),
                        ),
                      ).then((_) {
                        _loadSchedules();
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE4FBCB),
                disabledBackgroundColor: const Color(0xFF1E1E20),
                foregroundColor: const Color(0xFF1E1E20),
                disabledForegroundColor: const Color(0xFF6E727A),
                elevation: 0,
                minimumSize: const Size(102, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                isCompleted ? '준비완료' : '준비하기',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isCompleted ? const Color(0xFF6E727A) : const Color(0xFF1E1E20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LONG-PRESS OPTIONS: 편집 / 삭제 모달
  // ===========================================================================
  void _showScheduleOptionsModal(Map<String, dynamic> schedule) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: const BoxDecoration(
            color: Color(0xFF232426),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.slateGray.withAlpha(120),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title header
              Text(
                '${schedule['title']}',
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),

              // Edit option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E3034),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.lightMint,
                    size: 20,
                  ),
                ),
                title: const Text(
                  '일정 수정',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  AddScheduleModal.show(
                    context,
                    initialSchedule: schedule,
                    onScheduleUpdated: (updatedSchedule) {
                      // Saved by the modal already; just refetch the month.
                      _loadSchedules();
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('일정이 수정되었습니다.'),
                            duration: Duration(seconds: 2),
                            backgroundColor: Color(0xFF2E3034),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              const Divider(color: Color(0xFF2E3034), height: 1),

              // Delete option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.coralRed.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.coralRed,
                    size: 20,
                  ),
                ),
                title: const Text(
                  '일정 삭제',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.coralRed,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteSchedule(schedule);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteSchedule(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF232426),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '일정 삭제',
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
          content: Text(
            '"${schedule['title']}" 일정을 삭제하시겠습니까?',
            style: const TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 14,
              color: AppColors.lightGray,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: AppColors.slateGray)),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final id = schedule['id'];
                if (id is! int) return;

                try {
                  await CalendarService.instance.delete(id);
                } on ApiException catch (e) {
                  navigator.pop();
                  messenger.showSnackBar(SnackBar(
                    content: Text(e.message),
                    backgroundColor: AppColors.coralRed,
                  ));
                  return;
                }

                _loadSchedules();
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('일정이 삭제되었습니다.'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppColors.coralRed,
                  ),
                );
              },
              child: const Text('삭제', style: TextStyle(color: AppColors.coralRed, fontWeight: FontWeight.w400)),
            ),
          ],
        );
      },
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
        const SizedBox(height: 24),
        _buildTodayRecordSection(),
      ],
    );
  }

  Widget _buildWeeklyAvgConditionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF28292D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 주 평균 컨디션 지수',
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF90939A),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: 78 /100 (Centered /100 vertically next to 78)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _weeklyAvgConditionScore?.toString() ?? _noData,
                    style: GoogleFonts.outfit(
                      fontSize: 42,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFE4FBCB),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      ' /100',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withAlpha(210),
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),

              // Right: Bar Chart & Date Subtext
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildRecordBarChart(),
                  const SizedBox(height: 10),
                  Text(
                    _fullTodayDateWithWeekday,
                    style: const TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF90939A),
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
    final barHeights = [18.0, 24.0, 30.0, 48.0, 40.0, 22.0, 30.0];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final isHighlight = index == 3;
        return Container(
          margin: EdgeInsets.only(left: index == 0 ? 0 : 5.0),
          width: 14,
          height: barHeights[index],
          decoration: BoxDecoration(
            color: isHighlight
                ? const Color(0xFFE4FBCB)
                : (index == 2 || index == 4
                    ? const Color(0xFF566352)
                    : const Color(0xFF43474E)),
            borderRadius: BorderRadius.circular(6),
            boxShadow: isHighlight
                ? const [
                    BoxShadow(
                      color: Color(0x66E4FBCB),
                      blurRadius: 10,
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
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),

        if (_schedules.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                '오늘 예정된 일정이 없습니다.',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 14,
                  color: AppColors.slateGray,
                ),
              ),
            ),
          )
        else
          ..._schedules.map((schedule) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildRecordScheduleCardItem(schedule),
            );
          }),
      ],
    );
  }

  Widget _buildRecordScheduleCardItem(Map<String, dynamic> schedule) {
    final title = schedule['title'] as String? ?? '';
    final time = schedule['time'] as String? ?? '';
    final isCompleted = schedule['isCompleted'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF28292D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Title & Sub-info (Time)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_outlined,
                    color: Color(0xFF90939A),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF90939A),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Status Pill Tag (If completed: 리추얼 완료) + Circle Arrow Button
          Row(
            children: [
              if (isCompleted) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF505560),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '리추얼 완료',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFF1F2023),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: isCompleted ? Colors.white : const Color(0xFF555860),
                  size: 18,
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
        // 1. HR 심박수 섹션 (통계 + 라인 차트)
        _buildHrSection(),
        const SizedBox(height: 28),

        // 2. HRV 심박변이도 섹션 (통계 + 요일별 막대 차트)
        _buildHrvSection(),
        const SizedBox(height: 28),

        // 3. AI 분석 · 현재 상태 카드
        _buildAiAnalysisCard(),
        const SizedBox(height: 24),

        // 4. 의료 참고용 하단 안내 문구
        _buildMedicalDisclaimerText(),
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
                fontWeight: FontWeight.w400,
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
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF28292D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _buildStatColumn(
                label: '평균',
                value: _avgHrStr,
                unit: 'bpm',
                valueColor: const Color(0xFFE4FBCB),
              ),
              _buildVerticalDivider(),
              _buildStatColumn(
                label: '최고',
                value: _maxHrStr,
                unit: 'bpm',
                valueColor: const Color(0xFFF9F6AF),
              ),
              _buildVerticalDivider(),
              _buildStatColumn(
                label: '최소',
                value: _minHrStr,
                unit: 'bpm',
                valueColor: const Color(0xFFDCE7F8),
              ),
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
                  fontWeight: FontWeight.w400,
                  color: AppColors.lightGray,
                ),
              ),
              const SizedBox(height: 16),

              // Custom Line Chart Container
              SizedBox(
                height: 200,
                width: double.infinity,
                child: CustomPaint(
                  painter: _HrLineChartPainter(
                    // Nulls are days without a reading, and the painter skips
                    // them rather than drawing a line through zero.
                    hrList: _daily.map((d) => d.hr?.round()).toList(),
                  ),
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
                fontWeight: FontWeight.w400,
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
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF28292D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _buildStatColumn(
                label: '평균',
                value: _avgHrvStr,
                unit: 'ms',
                valueColor: const Color(0xFFE4FBCB),
              ),
              _buildVerticalDivider(),
              _buildStatColumn(
                label: '최고',
                value: _maxHrvStr,
                unit: 'ms',
                valueColor: const Color(0xFFF9F6AF),
              ),
              _buildVerticalDivider(),
              _buildStatColumn(
                label: '최소',
                value: _minHrvStr,
                unit: 'ms',
                valueColor: const Color(0xFFDCE7F8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // "요일별 평균 HRV" Bar Chart Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF28292D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '요일별 평균 HRV',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
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

  /// 7 Vertical Rounded Bars Chart for HRV (월~일 matching 레퍼런스 이미지)
  Widget _buildHrvBarChart() {
    // Days with no reading draw as an empty stub. There used to be a sample
    // week here — 22, 26, 32… — which rendered a full chart for someone who
    // had never measured anything.
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final Map<int, int?> dailyAvgs = {for (var w = 1; w <= 7; w++) w: null};
    int? highestVal;
    int? lowestVal;

    for (final day in _daily) {
      final hrv = day.hrv?.round();
      if (hrv == null) continue;
      dailyAvgs[day.date.weekday] = hrv;
      if (highestVal == null || hrv > highestVal) highestVal = hrv;
      if (lowestVal == null || hrv < lowestVal) lowestVal = hrv;
    }

    final hrvData = List.generate(7, (i) {
        final w = i + 1; // 1 = Mon, 7 = Sun
        final val = dailyAvgs[w];
        if (val == null) {
          return {
            'day': dayNames[i],
            'val': null,
            'height': 8.0,
            'color': const Color(0xFF38393F),
            'textColor': const Color(0xFF6E727C),
          };
        }

        final double ratio = (val / 45.0).clamp(0.2, 1.0);
        final double height = ratio * 120.0;
        final bool isHighest = (val == highestVal);
        final bool isLowest = (val == lowestVal && highestVal != lowestVal);

        Color barColor = const Color(0xFF555861);
        Color textColor = const Color(0xFF80848E);

        if (isHighest) {
          barColor = const Color(0xFFE4FBCB);
          textColor = const Color(0xFFE4FBCB);
        } else if (isLowest) {
          barColor = const Color(0xFFF9F6AF);
          textColor = const Color(0xFFF9F6AF);
        }

        return {
          'day': dayNames[i],
          'val': val,
          'height': height,
          'color': barColor,
          'textColor': textColor,
          'hasDot': isHighest || isLowest,
        };
      });

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
                fontWeight: hasDot ? FontWeight.w400 : FontWeight.w400,
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
      child: Padding(
        padding: const EdgeInsets.only(left: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF90939A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: valueColor ?? AppColors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF90939A),
                  ),
                ),
              ],
            ),
          ],
        ),
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
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF28292D),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title (No chevron >)
              const Text(
                '심박수가 높아지는 순간, 리추얼이 도움이 될 수 있어요',
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),

              // Rich Text Insights
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF90939A),
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(text: '오늘의 평균 심박수는 '),
                    TextSpan(
                      text: '$_avgHrStr BPM',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(text: '으로,\n정상 범위 내에서 안정적인 상태를 유지하고 있어요.\n\n'),
                    const TextSpan(text: '다만, 최고 심박수가 '),
                    TextSpan(
                      text: '$_maxHrStr BPM',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(text: '까지 상승한 순간이 있었어요.\n이는 일시적인 긴장이나 집중, 혹은 다가오는 일정에 대한 준비 상태로 볼 수 있어요.\n\n'),
                    const TextSpan(text: '최저 심박수는 '),
                    TextSpan(
                      text: '$_minHrStr BPM',
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                    const TextSpan(text: '으로 관찰되며,\n이는 리추얼 이후 이완된 상태에서 나타나는 자연스러운 수치예요.\n\n'),
                    const TextSpan(text: '전반적인 컨디션은 양호한 편이며, 심박수가 높아지는 순간엔\n'),
                    const TextSpan(
                      text: '짧은 리추얼로 미리 준비해보는 걸 추천드려요.',
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFE4FBCB),
                      ),
                    ),
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
        // 1. Ritual Circular Active/Quick Action Button
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
              color: Color(0xFFE4FBCB),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/nav_ritual.png',
                  width: 22,
                  height: 22,
                  color: const Color(0xFF1E1E20),
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.monitor_heart_outlined,
                    color: Color(0xFF1E1E20),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ritual',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1E1E20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 2. Main Navigation Bar Capsule Container
        Expanded(
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF35373C),
              borderRadius: BorderRadius.circular(29),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    assetPath: 'assets/images/nav_home.png',
                    fallbackIcon: Icons.home_outlined,
                    label: 'Home',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    assetPath: 'assets/images/nav_log.png',
                    fallbackIcon: Icons.calendar_today_outlined,
                    label: 'Log',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 2,
                    assetPath: 'assets/images/nav_breath.png',
                    fallbackIcon: Icons.air_rounded,
                    label: 'Breath',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Single Nav Tab Item (Aligned vertically with Icon + Label)
  Widget _buildNavItem({
    required int index,
    required String assetPath,
    required IconData fallbackIcon,
    required String label,
  }) {
    final isSelected = _selectedNavIndex == index;

    return GestureDetector(
      onTap: () => _onBottomNavTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1E20) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              width: 20,
              height: 20,
              color: isSelected ? Colors.white : const Color(0xFF82868E),
              errorBuilder: (context, error, stackTrace) => Icon(
                fallbackIcon,
                color: isSelected ? Colors.white : const Color(0xFF82868E),
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w400 : FontWeight.w400,
                color: isSelected ? Colors.white : const Color(0xFF82868E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter for "이번 주 HR 추이" Line Chart
class _HrLineChartPainter extends CustomPainter {
  /// One slot per day of the week; null where nothing was measured.
  final List<int?> hrList;

  _HrLineChartPainter({this.hrList = const []});

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

      // Draw vertical dashed grid line for each day column
      final vPath = Path();
      for (double dy = 0; dy < h - 24; dy += 6) {
        vPath.moveTo(x, dy);
        vPath.lineTo(x, math.min(dy + 3, h - 24));
      }
      canvas.drawPath(vPath, gridPaint);

      final textSpan = TextSpan(text: xDays[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, h - 14));
    }

    // Only the days that actually have a reading get a point. There was a
    // fallback week here — 50, 60, 65… — that drew a full trend line for an
    // account with no measurements at all.
    final double stepX =
        hrList.length > 1 ? chartW / (hrList.length - 1) : chartW;

    final List<Offset> points = [];
    for (int i = 0; i < hrList.length; i++) {
      final val = hrList[i];
      if (val == null) continue;
      // Normalize val between 20 and 120 (0.0 to 1.0)
      final norm = ((val - 20) / (120 - 20)).clamp(0.0, 1.0);
      final y = (h - 24) - norm * (h - 24 - 15);
      final x = startX + i * stepX;
      points.add(Offset(x, y));
    }

    if (points.isNotEmpty) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      if (points.length == 1) {
        path.lineTo(points.first.dx + 1, points.first.dy);
      } else {
        for (int i = 0; i < points.length - 1; i++) {
          final p0 = points[i];
          final p1 = points[i + 1];
          final controlX = (p0.dx + p1.dx) / 2;
          path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
        }
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

      // Draw dots for each measurement point
      for (final pt in points) {
        canvas.drawCircle(
          pt,
          3.0,
          Paint()..color = AppColors.lightMint,
        );
      }

      // Point Dot & Badge Tooltip on Last Highlight Point
      final lastPoint = points.last;
      // The most recent day that actually has a reading, not the last slot —
      // the week's later days are usually still empty.
      final latestValue = hrList.lastWhere((v) => v != null, orElse: () => null);

      canvas.drawCircle(
        lastPoint,
        5.0,
        Paint()..color = AppColors.white,
      );

      const badgeWidth = 36.0;
      const badgeHeight = 22.0;
      final badgeOffset = Offset(
        (lastPoint.dx - badgeWidth / 2).clamp(startX, w - badgeWidth),
        (lastPoint.dy - badgeHeight - 8).clamp(0.0, h - 24),
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

      final badgeTextSpan = TextSpan(
        text: '$latestValue',
        style: const TextStyle(
          fontFamily: AppFonts.pretendard,
          fontSize: 12,
          fontWeight: FontWeight.w400,
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
  }

  @override
  bool shouldRepaint(covariant _HrLineChartPainter oldDelegate) =>
      oldDelegate.hrList != hrList;
}
