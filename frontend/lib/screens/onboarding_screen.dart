import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/bpace_logo.dart';
import 'permission_request_screen.dart';

class OnboardingItem {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingItem({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingItem> _items = [
    OnboardingItem(
      imagePath: 'assets/images/onboarding_1.png',
      title: 'Your Breath,\nYour Pace',
      description: '모두에게 같은 호흡법이 맞는 것은 아니니까.\n내 몸의 반응에 맞는 호흡 리듬을 찾아보세요.',
    ),
    OnboardingItem(
      imagePath: 'assets/images/onboarding_2.png',
      title: 'Read\nYour Body',
      description: '스마트폰으로 현재 상태를 확인하고,\n호흡 전후의 반응을 바탕으로 나에게 맞는 페이스를 찾아요.',
    ),
    OnboardingItem(
      imagePath: 'assets/images/onboarding_3.png',
      title: 'Breathe Ahead',
      description: '중요한 일정에 맞춰,\n나에게 잘 맞았던 호흡을 필요한 순간에 준비해요.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PermissionRequestScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _onNextPressed() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToNext();
    }
  }

  void _onSkipPressed() {
    _navigateToNext();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _items[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // 1. Swipeable Background Images via PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final isSecondSlide = index == 1;
              final isThirdSlide = index == 2;
              if (isSecondSlide) {
                return Transform.scale(
                  scale: 1.88,
                  alignment: const Alignment(0.50, 0.12),
                  child: Image.asset(
                    _items[index].imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: AppColors.darkBg);
                    },
                  ),
                );
              }
              if (isThirdSlide) {
                return Transform.scale(
                  scale: 1.22,
                  alignment: const Alignment(-0.30, -0.65),
                  child: Image.asset(
                    _items[index].imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: AppColors.darkBg);
                    },
                  ),
                );
              }
              return Image.asset(
                _items[index].imagePath,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: AppColors.darkBg);
                },
              );
            },
          ),

          // 2. Dark Vignette Gradient Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(140),
                      Colors.black.withAlpha(50),
                      Colors.black.withAlpha(200),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Foreground UI Layer matching exact design screenshot
          SafeArea(
            child: ResponsiveContainer(
              maxWidth: 600,
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 95),
                  // Top Logo Header: BPACE (Enlarged size)
                  const BpaceLogo(
                    height: 52,
                    fontSize: 30,
                    iconSize: 42,
                    useFullImage: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Time For Your Ritual',
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.white,
                      letterSpacing: 2.2,
                    ),
                  ),

                  // Flex Spacer pushing title down further to match lower positioning
                  const Spacer(flex: 14),

                  // Main Title (Your Breath, Your Pace)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      currentItem.title,
                      key: ValueKey<String>(currentItem.title),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                        color: AppColors.white,
                        height: 1.22,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sub-description Text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      currentItem.description,
                      key: ValueKey<String>(currentItem.description),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: AppFonts.pretendard,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.lightGray,
                        height: 1.55,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // 3-dot Page Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_items.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: isActive ? 7.0 : 6.0,
                        height: isActive ? 7.0 : 6.0,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.white
                              : AppColors.white.withAlpha(90),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),

                  const Spacer(flex: 1),

                  // Bottom Navigation Controls (Onboarding 1 & 2: Skip + Arrow, Onboarding 3: Light Mint 시작하기 Button)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentPage < _items.length - 1
                        ? Stack(
                            key: const ValueKey('onboarding_nav_arrows'),
                            alignment: Alignment.center,
                            children: [
                              // Centered Skip Button
                              GestureDetector(
                                onTap: _onSkipPressed,
                                behavior: HitTestBehavior.opaque,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                  child: Text(
                                    '건너뛰기',
                                    style: TextStyle(
                                      fontFamily: AppFonts.pretendard,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.lightGray,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                              ),

                              // Right-aligned Circle Arrow Button
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: _onNextPressed,
                                  child: Container(
                                    width: 56,
                                    height: 56,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            key: const ValueKey('onboarding_start_button'),
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _navigateToNext,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.lightMint,
                                foregroundColor: AppColors.darkBg,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Text(
                                '시작하기',
                                style: TextStyle(
                                  fontFamily: AppFonts.pretendard,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.darkBg,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

