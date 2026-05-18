import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_card.dart';

class ReportMessageCard extends StatelessWidget {
  const ReportMessageCard({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        color: AppColors.lightGreenBackground,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: AppColors.cardWhite, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.primary, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(height: 1.48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
