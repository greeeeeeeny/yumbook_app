import 'package:flutter/material.dart';
import 'package:yumbook_app/themes/yum_colors.dart'; // 경로가 정확한지 확인하세요.

class YumTextStyles {
  // pubspec.yaml에 등록한 family 이름과 정확히 일치해야 합니다.
  static const String fontFamily = 'Pretendard';

  // H1: Bold, 28
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold, // 700
    color: YumColors.grey900, // AppColors -> YumColors로 변경
  );

  // H2: SemiBold, 24
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600, // SemiBold
    color: YumColors.grey900,
  );

  // Title: SemiBold, 18
  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600, // SemiBold
    color: YumColors.grey900,
  );

  // Body: Regular, 16
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal, // Regular
    color: YumColors.grey800,
  );

  // Caption: Regular, 12
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal, // Regular
    color: YumColors.grey600,
  );
}