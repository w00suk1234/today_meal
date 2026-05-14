class HealthCalculator {
  const HealthCalculator._();

  static double calculateBmi(double weightKg, double heightCm) {
    if (weightKg <= 0 || heightCm <= 0) {
      return 0;
    }
    final heightMeter = heightCm / 100;
    return weightKg / (heightMeter * heightMeter);
  }

  static String getBmiCategory(double bmi) {
    if (bmi <= 0) {
      return '미입력';
    }
    if (bmi < 18.5) {
      return '저체중';
    }
    if (bmi < 23) {
      return '정상 범위';
    }
    if (bmi < 25) {
      return '과체중 전단계';
    }
    return '높은 편';
  }

  static int calculateAge(DateTime? birthDate, {DateTime? now}) {
    if (birthDate == null) {
      return 0;
    }
    final today = now ?? DateTime.now();
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  static double calculateBmrMifflinStJeor({
    required String gender,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) {
      return 0;
    }
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    if (gender == 'female') {
      return base - 161;
    }
    return base + 5;
  }

  static double getActivityFactor(String activityLevel) {
    return switch (activityLevel) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'veryActive' => 1.9,
      _ => 1.2,
    };
  }

  static double calculateTdee(double bmr, String activityLevel) {
    if (bmr <= 0) {
      return 0;
    }
    return bmr * getActivityFactor(activityLevel);
  }

  static double calculateTargetCalories(double tdee, String goalType) {
    if (tdee <= 0) {
      return 0;
    }
    final target = switch (goalType) {
      'loss' => tdee - 400,
      'gain' => tdee + 300,
      _ => tdee,
    };
    return target < 1200 ? 1200 : target;
  }

  static double calculateWeightDiff(double currentWeight, double targetWeight) {
    if (currentWeight <= 0 || targetWeight <= 0) {
      return 0;
    }
    return targetWeight - currentWeight;
  }
}
