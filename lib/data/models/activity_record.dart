class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.dateKey,
    required this.type,
    required this.durationMinutes,
    required this.intensity,
    required this.createdAt,
    this.estimatedKcal,
    this.memo,
  });

  final String id;
  final String dateKey;
  final String type;
  final int durationMinutes;
  final String intensity;
  final double? estimatedKcal;
  final String? memo;
  final DateTime createdAt;

  ActivityRecord copyWith({
    String? id,
    String? dateKey,
    String? type,
    int? durationMinutes,
    String? intensity,
    double? estimatedKcal,
    String? memo,
    DateTime? createdAt,
  }) {
    return ActivityRecord(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intensity: intensity ?? this.intensity,
      estimatedKcal: estimatedKcal ?? this.estimatedKcal,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    int toInt(Object? value) {
      if (value is num) {
        return value.round();
      }
      return int.tryParse('$value') ?? 0;
    }

    double? toNullableDouble(Object? value) {
      if (value == null || '$value'.isEmpty) {
        return null;
      }
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse('$value');
    }

    return ActivityRecord(
      id: json['id'] as String? ?? '',
      dateKey: json['dateKey'] as String? ?? '',
      type: json['type'] as String? ?? 'etc',
      durationMinutes: toInt(json['durationMinutes']),
      intensity: json['intensity'] as String? ?? 'moderate',
      estimatedKcal: toNullableDouble(json['estimatedKcal']),
      memo: json['memo'] as String?,
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateKey': dateKey,
      'type': type,
      'durationMinutes': durationMinutes,
      'intensity': intensity,
      'estimatedKcal': estimatedKcal,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
