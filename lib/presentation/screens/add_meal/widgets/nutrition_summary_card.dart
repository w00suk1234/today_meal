import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/section_header.dart';

class NutritionDraft {
  const NutritionDraft({
    required this.kcal,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  final double kcal;
  final double carbs;
  final double protein;
  final double fat;
}

class NutritionSummaryCard extends StatelessWidget {
  const NutritionSummaryCard({required this.nutrition, super.key});

  final NutritionDraft nutrition;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(nutrition.kcal.round().toString(),
                  style: AppTextStyles.metricSmall),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Text('kcal', style: AppTextStyles.caption),
              ),
              const Spacer(),
              const AppTag(label: '확인 후 계산', icon: Icons.fact_check_outlined),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MacroMini(
                  label: '탄수화물',
                  value: nutrition.carbs,
                  color: AppColors.macroCarb),
              _MacroMini(
                  label: '단백질',
                  value: nutrition.protein,
                  color: AppColors.macroProtein),
              _MacroMini(
                  label: '지방', value: nutrition.fat, color: AppColors.macroFat),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroMini extends StatelessWidget {
  const _MacroMini(
      {required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 22,
              height: 4,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 7),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text('${value.toStringAsFixed(0)}g',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
