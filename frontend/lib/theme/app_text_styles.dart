import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppFonts {
  static const String pretendard = 'Pretendard';
  static const String gmarketSans = 'GmarketSans';
}

/// Design system text style constants with clean fallbacks.
class AppTextStyles {
  // Korean (Pretendard)
  static const TextStyle pretendardTitle = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.white,
  );

  static const TextStyle pretendardSubtitle = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.white,
  );

  static const TextStyle pretendardBody = TextStyle(
    fontFamily: AppFonts.pretendard,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.lightGray,
  );

  // English (GmarketSans)
  static const TextStyle gmarketTitle = TextStyle(
    fontFamily: AppFonts.gmarketSans,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.white,
  );

  static const TextStyle gmarketSubtitle = TextStyle(
    fontFamily: AppFonts.gmarketSans,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.white,
  );

  static const TextStyle gmarketBody = TextStyle(
    fontFamily: AppFonts.gmarketSans,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.lightGray,
  );
}
