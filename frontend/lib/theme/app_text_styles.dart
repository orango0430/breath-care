import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppFonts {
  static const String pretendard = 'Pretendard';
  static const String gmarketSans = 'GmarketSans';
}

/// Design system text style constants with clean fallbacks.
class AppTextStyles {
  // Korean (Pretendard / Google Font fallback)
  static TextStyle pretendardTitle = GoogleFonts.notoSansKr(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static TextStyle pretendardSubtitle = GoogleFonts.notoSansKr(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static TextStyle pretendardBody = GoogleFonts.notoSansKr(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.lightGray,
  );

  // English (GmarketSans / Google Font fallback)
  static TextStyle gmarketTitle = GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static TextStyle gmarketSubtitle = GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static TextStyle gmarketBody = GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.lightGray,
  );
}
