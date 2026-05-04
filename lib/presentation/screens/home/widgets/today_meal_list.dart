import 'package:flutter/material.dart';

import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/meal_record.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/food_image_view.dart';

class TodayMealList extends StatelessWidget {
  const TodayMealList({required this.records, super.key});

  final List<MealRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const AppEmptyState(message: '아직 기록된 식단이 없습니다. 첫 식단을 추가해보세요.');
    }
    return Column(
      children: records.reversed.map((record) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              leading: FoodImageView(imageRef: record.imagePath),
              title: Text(record.foodName, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${_label(record.mealType)} · ${record.intakeGram.round()}g'),
              trailing: Text(NutritionCalculator.kcal(record.kcal), style: const TextStyle(fontWeight: FontWeight.w800)),
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
