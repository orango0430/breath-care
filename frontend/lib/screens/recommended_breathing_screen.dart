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

  const RitualCardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imagePath,
    this.isBookmarked = true,
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
  final PageController _pageController = PageController(viewportFraction: 0.76);

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
    ),
    RitualCardItem(
      id: '2',
      title: '4-4-4-4 박스 호흡',
      description: '몰입 및 집중력 극대화 호흡',
      category: '시험',
      imagePath: 'assets/images/bg_breath_box_4444.png',
      isBookmarked: true,
    ),
    RitualCardItem(
      id: '3',
      title: '5.5-5.5 공진 호흡',
      description: '자율신경 균형 및 HRV 수치 극대화',
      category: '면접',
      imagePath: 'assets/images/bg_breath_resonance.png',
      isBookmarked: true,
    ),
    RitualCardItem(
      id: '4',
      title: '생리학적 한숨',
      description: '급속 CO₂ 배출 및 즉각적 심박수 강하',
      category: '발표',
      imagePath: 'assets/images/bg_breath_sigh.png',
      isBookmarked: false,
    ),
    RitualCardItem(
      id: '5',
      title: '4-6 릴랙스 호흡',
      description: '초보자 맞춤형 마일드 이완 및 안정을 도움',
      category: '면접',
      imagePath: 'assets/images/bg_breath_46_relax.png',
      isBookmarked: false,
    ),
    RitualCardItem(
      id: '6',
      title: '4-2-4-2 세미 박스 호흡',
      description: '저부담 인지 조절 및 일상 루틴 유지',
      category: '시험',
      imagePath: 'assets/images/bg_breath_semi_box.png',
      isBookmarked: false,
    ),
    RitualCardItem(
      id: '7',
      title: '2-1-4-1 횡격막 복식호흡',
      description: '횡격막 가동 및 복부 내장기 긴장 해소',
      category: '발표',
      imagePath: 'assets/images/bg_breath_diaphragmatic.png',
      isBookmarked: false,
    ),
    RitualCardItem(
      id: '8',
      title: '4-1-2-1 각성 호흡',
      description: '혈류 산소 순환 촉진 및 두뇌 에너징',
      category: '시험',
      imagePath: 'assets/images/bg_breath_awakening.png',
      isBookmarked: false,
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
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top App Header (BPACE Logo, Bell Icon, Profile Avatar)
              _buildHeader(context),
              const SizedBox(height: 20),

              // 2. Main Title: Time For \n Your Ritual
              Text(
                'Time For\nYour Ritual',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white,
                  height: 1.15,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 20),

              // 3. Search Bar Field Box
              _buildSearchBar(),
              const SizedBox(height: 24),

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
              const SizedBox(height: 14),

              // 5. Category Chips Row (발표, 시험, 면접, +)
              _buildCategoryChips(),
              const SizedBox(height: 20),

              // 6. Featured Carousel Cards PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _ritualItems.length,
                  itemBuilder: (context, index) {
                    final item = _ritualItems[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: _buildRitualCard(item),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Top Header Bar (With GUEST pictogram avatar as requested)
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const BpaceLogo(height: 24, fontSize: 20, iconSize: 22),
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
              left: 20,
              right: 20,
              bottom: 24,
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

                  // Bottom Action Pill Bar: [ Glassmorphic 시작하기 ]   (->)
                  Row(
                    children: [
                      // Translucent Glassmorphism Button: 시작하기
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => BreathingExerciseScreen(
                                  title: item.title,
                                  bgImagePath: item.imagePath,
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

                      // White Circle Right Arrow Button (->)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BreathingExerciseScreen(
                                title: item.title,
                                bgImagePath: item.imagePath,
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
}
