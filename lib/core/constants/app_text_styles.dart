import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const title = TextStyle(
      fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary);
  static const pageTitle = TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimary,
      height: 1.15);
  static const section = TextStyle(
      fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static const body =
      TextStyle(fontSize: 15, height: 1.45, color: AppColors.textPrimary);
  static const muted =
      TextStyle(fontSize: 13, height: 1.35, color: AppColors.textMuted);
  static const caption =
      TextStyle(fontSize: 12, height: 1.3, color: AppColors.textMuted);
  static const metric = TextStyle(
      fontSize: 31,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimary,
      height: 1);
  static const metricSmall = TextStyle(
      fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary);
}
