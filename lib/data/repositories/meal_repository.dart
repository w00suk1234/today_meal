import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../local/local_storage_service.dart';
import '../models/meal_record.dart';
import '../remote/supabase_client.dart';

class MealRepository {
  MealRepository(this._storage);

  static const _key = 'meal_records_v1';
  static const _corruptBackupKey = 'meal_records_v1_corrupt_backup';
  final LocalStorageService _storage;

  Future<List<MealRecord>> loadRecords() async {
    String? raw;
    try {
      raw = _storage.getString(_key);
      if (raw == null || raw.isEmpty) {
        return [];
      }
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => MealRecord.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      debugPrint('MealRepository.loadRecords failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (raw != null && raw.isNotEmpty) {
        await _storage.setString(_corruptBackupKey, raw);
      }
      // TODO: Add a recovery UI that can restore or export the backup value.
      return [];
    }
  }

  Future<void> saveRecords(List<MealRecord> records) async {
    final encoded =
        jsonEncode(records.map((record) => record.toJson()).toList());
    final ok = await _storage.setString(_key, encoded);
    if (!ok) {
      throw Exception('식단 기록 저장에 실패했습니다.');
    }
  }

  Future<void> saveMealGroupToSupabase({
    required List<MealRecord> records,
    required bool aiDetected,
    String? aiConfidence,
    String? note,
  }) async {
    final client = AppSupabase.clientOrNull;
    final userId = AppSupabase.currentUserId;
    if (client == null || userId == null || records.isEmpty) {
      return;
    }

    try {
      final first = records.first;
      final remoteImageUrl = _remoteImageUrl(first.imagePath);
      final mealLog = await client
          .from('meal_logs')
          .insert({
            'user_id': userId,
            'meal_type': first.mealType,
            'image_url': remoteImageUrl,
            'eaten_at': first.effectiveEatenAt.toIso8601String(),
            'started_at': first.effectiveStartedAt.toIso8601String(),
            'finished_at': first.effectiveFinishedAt.toIso8601String(),
            'total_kcal':
                records.fold<double>(0, (sum, item) => sum + item.kcal),
            'total_carbs':
                records.fold<double>(0, (sum, item) => sum + item.carbs),
            'total_protein':
                records.fold<double>(0, (sum, item) => sum + item.protein),
            'total_fat': records.fold<double>(0, (sum, item) => sum + item.fat),
            'ai_detected': aiDetected,
            'ai_confidence': aiConfidence,
            'note': note,
          })
          .select('id')
          .single();
      final mealLogId = mealLog['id'] as String;
      await client.from('meal_items').insert(
            records
                .map(
                  (record) => {
                    'meal_log_id': mealLogId,
                    'food_name': record.foodName,
                    'food_id': record.foodId,
                    'intake_gram': record.intakeGram,
                    'kcal': record.kcal,
                    'carbs': record.carbs,
                    'protein': record.protein,
                    'fat': record.fat,
                    'source': aiDetected ? 'mock_ai' : 'manual',
                    'confidence': aiConfidence,
                  },
                )
                .toList(),
          );
    } catch (error, stackTrace) {
      // Supabase sync is best-effort in the MVP. Local records remain saved.
      debugPrint('MealRepository.saveMealGroupToSupabase failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      // TODO: Store syncStatus/pendingSync metadata on local meal groups so a
      // retry queue can surface failed remote sync without blocking local save.
    }
  }

  String? _remoteImageUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('data:image/')) {
      debugPrint(
          'MealRepository: skipped base64 image data for Supabase image_url. Use Supabase Storage URL instead.');
      return null;
    }
    return value;
  }
}
