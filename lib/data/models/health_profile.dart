import '../../core/constants/app_constants.dart';
import '../../core/utils/health_calculator.dart';

class HealthProfile {
  const HealthProfile({
    required this.nickname,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.targetWeightKg,
    required this.activityLevel,
    required this.goalType,
    required this.sleepTime,
    required this.targetKcal,
    required this.bmr,
    required this.tdee,
    required this.bmi,
    this.birthDate,
  });

  final String nickname;
  final String gender;
  final DateTime? birthDate;
  final double heightCm;
  final double weightKg;
  final double targetWeightKg;
  final String activityLevel;
  final String goalType;
  final String sleepTime;
  final double targetKcal;
  final double bmr;
  final double tdee;
  final double bmi;

  factory HealthProfile.defaultProfile() {
    return const HealthProfile(
      nickname: '',
      gender: 'male',
      heightCm: 170,
      weightKg: 70,
      targetWeightKg: 68,
      activityLevel: 'light',
      goalType: 'maintain',
      sleepTime: '23:30',
      targetKcal: AppConstants.defaultTargetKcal,
      bmr: 0,
      tdee: 0,
      bmi: 0,
    );
  }

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    double toDouble(Object? value, double fallback) {
      return value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
    }

    final birthDateRaw = json['birthDate'] ?? json['birth_date'];
    final activityLevel = (json['activityLevel'] as String?) ?? (json['activity_level'] as String?) ?? 'light';
    final goalType = (json['goalType'] as String?) ?? (json['goal_type'] as String?) ?? 'maintain';
    final sleepTime = (json['sleepTime'] as String?) ?? (json['sleep_time'] as String?) ?? '23:30';

    return HealthProfile(
      nickname: json['nickname'] as String? ?? '',
      gender: json['gender'] as String? ?? 'male',
      birthDate: birthDateRaw == null || '$birthDateRaw'.isEmpty ? null : DateTime.tryParse('$birthDateRaw'),
      heightCm: toDouble(json['heightCm'] ?? json['height_cm'], 170),
      weightKg: toDouble(json['weightKg'] ?? json['weight_kg'], 70),
      targetWeightKg: toDouble(json['targetWeightKg'] ?? json['target_weight_kg'], 68),
      activityLevel: activityLevel,
      goalType: goalType,
      sleepTime: sleepTime,
      targetKcal: toDouble(json['targetKcal'] ?? json['target_kcal'], AppConstants.defaultTargetKcal),
      bmr: toDouble(json['bmr'], 0),
      tdee: toDouble(json['tdee'], 0),
      bmi: toDouble(json['bmi'], 0),
    );
  }

  HealthProfile recalculated() {
    final age = HealthCalculator.calculateAge(birthDate);
    final nextBmi = HealthCalculator.calculateBmi(weightKg, heightCm);
    final nextBmr = HealthCalculator.calculateBmrMifflinStJeor(
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
    );
    final nextTdee = HealthCalculator.calculateTdee(nextBmr, activityLevel);
    final nextTarget = HealthCalculator.calculateTargetCalories(nextTdee, goalType);
    return copyWith(
      bmi: nextBmi,
      bmr: nextBmr,
      tdee: nextTdee,
      targetKcal: nextTarget > 0 ? nextTarget : targetKcal,
    );
  }

  HealthProfile copyWith({
    String? nickname,
    String? gender,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    String? activityLevel,
    String? goalType,
    String? sleepTime,
    double? targetKcal,
    double? bmr,
    double? tdee,
    double? bmi,
  }) {
    return HealthProfile(
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goalType: goalType ?? this.goalType,
      sleepTime: sleepTime ?? this.sleepTime,
      targetKcal: targetKcal ?? this.targetKcal,
      bmr: bmr ?? this.bmr,
      tdee: tdee ?? this.tdee,
      bmi: bmi ?? this.bmi,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'heightCm': heightCm,
      'weightKg': weightKg,
      'targetWeightKg': targetWeightKg,
      'activityLevel': activityLevel,
      'goalType': goalType,
      'sleepTime': sleepTime,
      'targetKcal': targetKcal,
      'bmr': bmr,
      'tdee': tdee,
      'bmi': bmi,
    };
  }

  Map<String, dynamic> toSupabaseJson(String userId) {
    return {
      'user_id': userId,
      'nickname': nickname,
      'gender': gender,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'target_weight_kg': targetWeightKg,
      'activity_level': activityLevel,
      'goal_type': goalType,
      'sleep_time': sleepTime,
      'target_kcal': targetKcal,
      'bmr': bmr,
      'tdee': tdee,
      'bmi': bmi,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
