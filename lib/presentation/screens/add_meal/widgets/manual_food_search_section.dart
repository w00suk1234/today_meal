import 'package:flutter/material.dart';

import '../../../../data/models/food_item.dart';
import '../../../widgets/primary_action_button.dart';
import '../../../widgets/section_header.dart';
import 'food_result_list.dart';
import 'food_search_box.dart';
import 'meal_type_selector.dart';
import 'nutrition_summary_card.dart';
import 'portion_selector.dart';
import 'selected_food_summary_card.dart';

class ManualFoodSearchSection extends StatelessWidget {
  const ManualFoodSearchSection({
    required this.searchController,
    required this.focusNode,
    required this.foods,
    required this.selectedFood,
    required this.grams,
    required this.selectedMultiplier,
    required this.customGram,
    required this.gramController,
    required this.selectedMealType,
    required this.saving,
    required this.onQueryChanged,
    required this.onFoodSelected,
    required this.onMultiplierSelected,
    required this.onCustomSelected,
    required this.onCustomGramChanged,
    required this.onMealTypeSelected,
    required this.onSave,
    required this.nutrition,
    super.key,
  });

  final TextEditingController searchController;
  final FocusNode focusNode;
  final List<FoodItem> foods;
  final FoodItem? selectedFood;
  final double grams;
  final double selectedMultiplier;
  final bool customGram;
  final TextEditingController gramController;
  final String selectedMealType;
  final bool saving;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<FoodItem> onFoodSelected;
  final ValueChanged<double> onMultiplierSelected;
  final VoidCallback onCustomSelected;
  final VoidCallback onCustomGramChanged;
  final ValueChanged<String> onMealTypeSelected;
  final VoidCallback onSave;
  final NutritionDraft? nutrition;

  @override
  Widget build(BuildContext context) {
    final selected = selectedFood;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '직접 음식 검색'),
        FoodSearchBox(
          controller: searchController,
          focusNode: focusNode,
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 10),
        FoodResultList(
          foods: foods,
          selectedFood: selected,
          onSelected: onFoodSelected,
        ),
        if (selected != null && nutrition != null) ...[
          const SectionHeader(title: '선택한 음식'),
          SelectedFoodSummaryCard(food: selected, grams: grams),
          const SectionHeader(title: '섭취량'),
          PortionSelector(
            selectedMultiplier: selectedMultiplier,
            customGram: customGram,
            gramController: gramController,
            onMultiplierSelected: onMultiplierSelected,
            onCustomSelected: onCustomSelected,
            onCustomGramChanged: onCustomGramChanged,
          ),
          const SectionHeader(title: '식사 유형'),
          MealTypeSelector(
              selectedType: selectedMealType, onSelected: onMealTypeSelected),
          const SectionHeader(title: '영양소 요약'),
          NutritionSummaryCard(nutrition: nutrition!),
        ],
        const SizedBox(height: 16),
        PrimaryActionButton(
          label: selected == null
              ? '음식을 먼저 선택해 주세요'
              : saving
                  ? '저장 중...'
                  : '식단 저장',
          icon: selected == null ? Icons.info_outline : Icons.check,
          onPressed: selected == null || saving ? null : onSave,
        ),
      ],
    );
  }
}
