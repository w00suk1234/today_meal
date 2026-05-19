import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'app_card.dart';

enum MealStatusState { pending, recorded, skipped }

class MealStatusItem {
  const MealStatusItem({
    required this.label,
    required this.state,
    required this.icon,
    this.onTap,
  });

  final String label;
  final MealStatusState state;
  final IconData icon;
  final VoidCallback? onTap;
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
    final color = switch (item.state) {
      MealStatusState.recorded => AppColors.primary,
      MealStatusState.skipped => AppColors.orange,
      MealStatusState.pending => AppColors.textMuted,
    };
    final background = switch (item.state) {
      MealStatusState.recorded => AppColors.primarySoft,
      MealStatusState.skipped => AppColors.creamBackground,
      MealStatusState.pending => AppColors.lightGreenBackground,
    };
    final statusLabel = switch (item.state) {
      MealStatusState.recorded => '기록',
      MealStatusState.skipped => '굶음',
      MealStatusState.pending => null,
    };
    final statusIcon = switch (item.state) {
      MealStatusState.recorded => Icons.check_circle,
      MealStatusState.skipped => Icons.remove_circle_outline_rounded,
      MealStatusState.pending => item.icon,
    };

    final pill = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: color, size: 20),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (statusLabel != null) ...[
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.onTap,
        child: pill,
      ),
    );
  }
}
