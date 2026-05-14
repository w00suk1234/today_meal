class MealRecord {
  const MealRecord({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.mealType,
    required this.intakeGram,
    required this.kcal,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.createdAt,
    required this.dateKey,
    this.imagePath,
    this.eatenAt,
    this.startedAt,
    this.finishedAt,
  });

  final String id;
  final String foodId;
  final String foodName;
  final String? imagePath;
  final String mealType;
  final double intakeGram;
  final double kcal;
  final double carbs;
  final double protein;
  final double fat;
  final DateTime createdAt;
  final String dateKey;
  final DateTime? eatenAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  DateTime get effectiveEatenAt => eatenAt ?? createdAt;
  DateTime get effectiveStartedAt => startedAt ?? effectiveEatenAt;
  DateTime get effectiveFinishedAt =>
      finishedAt ?? effectiveStartedAt.add(const Duration(minutes: 15));

  factory MealRecord.fromJson(Map<String, dynamic> json) {
    double toDouble(Object? value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return MealRecord(
      id: json['id'] as String,
      foodId: json['foodId'] as String,
      foodName: json['foodName'] as String,
      imagePath: json['imagePath'] as String?,
      mealType: json['mealType'] as String,
      intakeGram: toDouble(json['intakeGram']),
      kcal: toDouble(json['kcal']),
      carbs: toDouble(json['carbs']),
      protein: toDouble(json['protein']),
      fat: toDouble(json['fat']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      dateKey: json['dateKey'] as String,
      eatenAt: _dateTimeOrNull(json['eatenAt']),
      startedAt: _dateTimeOrNull(json['startedAt']),
      finishedAt: _dateTimeOrNull(json['finishedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodId': foodId,
      'foodName': foodName,
      'imagePath': imagePath,
      'mealType': mealType,
      'intakeGram': intakeGram,
      'kcal': kcal,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'createdAt': createdAt.toIso8601String(),
      'dateKey': dateKey,
      'eatenAt': eatenAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
    };
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    if (value == null || '$value'.isEmpty) {
      return null;
    }
    return DateTime.tryParse('$value');
  }
}
