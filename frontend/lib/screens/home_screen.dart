import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/bpace_logo.dart';
import 'log_screen.dart';
import 'condition_measurement_screen.dart';
import 'recommended_breathing_screen.dart';
import 'my_page_screen.dart';
import '../utils/ppg_sensor_service.dart';
import '../utils/schedule_storage_service.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.initialIndex = 0, // Default to Home Screen (index 0)
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Dynamic state variables for measurement data
  int conditionScore = 78;
  int heartRate = 88;
  int hrvValue = 24;

  // Selected bottom navigation index (0: Home, 1: Log, 2: Breath)
  int _selectedNavIndex = 0;

  List<Map<String, dynamic>> _homeSchedules = [];

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialIndex;
    _loadSavedMeasurementData();
    _loadHomeSchedules();
  }

  Future<void> _loadHomeSchedules() async {
    final loaded = await ScheduleStorageService.loadSchedules();
    if (mounted) {
      setState(() {
        // 홈 화면 '오늘의 일정' 카드는 준비완료(리추얼 완료)된 일정은 제외하고 미완료된 예정 일정만 표시
        _homeSchedules = loaded.where((s) => s['isCompleted'] != true).toList();
      });
    }
  }

  Future<void> _loadSavedMeasurementData() async {
    final latestRes = PpgSensorService.latestResult;
    final prefs = await SharedPreferences.getInstance();
    final savedScore = prefs.getInt('latest_condition_score');
    final savedBpm = prefs.getInt('latest_bpm');
    final savedHrv = prefs.getInt('latest_hrv');

    if (mounted) {
      setState(() {
        if (latestRes != null) {
          conditionScore = latestRes.conditionScore;
          heartRate = latestRes.bpm;
          hrvValue = latestRes.hrvSdnnMs.round();
        } else if (savedScore != null) {
          conditionScore = savedScore;
          if (savedBpm != null) heartRate = savedBpm;
          if (savedHrv != null) hrvValue = savedHrv;
        }
      });
    }
  }

  // Format today's date dynamically (e.g., 2026년 8월 11일)
  String get _todayDateString {
    final now = DateTime.now();
    return '${now.year}년 ${now.month}월 ${now.day}일';
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
              // Main Scrollable Content (switches between Home ritual view and Breath management view)
              _selectedNavIndex == 2
                  ? const Padding(
                      padding: EdgeInsets.only(top: 12.0, bottom: 90.0),
                      child: RecommendedBreathingScreen(),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(top: 12.0, bottom: 90.0),
                      child: _buildHomeView(),
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

  // ==========================================
  // VIEW 1: BREATH MANAGEMENT SCREEN (Index 2)
  // ==========================================

  // ==========================================
  // VIEW 2: ORIGINAL HOME RITUAL SCREEN (Index 0)
  // ==========================================

  // ==========================================
  // VIEW 2: ORIGINAL HOME RITUAL SCREEN (Index 0)
  // ==========================================

  Widget _buildHomeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top App Header: Logo + Notification Bell + Guest Avatar
        _buildHeader(),
        const SizedBox(height: 18),

        // Title & Dynamic Today's Date
        _buildTitleAndDateSection(),
        const SizedBox(height: 18),

        // Today's Condition Score Card with Bar Chart
        _buildConditionIndexCard(),
        const SizedBox(height: 14),

        // HR & HRV Metric Cards Row
        _buildMetricCardsRow(),
        const SizedBox(height: 20),

        // Today's Schedule Section
        _buildScheduleSection(),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 1. Top Header Row for Home View
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
            _buildProfileAvatar(),
          ],
        ),
      ],
    );
  }

  /// Profile Avatar Icon Button
  Widget _buildProfileAvatar() {
    return GestureDetector(
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
    );
  }

  /// 2. Title and Dynamic Date Section
  Widget _buildTitleAndDateSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
        InkWell(
          onTap: () {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const LogScreen(initialSubTab: 0),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _todayDateString,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGray,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.lightGray,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 3. Today's Condition Index Card
  Widget _buildConditionIndexCard() {
    final latestRes = PpgSensorService.latestResult;
    final displayScore = latestRes != null
        ? (latestRes.hrvSdnnMs * 1.4 + 40).clamp(50.0, 96.0).round()
        : conditionScore;

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
            '오늘의 컨디션 지수',
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF90939A),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Score /100 (Centered /100 vertically next to score)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '$displayScore',
                    style: GoogleFonts.outfit(
                      fontSize: 46,
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

              _buildConditionBarChart(),
            ],
          ),
        ],
      ),
    );
  }

  /// 7 Vertical Bars Graphic matching log screen
  Widget _buildConditionBarChart() {
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

  /// 4. HR & HRV Metric Cards Row (Matching Screenshot 100%)
  Widget _buildMetricCardsRow() {
    final latestRes = PpgSensorService.latestResult;
    final displayBpm = latestRes?.bpm ?? heartRate;
    final displayHrv = latestRes != null ? latestRes.hrvSdnnMs.round() : hrvValue;

    return Row(
      children: [
        // Left: HR (Heart Rate) Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCE7F8),
              borderRadius: BorderRadius.circular(22),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1E1E20),
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '심박수',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6E727A),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.favorite_border_rounded,
                      color: Color(0xFF1E1E20),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$displayBpm',
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 34,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1E1E20),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'bpm',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF4A4D54),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Right: HRV (Heart Rate Variability) Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6AF),
              borderRadius: BorderRadius.circular(22),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1E1E20),
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '심박변이도',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6E727A),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.monitor_heart_outlined,
                      color: Color(0xFF1E1E20),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$displayHrv',
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 34,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1E1E20),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ms',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF4A4D54),
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

  /// 5. Today's Schedule Section (Matching Screenshot 100%)
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
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LogScreen(initialSubTab: 0),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '전체보기',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF90939A),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF90939A),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_homeSchedules.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              '오늘 등록된 일정이 없습니다.',
              style: TextStyle(color: Color(0xFF90939A)),
            ),
          )
        else
          ..._homeSchedules.map((schedule) {
            final title = schedule['title'] as String? ?? '';
            final time = schedule['time'] as String? ?? '';
            final isCompleted = schedule['isCompleted'] as bool? ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildScheduleCard(
                title: title,
                time: time,
                isCompleted: isCompleted,
                onTapPrepare: isCompleted
                    ? null
                    : () {
                        final id = (schedule['id'] as String?) ?? title;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ConditionMeasurementScreen(
                              scheduleTitle: id,
                            ),
                          ),
                        ).then((_) => _loadHomeSchedules());
                      },
              ),
            );
          }),
      ],
    );
  }

  /// Single Schedule Item Card Widget
  Widget _buildScheduleCard({
    required String title,
    required String time,
    required bool isCompleted,
    required VoidCallback? onTapPrepare,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF28292D),
        borderRadius: BorderRadius.circular(20),
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

          ElevatedButton(
            onPressed: onTapPrepare,
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
    );
  }

  // ==========================================
  // COMMON: BOTTOM FLOATING NAVIGATION BAR
  // ==========================================

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

  void _onBottomNavTap(int index) {
    if (index == _selectedNavIndex) return;

    if (index == 1) {
      // Navigate to Log Screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LogScreen(),
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
