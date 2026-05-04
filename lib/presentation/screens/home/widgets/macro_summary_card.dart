import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/daily_summary.dart';

class MacroSummaryCard extends StatelessWidget {
  const MacroSummaryCard({required this.summary, super.key});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            _Macro(label: '탄수화물', value: NutritionCalculator.grams(summary.totalCarbs), color: AppColors.secondary),
            _Macro(label: '단백질', value: NutritionCalculator.grams(summary.totalProtein), color: AppColors.primary),
            _Macro(label: '지방', value: NutritionCalculator.grams(summary.totalFat), color: AppColors.warning),
          ],
        ),
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 7),
          Text(label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
