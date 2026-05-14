class WeightLog {
  const WeightLog({
    required this.weightKg,
    required this.bmi,
    required this.loggedAt,
  });

  final double weightKg;
  final double bmi;
  final DateTime loggedAt;

  factory WeightLog.fromJson(Map<String, dynamic> json) {
    double toDouble(Object? value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return WeightLog(
      weightKg: toDouble(json['weightKg'] ?? json['weight_kg']),
      bmi: toDouble(json['bmi']),
      loggedAt: DateTime.tryParse('${json['loggedAt'] ?? json['logged_at']}') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weightKg': weightKg,
      'bmi': bmi,
      'loggedAt': loggedAt.toIso8601String(),
    };
  }
}
