import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/bpace_logo.dart';
import 'breathing_exercise_screen.dart';
import 'my_page_screen.dart';

/// Ritual Item Model for Carousel
class RitualCardItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imagePath;
  final bool isBookmarked;
  final double inhaleSec;
  final double inhale2Sec;
  final double holdSec;
  final double exhaleSec;
  final double hold2Sec;

  const RitualCardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imagePath,
    this.isBookmarked = true,
    this.inhaleSec = 4.0,
    this.inhale2Sec = 0.0,
    this.holdSec = 7.0,
    this.exhaleSec = 8.0,
    this.hold2Sec = 0.0,
  });
}

/// Recommended Breathing Screen (새로운 추천 Ritual 호흡 메인 화면)
class RecommendedBreathingScreen extends StatefulWidget {
  const RecommendedBreathingScreen({super.key});

  @override
  State<RecommendedBreathingScreen> createState() =>
      _RecommendedBreathingScreenState();
}

class _RecommendedBreathingScreenState
    extends State<RecommendedBreathingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.78);

  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['발표', '시험', '면접'];

  final List<RitualCardItem> _ritualItems = const [
    RitualCardItem(
      id: '1',
      title: '4-7-8 호흡',
      description: '긴장을 천천히 가라앉히는 호흡',
      category: '발표',
      imagePath: 'assets/images/bg_breath_478.png',
      isBookmarked: true,
      inhaleSec: 4.0,
      inhale2Sec: 0.0,
      holdSec: 7.0,
      exhaleSec: 8.0,
      hold2Sec: 0.0,
    ),
    RitualCardItem(
      id: '2',
      title: '4-4-4-4 박스 호흡',
      description: '몰입 및 집중력 극대화 호흡',
      category: '시험',
      imagePath: 'assets/images/bg_breath_box_4444.png',
      isBookmarked: true,
      inhaleSec: 4.0,
      inhale2Sec: 0.0,
      holdSec: 4.0,
      exhaleSec: 4.0,
      hold2Sec: 4.0,
    ),
    RitualCardItem(
      id: '3',
      title: '5-5 공진 호흡',
      description: '자율신경 균형 및 HRV 수치 극대화',
      category: '면접',
      imagePath: 'assets/images/bg_breath_resonance.png',
      isBookmarked: true,
      inhaleSec: 5.0,
      inhale2Sec: 0.0,
      holdSec: 0.0,
      exhaleSec: 5.0,
      hold2Sec: 0.0,
    ),
    RitualCardItem(
      id: '4',
      title: '생리학적 한숨',
      description: '들숨 2초 + 추가들숨 1초 - 날숨 6초',
      category: '발표',
      imagePath: 'assets/images/bg_breath_sigh.png',
      isBookmarked: false,
      inhaleSec: 2.0,
      inhale2Sec: 1.0,
      holdSec: 0.0,
      exhaleSec: 6.0,
      hold2Sec: 0.0,
    ),
    RitualCardItem(
      id: '5',
      title: '4-6 릴랙스 호흡',
      description: '초보자 맞춤형 마일드 이완 및 안정을 도움',
      category: '면접',
      imagePath: 'assets/images/bg_breath_46_relax.png',
      isBookmarked: false,
      inhaleSec: 4.0,
      holdSec: 0.0,
      exhaleSec: 6.0,
    ),
    RitualCardItem(
      id: '6',
      title: '4-2-4-2 세미 박스 호흡',
      description: '저부담 인지 조절 및 일상 루틴 유지',
      category: '시험',
      imagePath: 'assets/images/bg_breath_semi_box.png',
      isBookmarked: false,
      inhaleSec: 4.0,
      holdSec: 2.0,
      exhaleSec: 4.0,
    ),
    RitualCardItem(
      id: '7',
      title: '2-1-4-1 횡격막 복식호흡',
      description: '횡격막 가동 및 복부 내장기 긴장 해소',
      category: '발표',
      imagePath: 'assets/images/bg_breath_diaphragmatic.png',
      isBookmarked: false,
      inhaleSec: 2.0,
      holdSec: 1.0,
      exhaleSec: 4.0,
    ),
    RitualCardItem(
      id: '8',
      title: '4-1-2-1 각성 호흡',
      description: '혈류 산소 순환 촉진 및 두뇌 에너징',
      category: '시험',
      imagePath: 'assets/images/bg_breath_awakening.png',
      isBookmarked: false,
      inhaleSec: 4.0,
      holdSec: 1.0,
      exhaleSec: 2.0,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _addCustomCategory() {
    showDialog(
      context: context,
      builder: (context) {
        final categoryController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppColors.darkCharcoal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '새 카테고리 추가',
            style: TextStyle(
              fontFamily: AppFonts.pretendard,
              fontSize: 16,
              color: AppColors.white,
            ),
          ),
          content: TextField(
            controller: categoryController,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              hintText: '카테고리명 입력 (예: 면접)',
              hintStyle: TextStyle(color: AppColors.slateGray),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소', style: TextStyle(color: AppColors.slateGray)),
            ),
            TextButton(
              onPressed: () {
                final text = categoryController.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _categories.add(text);
                    _selectedCategoryIndex = _categories.length - 1;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('추가', style: TextStyle(color: AppColors.lightMint)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top App Header (Identical to Home & Log screens)
        _buildHeader(context),
        const SizedBox(height: 18),

        // 2. Main Title: Time For \n Your Ritual (Identical to Home & Log screens)
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
        const SizedBox(height: 18),

        // 3. Search Bar Field Box
        _buildSearchBar(),
        const SizedBox(height: 20),

        // 4. Section Header: 추천 Ritual
        const Text(
          '추천 Ritual',
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 12),

        // 5. Category Chips Row (발표, 시험, 면접, +)
        _buildCategoryChips(),
        const SizedBox(height: 16),

        // 6. Featured Carousel Cards PageView matching Image 3 squarish 3D scaling effect
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 0.90,
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double page = 0.0;
                  if (_pageController.hasClients && _pageController.position.haveDimensions) {
                    page = _pageController.page ?? 0.0;
                  }
                  return PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _ritualItems.length,
                    itemBuilder: (context, index) {
                      final item = _ritualItems[index];
                      final diff = (index - page).abs();
                      final scale = (1.0 - diff * 0.14).clamp(0.86, 1.0);
                      final opacity = (1.0 - diff * 0.35).clamp(0.65, 1.0);

                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
                            child: _buildRitualCard(item),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// 1. Top Header Bar (With GUEST pictogram avatar as requested)
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const BpaceLogo(iconSize: 24, fontSize: 18),
        Row(
          children: [
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('알림함으로 이동합니다.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.white,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 14),
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

  /// 3. Search Bar Container Field
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252628),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontFamily: AppFonts.pretendard,
          fontSize: 15,
          color: AppColors.white,
        ),
        decoration: const InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 15,
            color: AppColors.slateGray,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.slateGray,
              size: 22,
            ),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 50),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// 5. Category Chips Row (발표, 시험, 면접, +)
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...List.generate(_categories.length, (index) {
            final isSelected = _selectedCategoryIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.white : const Color(0xFF252628),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.darkBg : AppColors.lightGray,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Plus (+) Add Category Button
          GestureDetector(
            onTap: _addCustomCategory,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF252628),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.lightGray,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 6. Featured Ritual Card Component matching screenshot
  Widget _buildRitualCard(RitualCardItem item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF2B2D32),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image / Gradient
            Image.asset(
              item.imagePath,
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

            // Dark Frosted Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(30),
                    Colors.black.withAlpha(140),
                    Colors.black.withAlpha(220),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Bookmark Ribbon Icon on Top Right
            Positioned(
              top: 18,
              right: 18,
              child: Icon(
                item.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: AppColors.white,
                size: 26,
              ),
            ),

            // Bottom Content Information & Action Buttons
            Positioned(
              left: 18,
              right: 18,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title: 4-7-8 호흡
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle Description: 긴장을 천천히 가라앉히는 호흡
                  Text(
                    item.description,
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withAlpha(210),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Single Unified Integrated Glass Pill Bar Button (일체형 글래스 버튼)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BreathingExerciseScreen(
                            title: item.title,
                            bgImagePath: item.imagePath,
                            targetInhaleSec: item.inhaleSec,
                            targetInhale2Sec: item.inhale2Sec,
                            targetHoldSec: item.holdSec,
                            targetExhaleSec: item.exhaleSec,
                            targetHold2Sec: item.hold2Sec,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.only(left: 16, right: 5, top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(45),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withAlpha(70),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.only(left: 32.0),
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
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.darkBg,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
