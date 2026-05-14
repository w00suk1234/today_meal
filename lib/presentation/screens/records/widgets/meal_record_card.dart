import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/meal_record.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/food_image_view.dart';

class MealRecordCard extends StatelessWidget {
  const MealRecordCard(
      {required this.record, required this.onDelete, super.key});

  final MealRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            FoodImageView(
                imageRef: record.imagePath, size: 68, borderRadius: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(record.foodName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900))),
                      Text(NutritionCalculator.kcal(record.kcal),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                      '${_label(record.mealType)} · ${_time(record.effectiveEatenAt)} · ${record.intakeGram.round()}g',
                      style: AppTextStyles.caption),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _MacroPill(
                          label: '탄 ${record.carbs.toStringAsFixed(0)}g',
                          color: AppColors.macroCarb),
                      const SizedBox(width: 6),
                      _MacroPill(
                          label: '단 ${record.protein.toStringAsFixed(0)}g',
                          color: AppColors.macroProtein),
                      const SizedBox(width: 6),
                      _MacroPill(
                          label: '지 ${record.fat.toStringAsFixed(0)}g',
                          color: AppColors.macroFat),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: '삭제',
              onPressed: onDelete,
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
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

  String _time(DateTime value) {
    return '${value.hour}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 11)),
        ),
      ),
    );
  }
}
