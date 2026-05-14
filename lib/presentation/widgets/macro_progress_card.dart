import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'app_card.dart';

class MacroProgressCard extends StatelessWidget {
  const MacroProgressCard({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    required this.icon,
    super.key,
  });

  final String label;
  final double value;
  final double target;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final percent = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 15),
              ),
              const Spacer(),
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 4,
                  backgroundColor: AppColors.border,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 3),
          Text('${value.toStringAsFixed(0)}g',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
