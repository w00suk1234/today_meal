import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/daily_summary.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({required this.summary, required this.targetKcal, super.key});

  final DailySummary summary;
  final double targetKcal;

  @override
  Widget build(BuildContext context) {
    final percent = NutritionCalculator.calculateTargetPercent(summary.totalKcal, targetKcal);
    final remaining = targetKcal - summary.totalKcal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘 총 섭취', style: AppTextStyles.muted),
            const SizedBox(height: 6),
            Text(NutritionCalculator.kcal(summary.totalKcal), style: AppTextStyles.metric),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: (percent / 100).clamp(0, 1),
                backgroundColor: AppColors.border,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Metric(label: '목표', value: NutritionCalculator.kcal(targetKcal)),
                _Metric(label: '진행률', value: '${percent.round()}%'),
                _Metric(label: remaining >= 0 ? '남은 칼로리' : '초과', value: NutritionCalculator.kcal(remaining.abs())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.muted),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
