import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import 'signup_screen.dart';

/// Login Screen (로그인 페이지 matching left screenshot 100%)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('아이디 (이메일)와 비밀번호를 입력해 주세요.'),
          backgroundColor: AppColors.coralRed,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('로그인이 성공적으로 완료되었습니다.'),
        backgroundColor: AppColors.lightMint,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E20), // Dark charcoal background matching design
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Back Arrow (<)
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.white,
                      size: 28,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Scrollable Body Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Big Title: Hey \n Welcome Back
                      Text(
                        'Hey\nWelcome Back',
                        style: GoogleFonts.outfit(
                          fontSize: 38,
                          fontWeight: FontWeight.w400,
                          color: AppColors.white,
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 52),

                      // 3. ID / Email Input Box
                      _buildPillInputField(
                        controller: _emailController,
                        hintText: '아이디 (이메일)',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // 4. Password Input Box
                      _buildPillInputField(
                        controller: _passwordController,
                        hintText: '비밀번호',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),

                      // 5. Underlined Link: 이메일/비밀번호 찾기 (matching left screenshot)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('비밀번호 재설정 페이지로 이동합니다.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Text(
                              '이메일/비밀번호 찾기',
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFACAEB3),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFACAEB3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 6. Main White Login Button (로그인하기)
                      GestureDetector(
                        onTap: _onLoginPressed,
                        child: Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(29),
                          ),
                          child: const Center(
                            child: Text(
                              '로그인하기',
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1E20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 7. Horizontal Divider with "or"
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFF383A3E),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.0),
                            child: Text(
                              'or',
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 13,
                                color: Color(0xFF7A7D84),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFF383A3E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 8. Google Social Login Pill Button (Google로 계속하기)
                      _buildSocialPillButton(
                        icon: const _GoogleGLogo(size: 20),
                        text: 'Google로 계속하기',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Google 로그인 연동 중...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 48),

                      // 9. Bottom Signup Prompt: 계정이 없으신가요? 회원가입하기
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 13,
                                color: Color(0xFF7A7D84),
                              ),
                              children: [
                                TextSpan(text: '계정이 없으신가요? '),
                                TextSpan(
                                  text: '회원가입하기',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pill-shaped Input Field matching screenshot
  Widget _buildPillInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2D30),
        borderRadius: BorderRadius.circular(29),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: AppFonts.pretendard,
          fontSize: 15,
          color: AppColors.white,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontFamily: AppFonts.pretendard,
            fontSize: 15,
            color: Color(0xFF7A7D84),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 22, right: 14),
            child: Icon(
              icon,
              color: const Color(0xFF8E9198),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 56),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  /// Pill-shaped Social Login Button matching screenshot
  Widget _buildSocialPillButton({
    required Widget icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2D30),
          borderRadius: BorderRadius.circular(29),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontFamily: AppFonts.pretendard,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Colorful Google 'G' Logo Widget
class _GoogleGLogo extends StatelessWidget {
  final double size;

  const _GoogleGLogo({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: _GoogleGLogoPainter(),
      ),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  const _GoogleGLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.24;
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.24;
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.24;
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.24;

    final rect = Rect.fromCircle(center: center, radius: radius * 0.76);

    // Red Arc (Top)
    canvas.drawArc(rect, -2.3, 1.8, false, redPaint);
    // Yellow Arc (Left)
    canvas.drawArc(rect, 2.4, 1.4, false, yellowPaint);
    // Green Arc (Bottom)
    canvas.drawArc(rect, 0.8, 1.6, false, greenPaint);
    // Blue Arc (Right)
    canvas.drawArc(rect, -0.5, 1.3, false, bluePaint);

    // Center blue crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(w * 0.45, h * 0.4, w * 0.5, h * 0.22);
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
