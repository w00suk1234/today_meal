import 'meal_record.dart';

class DailySummary {
  const DailySummary({
    required this.dateKey,
    required this.totalKcal,
    required this.totalCarbs,
    required this.totalProtein,
    required this.totalFat,
    required this.records,
  });

  final String dateKey;
  final double totalKcal;
  final double totalCarbs;
  final double totalProtein;
  final double totalFat;
  final List<MealRecord> records;
}
