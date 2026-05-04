import '../../data/models/daily_summary.dart';
import '../../data/models/food_item.dart';
import '../../data/models/meal_record.dart';

class NutritionCalculator {
  const NutritionCalculator._();

  static double calculateKcal(FoodItem foodItem, double intakeGram) {
    return foodItem.kcalPer100g * intakeGram / 100;
  }

  static double calculateCarbs(FoodItem foodItem, double intakeGram) {
    return foodItem.carbPer100g * intakeGram / 100;
  }

  static double calculateProtein(FoodItem foodItem, double intakeGram) {
    return foodItem.proteinPer100g * intakeGram / 100;
  }

  static double calculateFat(FoodItem foodItem, double intakeGram) {
    return foodItem.fatPer100g * intakeGram / 100;
  }

  static DailySummary calculateDailySummary(List<MealRecord> records, String dateKey) {
    return DailySummary(
      dateKey: dateKey,
      totalKcal: records.fold(0, (sum, item) => sum + item.kcal),
      totalCarbs: records.fold(0, (sum, item) => sum + item.carbs),
      totalProtein: records.fold(0, (sum, item) => sum + item.protein),
      totalFat: records.fold(0, (sum, item) => sum + item.fat),
      records: records,
    );
  }

  static double calculateTargetPercent(double totalKcal, double targetKcal) {
    if (targetKcal <= 0) {
      return 0;
    }
    return totalKcal / targetKcal * 100;
  }

  static String kcal(double value) => '${value.round()}kcal';

  static String grams(double value) => '${value.toStringAsFixed(1)}g';
}
