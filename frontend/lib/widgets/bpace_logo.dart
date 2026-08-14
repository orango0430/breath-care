import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class BpaceLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final double? height;
  final Color color;
  final bool useFullImage;

  const BpaceLogo({
    super.key,
    this.iconSize = 36.0,
    this.fontSize = 26.0,
    this.height,
    this.color = AppColors.white,
    this.useFullImage = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useFullImage) {
      final logoHeight = height ?? (fontSize * 1.6);
      return Image.asset(
        'assets/images/bpace_logo_transparent.png',
        height: logoHeight,
        fit: BoxFit.contain,
        color: color == AppColors.white ? null : color,
        colorBlendMode: color == AppColors.white ? null : BlendMode.srcIn,
        errorBuilder: (context, error, stackTrace) {
          return _buildTextAndIconLogo();
        },
      );
    }
    return _buildTextAndIconLogo();
  }

  Widget _buildTextAndIconLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/bpace_icon.png',
          width: iconSize,
          height: iconSize,
          color: color == AppColors.white ? null : color,
          colorBlendMode: color == AppColors.white ? null : BlendMode.srcIn,
          errorBuilder: (context, error, stackTrace) {
            return CustomPaint(
              size: Size(iconSize, iconSize),
              painter: _BpaceMarkPainter(color: color),
            );
          },
        ),
        SizedBox(width: iconSize * 0.25),
        Text(
          'BPACE',
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            color: color,
            letterSpacing: 2.8,
          ),
        ),
      ],
    );
  }
}

class _BpaceMarkPainter extends CustomPainter {
  final Color color;

  _BpaceMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.fillType = PathFillType.evenOdd;

    // Outer boundary of Image 2 logo mark
    path.moveTo(w * 0.45, h * 0.12);
    path.cubicTo(w * 0.30, h * 0.16, w * 0.12, h * 0.37, w * 0.10, h * 0.54);
    path.cubicTo(w * 0.18, h * 0.72, w * 0.30, h * 0.84, w * 0.40, h * 0.88);
    path.cubicTo(w * 0.62, h * 0.88, w * 0.85, h * 0.72, w * 0.85, h * 0.30);
    path.cubicTo(w * 0.72, h * 0.16, w * 0.60, h * 0.12, w * 0.45, h * 0.12);

    // Inner cutout for Image 2 logo mark
    final cutout = Path();
    cutout.moveTo(w * 0.45, h * 0.16);
    cutout.cubicTo(w * 0.60, h * 0.16, w * 0.70, h * 0.23, w * 0.70, h * 0.33);
    cutout.cubicTo(w * 0.65, h * 0.40, w * 0.40, h * 0.46, w * 0.45, h * 0.56);
    cutout.cubicTo(w * 0.65, h * 0.60, w * 0.72, h * 0.70, w * 0.70, h * 0.77);
    cutout.cubicTo(w * 0.55, h * 0.86, w * 0.35, h * 0.79, w * 0.32, h * 0.58);
    cutout.cubicTo(w * 0.25, h * 0.46, w * 0.25, h * 0.30, w * 0.45, h * 0.16);

    path.addPath(cutout, Offset.zero);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BpaceMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
