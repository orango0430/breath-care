import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'breathing_exercise_screen.dart';

/// Breathing Item Model
class BreathExerciseItem {
  final String id;
  final String title;
  final String durationAndDifficulty;
  final String description;
  final String category; // '전체', '긴장 완화', '집중 향상', '수면 준비'
  final Color boxColor;
  final bool isRecommended;
  final String? badgeText;

  const BreathExerciseItem({
    required this.id,
    required this.title,
    required this.durationAndDifficulty,
    required this.description,
    required this.category,
    required this.boxColor,
    this.isRecommended = false,
    this.badgeText,
  });
}

/// Recommended Breathing Screen (추천 호흡 화면 - 2번째 이미지)
class RecommendedBreathingScreen extends StatefulWidget {
  const RecommendedBreathingScreen({super.key});

  @override
  State<RecommendedBreathingScreen> createState() =>
      _RecommendedBreathingScreenState();
}

class _RecommendedBreathingScreenState
    extends State<RecommendedBreathingScreen> {
  // Selected category filter chip ('전체', '긴장 완화', '집중 향상', '수면 준비')
  String selectedCategory = '전체';

  final List<String> categories = const [
    '전체',
    '긴장 완화',
    '집중 향상',
    '수면 준비',
  ];

  final List<BreathExerciseItem> items = const [
    BreathExerciseItem(
      id: '1',
      title: '긴장 완화 호흡',
      durationAndDifficulty: '5분 · 중간 강도',
      description: '불안한 긴장을 낮추고 마음을 안정시켜요',
      category: '긴장 완화',
      boxColor: Color(0xFF2E453E),
      isRecommended: true,
      badgeText: '추천',
    ),
    BreathExerciseItem(
      id: '2',
      title: '복식 호흡',
      durationAndDifficulty: '3분 · 쉬움',
      description: '복부 중심으로 깊게 호흡하여 안정감을 줘요',
      category: '긴장 완화',
      boxColor: Color(0xFF344265),
      isRecommended: false,
    ),
    BreathExerciseItem(
      id: '3',
      title: '4-7-8 호흡',
      durationAndDifficulty: '4분 · 중간 강도',
      description: '불안과 스트레스를 완화해 도움을 줘요',
      category: '긴장 완화',
      boxColor: Color(0xFF47385E),
      isRecommended: false,
    ),
    BreathExerciseItem(
      id: '4',
      title: '박스 호흡',
      durationAndDifficulty: '4분 · 중간 강도',
      description: '깊은 집중과 감정 조절에 효과적이에요',
      category: '집중 향상',
      boxColor: Color(0xFF42382F),
      isRecommended: false,
    ),
    BreathExerciseItem(
      id: '5',
      title: '수면 준비 호흡',
      durationAndDifficulty: '7분 · 쉬움',
      description: '잠들기 전 긴장을 풀고 숙면을 도와줘요',
      category: '수면 준비',
      boxColor: Color(0xFF28403D),
      isRecommended: false,
    ),
  ];

  List<BreathExerciseItem> get filteredItems {
    if (selectedCategory == '전체') {
      return items;
    }
    return items
        .where((item) =>
            item.category == selectedCategory || item.isRecommended)
        .toList();
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
              // App Bar Header: Back Arrow + "호흡하기"
              _buildHeader(context),
              const SizedBox(height: 16),

              // Filter Tag Chips Bar (Horizontal Scroll)
              _buildFilterChips(),
              const SizedBox(height: 20),

              // Breathing Exercise List
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildBreathCard(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// App Bar Header with Back Arrow and Title
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.white,
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 14),
        const Text(
          '호흡하기',
          style: TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  /// Horizontal Scrollable Filter Chip Bar
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.lightMint
                      : AppColors.darkCharcoal,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.lightMint
                        : AppColors.slateDarkGray.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 13.5,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.darkBg : AppColors.lightGray,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Individual Breathing Exercise Card Component matching Image 2
  Widget _buildBreathCard(BreathExerciseItem item) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BreathingExerciseScreen(
              title: item.title,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCharcoal,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: item.isRecommended
                ? AppColors.slateDarkGray.withAlpha(120)
                : AppColors.slateDarkGray.withAlpha(50),
            width: item.isRecommended ? 1.0 : 0.8,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Left Square Thumbnail Container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: item.boxColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),

                // Middle Information Block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.durationAndDifficulty,
                        style: const TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: AppColors.lightGray,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontFamily: AppFonts.pretendard,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.lightGray.withAlpha(200),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Right Action Icon Button (Checkmark for Recommended, Play Button for others)
                if (item.isRecommended)
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BreathingExerciseScreen(
                            title: item.title,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.lightMint,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.darkBg,
                        size: 20,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BreathingExerciseScreen(
                            title: item.title,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.slateDarkGray.withAlpha(150),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.lightGray,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),

            // Top-Right "추천" Badge if applicable
            if (item.badgeText != null)
              Positioned(
                top: 0,
                right: 48, // Positioned to the left of the checkmark button
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEBFE), // Light soft blue badge
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.badgeText!,
                    style: const TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2F4D),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
