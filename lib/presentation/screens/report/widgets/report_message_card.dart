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
        padding: const EdgeInsets.all(15),
        color: AppColors.lightGreenBackground,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  color: AppColors.cardWhite, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 11),
            Expanded(child: Text(message, style: AppTextStyles.body)),
          ],
        ),
      ),
    );
  }
}
