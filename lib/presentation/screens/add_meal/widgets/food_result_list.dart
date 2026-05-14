import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/food_item.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_empty_state.dart';

class FoodResultList extends StatelessWidget {
  const FoodResultList({
    required this.foods,
    required this.selectedFood,
    required this.onSelected,
    super.key,
  });

  final List<FoodItem> foods;
  final FoodItem? selectedFood;
  final ValueChanged<FoodItem> onSelected;

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) {
      return const AppEmptyState(
          message: '검색 결과가 없습니다. 다른 음식명을 입력해보세요.', icon: Icons.search_off);
    }
    return Column(
      children: foods.map((food) {
        final selected = selectedFood?.id == food.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            onTap: () => onSelected(food),
            padding: const EdgeInsets.all(12),
            borderColor: selected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
            color: selected ? AppColors.primarySoft : AppColors.cardWhite,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: selected
                      ? AppColors.primary
                      : AppColors.lightGreenBackground,
                  foregroundColor: selected ? Colors.white : AppColors.primary,
                  child: const Icon(Icons.restaurant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(food.name,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(
                          '${food.category} · 1인분 ${food.servingGram.round()}g',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Text('${food.kcalPer100g.round()}kcal',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
