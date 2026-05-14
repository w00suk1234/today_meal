import 'package:flutter/foundation.dart';

import '../../core/utils/date_utils.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../models/food_item.dart';
import '../models/meal_record.dart';

class DemoMealSeed {
  const DemoMealSeed._();

  static List<MealRecord> buildForPortfolioCapture(List<FoodItem> foods) {
    if (!kDebugMode) {
      return const [];
    }

    final today = DateTime.now();
    final foodById = {for (final food in foods) food.id: food};
    final demos = [
      _DemoMeal(
        foodId: 'sandwich',
        displayName: '수란 아보카도 토스트',
        mealType: 'breakfast',
        intakeGram: 210,
        eatenAt: DateTime(today.year, today.month, today.day, 8, 30),
      ),
      _DemoMeal(
        foodId: 'salad',
        displayName: '구운 연어 샐러드',
        mealType: 'lunch',
        intakeGram: 260,
        eatenAt: DateTime(today.year, today.month, today.day, 12, 45),
      ),
      _DemoMeal(
        foodId: 'yogurt',
        displayName: '베리 단백질 스무디',
        mealType: 'snack',
        intakeGram: 240,
        eatenAt: DateTime(today.year, today.month, today.day, 16, 15),
      ),
    ];

    return [
      for (var i = 0; i < demos.length; i++)
        if (foodById[demos[i].foodId] != null)
          _recordFromDemo(demos[i], foodById[demos[i].foodId]!, i),
    ];
  }

  static MealRecord _recordFromDemo(_DemoMeal demo, FoodItem food, int index) {
    return MealRecord(
      id: 'debug_demo_${demo.foodId}_$index',
      foodId: food.id,
      foodName: demo.displayName,
      mealType: demo.mealType,
      intakeGram: demo.intakeGram,
      kcal: NutritionCalculator.calculateKcal(food, demo.intakeGram),
      carbs: NutritionCalculator.calculateCarbs(food, demo.intakeGram),
      protein: NutritionCalculator.calculateProtein(food, demo.intakeGram),
      fat: NutritionCalculator.calculateFat(food, demo.intakeGram),
      createdAt: demo.eatenAt,
      dateKey: AppDateUtils.dateKey(demo.eatenAt),
      eatenAt: demo.eatenAt,
      startedAt: demo.eatenAt,
      finishedAt: demo.eatenAt.add(const Duration(minutes: 18)),
    );
  }
}

class _DemoMeal {
  const _DemoMeal({
    required this.foodId,
    required this.displayName,
    required this.mealType,
    required this.intakeGram,
    required this.eatenAt,
  });

  final String foodId;
  final String displayName;
  final String mealType;
  final double intakeGram;
  final DateTime eatenAt;
}
