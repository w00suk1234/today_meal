import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'app_card.dart';

class MealStatusItem {
  const MealStatusItem({
    required this.label,
    required this.done,
    required this.icon,
  });

  final String label;
  final bool done;
  final IconData icon;
}

class MealStatusCard extends StatelessWidget {
  const MealStatusCard({required this.items, super.key});

  final List<MealStatusItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _MealStatusPill(item: items[i])),
            if (i != items.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _MealStatusPill extends StatelessWidget {
  const _MealStatusPill({required this.item});

  final MealStatusItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.done ? AppColors.primary : AppColors.textMuted;
    final background =
        item.done ? AppColors.primarySoft : AppColors.lightGreenBackground;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: item.done
                ? AppColors.primary.withValues(alpha: 0.18)
                : AppColors.border),
      ),
      child: Column(
        children: [
          Icon(item.done ? Icons.check_circle : item.icon,
              color: color, size: 20),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(item.label,
                style: AppTextStyles.caption
                    .copyWith(color: color, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
