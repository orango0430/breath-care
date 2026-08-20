import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'home_screen.dart';

class PermissionRequestScreen extends StatelessWidget {
  const PermissionRequestScreen({super.key});

  Future<void> _completeAndNavigate(BuildContext context) async {
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

  Future<void> _requestPermissions(BuildContext context) async {
    if (!kIsWeb) {
      try {
        await Permission.camera.request();
      } catch (_) {}
    }
    if (!context.mounted) return;
    await _completeAndNavigate(context);
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
              const Spacer(flex: 2),

              // Top Permission Pebble Icon
              Image.asset(
                'assets/images/permission_icon.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(height: 64);
                },
              ),
              const SizedBox(height: 32),

              // Title Header
              const Text(
                '앱 사용을 위해\n위 권한의 허용이 필요해요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.pretendard,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.white,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 36),

              // 1. Camera Card
              _buildPermissionCard(
                icon: Icons.camera_alt_outlined,
                title: '카메라',
                subtitle: '손가락으로 맥박 반응을 측정해요',
              ),
              const SizedBox(height: 14),

              // 2. Calendar Card
              _buildPermissionCard(
                icon: Icons.calendar_today_outlined,
                title: '캘린더',
                subtitle: '일정에 맞는 호흡 타이밍을 준비해요',
              ),
              const SizedBox(height: 14),

              // 3. Notification Card
              _buildPermissionCard(
                icon: Icons.notifications_none_rounded,
                title: '알림',
                subtitle: '준비된 호흡을 제때 알려드려요',
              ),

              const Spacer(flex: 3),

              // Bottom Primary Button: "허용"
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _requestPermissions(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightMint,
                    foregroundColor: AppColors.darkBg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    '허용',
                    style: TextStyle(
                      fontFamily: AppFonts.pretendard,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.darkBg,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Action: "허용하지 않음"
              TextButton(
                onPressed: () => _completeAndNavigate(context),
                child: const Text(
                  '허용하지 않음',
                  style: TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.slateGray,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.darkCharcoal,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.white,
            size: 24,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: AppFonts.pretendard,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
