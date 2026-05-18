import 'dart:convert';

import '../local/local_storage_service.dart';
import '../models/weight_log.dart';
import '../models/weight_record.dart';

class WeightRepository {
  WeightRepository(this._storage);

  static const _key = 'weight_records_v1';
  static const _legacyWeightLogsKey = 'weight_logs_v1';

  final LocalStorageService _storage;

  Future<List<WeightRecord>> getAll() async {
    final records = await _readSavedRecords();
    if (records != null) {
      return records;
    }

    final migrated = await _readLegacyRecords();
    if (migrated.isNotEmpty) {
      await _saveAll(migrated);
    }
    return migrated;
  }

  Future<WeightRecord?> getLatest() async {
    final records = await getAll();
    if (records.isEmpty) {
      return null;
    }
    return records.last;
  }

  Future<void> save(WeightRecord record) async {
    final records = await getAll();
    final next = <WeightRecord>[];
    var replaced = false;

    for (final item in records) {
      if (item.id == record.id || item.dateKey == record.dateKey) {
        next.add(record.copyWith(
          id: item.id,
          createdAt: item.createdAt,
        ));
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

  Future<WeightRecord> saveToday(double weightKg, {String? memo}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    WeightRecord? existing;
    for (final record in await getAll()) {
      if (record.isSameDate(today)) {
        existing = record;
        break;
      }
    }
    final record = WeightRecord(
      id: existing?.id ?? 'weight_${today.millisecondsSinceEpoch}',
      date: today,
      weightKg: weightKg,
      memo: memo?.trim().isEmpty == true ? null : memo?.trim(),
      createdAt: existing?.createdAt ?? now,
    );
    await save(record);
    return record;
  }

  Future<void> delete(String id) async {
    final records = await getAll();
    await _saveAll(records.where((record) => record.id != id).toList());
  }

  Future<List<WeightRecord>> getRecordsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    final records = await getAll();
    return records.where((record) {
      final date = DateTime(record.date.year, record.date.month, record.date.day);
      return !date.isBefore(normalizedStart) && !date.isAfter(normalizedEnd);
    }).toList();
  }

  Future<double?> getTrend7Days() async {
    final now = DateTime.now();
    final records =
        await getRecordsBetween(now.subtract(const Duration(days: 6)), now);
    if (records.length < 2) {
      return null;
    }
    return records.last.weightKg - records.first.weightKg;
  }

  Future<List<WeightRecord>?> _readSavedRecords() async {
    try {
      final raw = _storage.getString(_key);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw) as List<dynamic>;
      return _sortAndDedupe(decoded
          .map((item) => WeightRecord.fromJson(item as Map<String, dynamic>))
          .where((record) => record.weightKg > 0)
          .toList());
    } catch (_) {
      return null;
    }
  }

  Future<List<WeightRecord>> _readLegacyRecords() async {
    try {
      final raw = _storage.getString(_legacyWeightLogsKey);
      if (raw == null || raw.isEmpty) {
        return [];
      }
      final decoded = jsonDecode(raw) as List<dynamic>;
      final records = decoded.map((item) {
        final log = WeightLog.fromJson(item as Map<String, dynamic>);
        final date = DateTime(
          log.loggedAt.year,
          log.loggedAt.month,
          log.loggedAt.day,
        );
        return WeightRecord(
          id: 'legacy_${log.loggedAt.microsecondsSinceEpoch}',
          date: date,
          weightKg: log.weightKg,
          createdAt: log.loggedAt,
        );
      }).where((record) => record.weightKg > 0);
      return _sortAndDedupe(records.toList());
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<WeightRecord> records) async {
    final next = _sortAndDedupe(records);
    await _storage.setString(
      _key,
      jsonEncode(next.map((record) => record.toJson()).toList()),
    );
  }

  List<WeightRecord> _sortAndDedupe(List<WeightRecord> records) {
    final byDate = <String, WeightRecord>{};
    for (final record in records) {
      final existing = byDate[record.dateKey];
      if (existing == null || record.createdAt.isAfter(existing.createdAt)) {
        byDate[record.dateKey] = record;
      }
    }
    final next = byDate.values.toList()
      ..sort((a, b) {
        final dateOrder = a.date.compareTo(b.date);
        if (dateOrder != 0) {
          return dateOrder;
        }
        return a.createdAt.compareTo(b.createdAt);
      });
    return next;
  }
}
