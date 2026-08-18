import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';

/// Sign Up Screen (회원가입 페이지 matching screenshot)
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onSignupPressed() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final nickname = _nameController.text.trim(); // 백엔드 API 수신 규격: nickname

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty || nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 회원가입 정보를 입력해 주세요.'),
          backgroundColor: AppColors.coralRed,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호는 최소 8자 이상이어야 합니다.'),
          backgroundColor: AppColors.coralRed,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호가 일치하지 않습니다.'),
          backgroundColor: AppColors.coralRed,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('회원가입이 성공적으로 완료되었습니다!'),
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

              // Scrollable Content Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Heading Title: Create \n Your Account
                      Text(
                        'Create\nYour Account',
                        style: GoogleFonts.outfit(
                          fontSize: 38,
                          fontWeight: FontWeight.w400,
                          color: AppColors.white,
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 3. Email Input Field (이메일 주소)
                      _buildPillInputField(
                        controller: _emailController,
                        hintText: '이메일 주소',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),

                      // 4. Password Input Field (비밀번호)
                      _buildPillInputField(
                        controller: _passwordController,
                        hintText: '비밀번호',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF8E9198),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 5. Confirm Password Input Field (비밀번호 확인)
                      _buildPillInputField(
                        controller: _confirmPasswordController,
                        hintText: '비밀번호 확인',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                          child: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF8E9198),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 6. Name Input Field (이름)
                      _buildPillInputField(
                        controller: _nameController,
                        hintText: '이름',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 32),

                      // 7. Main White Sign Up Button (회원가입)
                      GestureDetector(
                        onTap: _onSignupPressed,
                        child: Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(29),
                          ),
                          child: const Center(
                            child: Text(
                              '회원가입',
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

                      // 8. Horizontal Divider with "or"
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

                      // 9. Google Social Sign Up Pill Button (Google로 시작하기)
                      _buildSocialPillButton(
                        icon: const _GoogleGLogo(size: 20),
                        text: 'Google로 시작하기',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Google 회원가입 연동 중...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 38),

                      // 10. Bottom Login Prompt: 이미 계정이 있으신가요? 로그인하기
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: AppFonts.pretendard,
                                fontSize: 13,
                                color: Color(0xFF7A7D84),
                              ),
                              children: [
                                TextSpan(text: '이미 계정이 있으신가요? '),
                                TextSpan(
                                  text: '로그인하기',
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
    Widget? suffixIcon,
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
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 18.0),
                  child: suffixIcon,
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 48),
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
