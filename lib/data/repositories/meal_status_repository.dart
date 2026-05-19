import 'dart:convert';

import '../local/local_storage_service.dart';
import '../models/meal_status_record.dart';

class MealStatusRepository {
  MealStatusRepository(this._storage);

  static const _key = 'meal_status_records_v1';

  final LocalStorageService _storage;

  Future<List<MealStatusRecord>> getAll() async {
    final raw = _storage.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return _sortAndDedupe(
        decoded
            .map(
              (item) => MealStatusRecord.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<MealStatusRecord>> getByDate(String dateKey) async {
    final records = await getAll();
    return records.where((record) => record.dateKey == dateKey).toList();
  }

  Future<MealStatusRecord> markSkipped({
    required String dateKey,
    required String mealType,
    String? memo,
  }) async {
    final record = MealStatusRecord(
      id: 'meal_status_${dateKey}_$mealType',
      dateKey: dateKey,
      mealType: mealType,
      status: MealStatusRecord.skipped,
      memo: memo?.trim().isEmpty == true ? null : memo?.trim(),
      createdAt: DateTime.now(),
    );
    await save(record);
    return record;
  }

  Future<void> save(MealStatusRecord record) async {
    final records = await getAll();
    final next = <MealStatusRecord>[];
    var replaced = false;

    for (final item in records) {
      if (item.dateKey == record.dateKey && item.mealType == record.mealType) {
        next.add(record.copyWith(id: item.id));
        replaced = true;
      } else {
        next.add(item);
      }
    }

    if (!replaced) {
      next.add(record);
    }
    await _saveAll(next);
  }

  Future<void> clear({
    required String dateKey,
    required String mealType,
  }) async {
    final records = await getAll();
    await _saveAll(
      records
          .where(
            (record) =>
                record.dateKey != dateKey || record.mealType != mealType,
          )
          .toList(),
    );
  }

  Future<void> _saveAll(List<MealStatusRecord> records) async {
    await _storage.setString(
      _key,
      jsonEncode(_sortAndDedupe(records).map((item) => item.toJson()).toList()),
    );
  }

  List<MealStatusRecord> _sortAndDedupe(List<MealStatusRecord> records) {
    final byMeal = <String, MealStatusRecord>{};
    for (final record in records) {
      if (record.dateKey.isEmpty || record.mealType.isEmpty) {
        continue;
      }
      byMeal['${record.dateKey}_${record.mealType}'] = record;
    }
    final next = byMeal.values.toList()
      ..sort((a, b) {
        final dateOrder = a.dateKey.compareTo(b.dateKey);
        if (dateOrder != 0) {
          return dateOrder;
        }
        return a.mealType.compareTo(b.mealType);
      });
    return next;
  }
}
