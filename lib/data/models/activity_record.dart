class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.dateKey,
    required this.type,
    required this.durationMinutes,
    required this.intensity,
    required this.createdAt,
    this.customTypeName,
    this.estimatedKcal,
    this.memo,
  });

  final String id;
  final String dateKey;
  final String type;
  final int durationMinutes;
  final String intensity;
  final String? customTypeName;
  final double? estimatedKcal;
  final String? memo;
  final DateTime createdAt;

  ActivityRecord copyWith({
    String? id,
    String? dateKey,
    String? type,
    int? durationMinutes,
    String? intensity,
    String? customTypeName,
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
      customTypeName: customTypeName ?? this.customTypeName,
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

    String cleanString(Object? value) {
      final text = value is String ? value.trim() : '';
      return text == 'null' ? '' : text;
    }

    String? cleanNullableString(Object? value) {
      final text = cleanString(value);
      return text.isEmpty ? null : text;
    }

    String normalizeType(Object? value) {
      final text = cleanString(value);
      return switch (text) {
        'walk' || 'running' || 'strength' || 'cycling' || 'etc' => text,
        _ => 'etc',
      };
    }

    String normalizeIntensity(Object? value) {
      final text = cleanString(value);
      return switch (text) {
        'light' || 'moderate' || 'hard' => text,
        _ => 'moderate',
      };
    }

    final createdAt =
        DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now();
    final dateKey = cleanString(json['dateKey']).isNotEmpty
        ? cleanString(json['dateKey'])
        : createdAt.toIso8601String().substring(0, 10);

    return ActivityRecord(
      id: cleanString(json['id']),
      dateKey: dateKey,
      type: normalizeType(json['type']),
      durationMinutes: toInt(json['durationMinutes']),
      intensity: normalizeIntensity(json['intensity']),
      customTypeName: cleanNullableString(json['customTypeName']),
      estimatedKcal: toNullableDouble(json['estimatedKcal']),
      memo: cleanNullableString(json['memo']),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateKey': dateKey,
      'type': type,
      'durationMinutes': durationMinutes,
      'intensity': intensity,
      'customTypeName': customTypeName,
      'estimatedKcal': estimatedKcal,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
