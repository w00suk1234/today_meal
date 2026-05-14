import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'app_card.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.icon,
    this.color = AppColors.primary,
    super.key,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(title, style: AppTextStyles.caption)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.metricSmall),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
