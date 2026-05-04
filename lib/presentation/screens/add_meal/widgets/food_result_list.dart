import 'package:flutter/material.dart';

import '../../../../data/models/food_item.dart';
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
      return const AppEmptyState(message: '검색 결과가 없습니다. 다른 음식명을 입력해보세요.', icon: Icons.search_off);
    }
    return Column(
      children: foods.map((food) {
        final selected = selectedFood?.id == food.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: ListTile(
              selected: selected,
              leading: CircleAvatar(
                backgroundColor: selected ? Theme.of(context).colorScheme.primary : const Color(0xFFEAF3EF),
                foregroundColor: selected ? Colors.white : Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.restaurant),
              ),
              title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${food.category} · 1인분 ${food.servingGram.round()}g'),
              trailing: Text('${food.kcalPer100g.round()}kcal/100g'),
              onTap: () => onSelected(food),
            ),
          ),
        );
      }).toList(),
    );
  }
}
