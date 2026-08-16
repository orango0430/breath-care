import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/bpace_logo.dart';
import 'splash_screen.dart';
import 'log_screen.dart';
import 'condition_measurement_screen.dart';
import 'recommended_breathing_screen.dart';
import 'breathing_exercise_screen.dart';
import 'my_page_screen.dart';
import '../utils/ppg_sensor_service.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedNavIndex = widget.initialIndex;
  }

  // Format today's date dynamically (e.g., 2026년 8월 11일)
  String get _todayDateString {
    final now = DateTime.now();
    return '${now.year}년 ${now.month}월 ${now.day}일';
  }

  Future<void> _resetOnboarding() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_seen_onboarding');

    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(
        content: Text('온보딩 상태가 초기화되었습니다. 스플래쉬 화면으로 이동합니다.'),
        duration: Duration(seconds: 1),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    navigator.pushReplacement(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
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
          child: Stack(
            children: [
              // Main Scrollable Content (switches between Home ritual view and Breath management view)
              _selectedNavIndex == 2
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 80.0),
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
        _buildConditionCard(),
        const SizedBox(height: 14),

        // HR & HRV Metric Cards Row
        _buildMetricCardsRow(),
        const SizedBox(height: 20),

        // Today's Schedule Section
        _buildScheduleSection(),
        const SizedBox(height: 16),

        // Reset Onboarding Dev Helper
        Center(
          child: TextButton.icon(
            onPressed: _resetOnboarding,
            icon: const Icon(Icons.refresh, color: AppColors.slateGray, size: 16),
            label: const Text(
              '테스트용: 온보딩 초기화 후 다시보기',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 12,
                color: AppColors.slateGray,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
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
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: AppColors.white,
            height: 1.18,
            letterSpacing: 0.2,
          ),
        ),
        InkWell(
          onTap: () {},
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
                    fontWeight: FontWeight.w500,
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

  /// 3. Today's Condition Score Card with 7-Bar Chart Indicator
  Widget _buildConditionCard() {
    final latestRes = PpgSensorService.latestResult;
    final displayScore = latestRes?.conditionScore ?? conditionScore;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.slateDarkGray.withAlpha(75),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 컨디션 지수',
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$displayScore',
                    style: const TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      height: 1,
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
              _buildConditionBarChart(),
            ],
          ),
        ],
      ),
    );
  }

  /// 7 Vertical Bars Graphic matching design
  Widget _buildConditionBarChart() {
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

  /// 4. HR & HRV Metric Cards Row
  Widget _buildMetricCardsRow() {
    final latestRes = PpgSensorService.latestResult;
    final displayBpm = latestRes?.bpm ?? heartRate;
    final displayHrv = latestRes != null ? latestRes.hrvSdnnMs.round() : hrvValue;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkBg,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '심박수',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slateDarkGray,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.favorite_border_rounded,
                      color: AppColors.darkBg,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$displayBpm',
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkBg,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'bpm',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateDarkGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkBg,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '심박변이도',
                          style: TextStyle(
                            fontFamily: AppFonts.pretendard,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.slateDarkGray,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.monitor_heart_outlined,
                      color: AppColors.darkBg,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$displayHrv',
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkBg,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ms',
                      style: TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateDarkGray,
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

  /// 5. Today's Schedule Section
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

        _buildScheduleCard(
          title: '프로젝트 회의 일정',
          time: '오후 2:30',
          onTapPrepare: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ConditionMeasurementScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        _buildScheduleCard(
          title: '중앙해커톤 본선 피칭',
          time: '오후 6:30',
          onTapPrepare: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ConditionMeasurementScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Single Schedule Item Card Widget
  Widget _buildScheduleCard({
    required String title,
    required String time,
    required VoidCallback onTapPrepare,
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
                      color: AppColors.lightGray,
                    ),
                  ),
                ],
              ),
            ],
          ),

          ElevatedButton(
            onPressed: onTapPrepare,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightMint,
              foregroundColor: AppColors.darkBg,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              '준비하기',
              style: TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 13,
                fontWeight: FontWeight.w700,
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
        // "Ritual" Circular Quick Action Button
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

        // Main Navigation Bar Container
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
                  label: 'History',
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

  /// Single Nav Tab Item
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

/// Polyline Line Chart Painter for HRV Card with Glowing Dots
class _HrvLineChartPainter extends CustomPainter {
  final List<double> points;

  _HrvLineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final linePaint = Paint()
      ..color = Colors.white.withAlpha(216)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotGlowPaint = Paint()
      ..color = Colors.white.withAlpha(89)
      ..style = PaintingStyle.fill;

    final path = Path();
    final stepX = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height * (1.0 - points[i]);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height * (1.0 - points[i]);
      canvas.drawCircle(Offset(x, y), 4.0, dotGlowPaint);
      canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HrvLineChartPainter oldDelegate) => false;
}
