import 'package:flutter/material.dart';

import '../../core/constants/app_text_styles.dart';

class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(title, style: AppTextStyles.section),
    );
  }
}
