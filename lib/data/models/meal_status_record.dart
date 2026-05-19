class MealStatusRecord {
  const MealStatusRecord({
    required this.id,
    required this.dateKey,
    required this.mealType,
    required this.status,
    required this.createdAt,
    this.memo,
  });

  static const skipped = 'skipped';

  final String id;
  final String dateKey;
  final String mealType;
  final String status;
  final String? memo;
  final DateTime createdAt;

  bool get isSkipped => status == skipped;

  MealStatusRecord copyWith({
    String? id,
    String? dateKey,
    String? mealType,
    String? status,
    String? memo,
    DateTime? createdAt,
  }) {
    return MealStatusRecord(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      mealType: mealType ?? this.mealType,
      status: status ?? this.status,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MealStatusRecord.fromJson(Map<String, dynamic> json) {
    return MealStatusRecord(
      id: json['id'] as String,
      dateKey: json['dateKey'] as String,
      mealType: json['mealType'] as String,
      status: json['status'] as String? ?? skipped,
      memo: json['memo'] as String?,
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateKey': dateKey,
      'mealType': mealType,
      'status': status,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
