import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
    this.isBookmarked = false,
    this.inhaleSec = 4.0,
    this.inhale2Sec = 0.0,
    this.holdSec = 7.0,
    this.exhaleSec = 8.0,
    this.hold2Sec = 0.0,
  });

  RitualCardItem copyWith({
    bool? isBookmarked,
  }) {
    return RitualCardItem(
      id: id,
      title: title,
      description: description,
      category: category,
      imagePath: imagePath,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      inhaleSec: inhaleSec,
      inhale2Sec: inhale2Sec,
      holdSec: holdSec,
      exhaleSec: exhaleSec,
      hold2Sec: hold2Sec,
    );
  }
}

/// Initial Master Data for Ritual Cards (in user requested order & 5 categories)
const List<RitualCardItem> _rawRitualItems = [
  // 1. 진정
  RitualCardItem(
    id: '1',
    title: '생리학적 한숨',
    description: '벅찬 긴장을 빠르게 내려놓는 호흡',
    category: '진정',
    imagePath: 'assets/images/bg_breath_sigh.png',
    isBookmarked: false,
    inhaleSec: 2.0,
    inhale2Sec: 1.0,
    holdSec: 0.0,
    exhaleSec: 6.0,
    hold2Sec: 0.0,
  ),

  // 2~3. 이완
  RitualCardItem(
    id: '2',
    title: '4-7-8 호흡',
    description: '긴장을 천천히 가라앉히는 호흡',
    category: '이완',
    imagePath: 'assets/images/bg_breath_478.png',
    isBookmarked: false,
    inhaleSec: 4.0,
    inhale2Sec: 0.0,
    holdSec: 7.0,
    exhaleSec: 8.0,
    hold2Sec: 0.0,
  ),
  RitualCardItem(
    id: '3',
    title: '4-6 릴랙스 호흡',
    description: '일상의 긴장을 부드럽게 풀어주는 호흡',
    category: '이완',
    imagePath: 'assets/images/bg_breath_46_relax.png',
    isBookmarked: false,
    inhaleSec: 4.0,
    holdSec: 0.0,
    exhaleSec: 6.0,
  ),

  // 4~5. 집중
  RitualCardItem(
    id: '4',
    title: '4-4-4-4 박스 호흡',
    description: '흐트러진 마음을 차분히 집중시키는 호흡',
    category: '집중',
    imagePath: 'assets/images/bg_breath_box_4444.png',
    isBookmarked: false,
    inhaleSec: 4.0,
    inhale2Sec: 0.0,
    holdSec: 4.0,
    exhaleSec: 4.0,
    hold2Sec: 4.0,
  ),
  RitualCardItem(
    id: '5',
    title: '4-2-4-2 세미 박스 호흡',
    description: '부담 없이 집중력을 되찾는 호흡',
    category: '집중',
    imagePath: 'assets/images/bg_breath_semi_box.png',
    isBookmarked: false,
    inhaleSec: 4.0,
    holdSec: 2.0,
    exhaleSec: 4.0,
    hold2Sec: 2.0,
  ),

  // 6~7. 회복
  RitualCardItem(
    id: '6',
    title: '5-5 공진 호흡',
    description: '호흡의 균형을 찾아 편안해지는 호흡',
    category: '회복',
    imagePath: 'assets/images/bg_breath_resonance.png',
    isBookmarked: false,
    inhaleSec: 5.0,
    inhale2Sec: 0.0,
    holdSec: 0.0,
    exhaleSec: 5.0,
    hold2Sec: 0.0,
  ),
  RitualCardItem(
    id: '7',
    title: '2-1-4-1 횡격막 복식호흡',
    description: '지친 몸을 깊고 편안하게 이완하는 호흡',
    category: '회복',
    imagePath: 'assets/images/bg_breath_diaphragmatic.png',
    isBookmarked: false,
    inhaleSec: 2.0,
    holdSec: 1.0,
    exhaleSec: 4.0,
  ),

  // 8. 각성
  RitualCardItem(
    id: '8',
    title: '4-1-2-1 각성 호흡',
    description: '잠든 몸과 정신을 가볍게 깨우는 호흡',
    category: '각성',
    imagePath: 'assets/images/bg_breath_awakening.png',
    isBookmarked: false,
    inhaleSec: 4.0,
    holdSec: 1.0,
    exhaleSec: 2.0,
  ),
];

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
  final PageController _pageController =
      PageController(viewportFraction: 0.83, initialPage: 1002);
  String _searchQuery = '';

  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['전체', '진정', '이완', '집중', '회복', '각성'];

  List<RitualCardItem> get _filteredRitualItems {
    List<RitualCardItem> items = _ritualItems;

    // 1. 카테고리 필터링 (전체가 아닐 경우)
    if (_selectedCategoryIndex != 0) {
      final cat = _categories[_selectedCategoryIndex];
      items = items.where((item) => item.category == cat).toList();
    }

    // 2. 검색어 필터링 (제목, 한 줄 설명, 카테고리 텍스트 매칭)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((item) {
        final titleMatch = item.title.toLowerCase().contains(q);
        final descMatch = item.description.toLowerCase().contains(q);
        final catMatch = item.category.toLowerCase().contains(q);
        return titleMatch || descMatch || catMatch;
      }).toList();
    }

    return items;
  }

  late List<RitualCardItem> _ritualItems;

  @override
  void initState() {
    super.initState();
    _ritualItems = List.from(_rawRitualItems);
    _loadBookmarkedState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  Future<void> _loadBookmarkedState() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedIds = prefs.getStringList('bookmarked_ritual_ids') ?? [];
    if (bookmarkedIds.isNotEmpty) {
      if (mounted) {
        setState(() {
          _ritualItems = _rawRitualItems.map((item) {
            return item.copyWith(
              isBookmarked: bookmarkedIds.contains(item.id),
            );
          }).toList();
        });
      }
    }
  }

  Future<void> _toggleBookmark(String id) async {
    setState(() {
      final index = _ritualItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _ritualItems[index] = _ritualItems[index].copyWith(
          isBookmarked: !_ritualItems[index].isBookmarked,
        );
      }
    });

    final prefs = await SharedPreferences.getInstance();
    final bookmarkedIds = _ritualItems
        .where((item) => item.isBookmarked)
        .map((item) => item.id)
        .toList();
    await prefs.setStringList('bookmarked_ritual_ids', bookmarkedIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top App Header (Identical to Home & Log screens)
        _buildHeader(context),
        const SizedBox(height: 18),

        // 2. Main Title
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

        // 3. Search Bar Field Box
        _buildSearchBar(),
        const SizedBox(height: 20),

        // 4. Section Header: 추천 Ritual
        const Text(
          '추천 Ritual',
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 12),

        // 5. Category Chips Row (발표, 시험, 면접, +)
        _buildCategoryChips(),
        const SizedBox(height: 16),

        // 6. Featured Carousel Cards PageView (Square 1:1 AspectRatio + Infinite Loop)
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double page = 1002.0;
                  if (_pageController.hasClients && _pageController.position.haveDimensions) {
                    page = _pageController.page ?? 1002.0;
                  }
                  final displayItems = _filteredRitualItems;
                  if (displayItems.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            color: AppColors.slateGray,
                            size: 40,
                          ),
                          SizedBox(height: 10),
                          Text(
                            '검색 결과가 없습니다',
                            style: TextStyle(
                              fontFamily: AppFonts.pretendard,
                              fontSize: 14,
                              color: AppColors.slateGray,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final isLoop = displayItems.length > 1;

                  return PageView.builder(
                    controller: _pageController,
                    physics: isLoop
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemCount: isLoop ? 10000 : 1,
                    itemBuilder: (context, index) {
                      final realIndex = isLoop ? (index % displayItems.length) : 0;
                      final item = displayItems[realIndex];
                      final diff = isLoop ? (index - page).abs() : 0.0;
                      final scale = (1.0 - diff * 0.10).clamp(0.88, 1.0);
                      final opacity = (1.0 - diff * 0.45).clamp(0.55, 1.0);

                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
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
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: const TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 15,
            color: AppColors.slateGray,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.slateGray,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () => _searchController.clear(),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.cancel_rounded,
                      color: AppColors.slateGray,
                      size: 20,
                    ),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 40),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// 5. Category Chips Row (진정, 이완, 집중, 회복, 각성)
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_categories.length, (index) {
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
                    fontWeight: FontWeight.w400,
                    color: isSelected ? AppColors.darkBg : AppColors.lightGray,
                  ),
                ),
              ),
            ),
          );
        }),
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

            // Dark Frosted Vignette Overlay matching Image 2
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(40),
                    Colors.transparent,
                    Colors.black.withAlpha(120),
                    Colors.black.withAlpha(180),
                  ],
                  stops: const [0.0, 0.35, 0.70, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Bookmark Ribbon Icon on Top Right (Thinner Sleek Outline Border & Dynamic Toggle)
            Positioned(
              top: 14,
              right: 16,
              child: GestureDetector(
                onTap: () => _toggleBookmark(item.id),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    item.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border,
                    color: AppColors.white.withAlpha(item.isBookmarked ? 255 : 210),
                    size: item.isBookmarked ? 24 : 22,
                  ),
                ),
              ),
            ),

            // Bottom Content Information & Action Buttons matching Image 2 Layout
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title: 4-7-8 호흡 (w500 Medium - one step above subtitle w400)
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 7),

                  // Subtitle Description: 긴장을 천천히 가라앉히는 호흡
                  Text(
                    item.description,
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white.withAlpha(225),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Single Unified Integrated Glass Pill Bar Button matching Image 2
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: double.infinity,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(45),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withAlpha(70),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Perfectly Centered Text: 시작하기
                              const Text(
                                '시작하기',
                                style: TextStyle(
                                  fontFamily: AppFonts.pretendard,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),

                              // Right Positioned White Circle Arrow Button
                              Positioned(
                                right: 3,
                                top: 3,
                                bottom: 3,
                                child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Color(0xFF1E1E22),
                                      size: 17,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
