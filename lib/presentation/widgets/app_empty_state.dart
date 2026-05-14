import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'app_card.dart';
import 'primary_action_button.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.message,
    this.icon = Icons.restaurant_menu,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
                color: AppColors.lightGreenBackground, shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center, style: AppTextStyles.muted),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            PrimaryActionButton(
              label: actionLabel!,
              icon: Icons.add_circle_outline,
              compact: true,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
