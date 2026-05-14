import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/food_item.dart';
import '../../../widgets/app_card.dart';

class SelectedFoodSummaryCard extends StatelessWidget {
  const SelectedFoodSummaryCard({
    required this.food,
    required this.grams,
    super.key,
  });

  final FoodItem food;
  final double grams;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.restaurant_menu, color: AppColors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.name, style: AppTextStyles.section),
                const SizedBox(height: 5),
                Text(
                  '${food.category} · 1인분 ${food.servingGram.round()}g · 예상 ${grams.round()}g',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
