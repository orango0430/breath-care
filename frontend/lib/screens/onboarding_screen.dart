import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/bpace_logo.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Top Logo Header
              const Center(
                child: BpaceLogo(
                  iconSize: 26,
                  fontSize: 20,
                ),
              ),

              const Spacer(flex: 3),

              // Main Center Title & Subtitle
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Time For\nYour Ritual',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.gmarketSans,
                      fontSize: 34,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                      height: 1.25,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    '중요한 순간을 앞두고,\n당신의 컨디션을 미리 준비해요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.lightGray,
                      height: 1.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 4),

              // Bottom CTA Button: "Ritual 시작하기"
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _completeOnboarding(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightMint,
                    foregroundColor: AppColors.darkBg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Ritual 시작하기',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBg,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
