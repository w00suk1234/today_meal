import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/meal_record.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/food_image_view.dart';

class TodayMealList extends StatelessWidget {
  const TodayMealList({required this.records, this.onAddMeal, super.key});

  final List<MealRecord> records;
  final VoidCallback? onAddMeal;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return AppEmptyState(
        message: '아직 기록된 식단이 없습니다. 첫 식사를 추가해보세요.',
        actionLabel: '식사 추가하기',
        onAction: onAddMeal,
      );
    }
    return Column(
      children: records.reversed.take(3).map((record) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                FoodImageView(
                    imageRef: record.imagePath, size: 58, borderRadius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.foodName,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Text(
                          '${_label(record.mealType)} · ${record.intakeGram.round()}g',
                          style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Dot(
                              color: AppColors.macroCarb,
                              label: '탄 ${record.carbs.toStringAsFixed(0)}g'),
                          const SizedBox(width: 8),
                          _Dot(
                              color: AppColors.macroProtein,
                              label: '단 ${record.protein.toStringAsFixed(0)}g'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  NutritionCalculator.kcal(record.kcal),
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _label(String type) {
    return switch (type) {
      'breakfast' => '아침',
      'lunch' => '점심',
      'dinner' => '저녁',
      _ => '간식',
    };
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
