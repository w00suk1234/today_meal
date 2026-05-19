import 'dart:convert';

import '../local/local_storage_service.dart';
import '../models/activity_record.dart';

class ActivityRepository {
  ActivityRepository(this._storage);

  static const _key = 'activity_records_v1';

  final LocalStorageService _storage;

  Future<List<ActivityRecord>> getAll() async {
    final raw = _storage.getString(_key);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return _sort(
        decoded
            .map(
                (item) => ActivityRecord.fromJson(item as Map<String, dynamic>))
            .where(
              (record) =>
                  record.id.isNotEmpty &&
                  record.dateKey.isNotEmpty &&
                  record.durationMinutes > 0,
            )
            .toList(),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<ActivityRecord>> getByDate(String dateKey) async {
    final records = await getAll();
    return records.where((record) => record.dateKey == dateKey).toList();
  }

  Future<void> add(ActivityRecord record) async {
    final records = await getAll();
    await _saveAll([...records, record]);
  }

  Future<void> delete(String id) async {
    final records = await getAll();
    await _saveAll(records.where((record) => record.id != id).toList());
  }

  Future<void> _saveAll(List<ActivityRecord> records) async {
    final ok = await _storage.setString(
      _key,
      jsonEncode(_sort(records).map((record) => record.toJson()).toList()),
    );
    if (!ok) {
      throw Exception('운동 기록 저장에 실패했습니다.');
    }
  }

  List<ActivityRecord> _sort(List<ActivityRecord> records) {
    final next = [...records];
    next.sort((a, b) {
      final dateOrder = a.dateKey.compareTo(b.dateKey);
      if (dateOrder != 0) {
        return dateOrder;
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return next;
  }
}
