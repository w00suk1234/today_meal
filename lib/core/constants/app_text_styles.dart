import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const title = TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static const section = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const body = TextStyle(fontSize: 15, color: AppColors.textPrimary);
  static const muted = TextStyle(fontSize: 13, color: AppColors.textMuted);
  static const metric = TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
}
