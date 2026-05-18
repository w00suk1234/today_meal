class WeightRecord {
  const WeightRecord({
    required this.id,
    required this.date,
    required this.weightKg,
    required this.createdAt,
    this.memo,
  });

  final String id;
  final DateTime date;
  final double weightKg;
  final String? memo;
  final DateTime createdAt;

  String get dateKey => _dateKey(date);

  WeightRecord copyWith({
    String? id,
    DateTime? date,
    double? weightKg,
    String? memo,
    bool clearMemo = false,
    DateTime? createdAt,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      weightKg: weightKg ?? this.weightKg,
      memo: clearMemo ? null : (memo ?? this.memo),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    double toDouble(Object? value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

    final dateRaw = json['date'] ?? json['date_key'] ?? json['loggedAt'];
    final createdAtRaw = json['createdAt'] ?? json['created_at'];
    final parsedDate = DateTime.tryParse('$dateRaw');
    final createdAt = DateTime.tryParse('$createdAtRaw') ?? DateTime.now();
    final date = parsedDate ?? createdAt;
    final memo = json['memo'] is String ? (json['memo'] as String).trim() : '';

    return WeightRecord(
      id: json['id'] as String? ?? 'weight_${_dateKey(date)}',
      date: DateTime(date.year, date.month, date.day),
      weightKg: toDouble(json['weightKg'] ?? json['weight_kg']),
      memo: memo.isEmpty ? null : memo,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': dateKey,
      'weightKg': weightKg,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool isSameDate(DateTime value) => dateKey == _dateKey(value);

  static String _dateKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
