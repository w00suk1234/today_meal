import 'dart:convert';

import '../local/local_storage_service.dart';
import '../models/health_profile.dart';
import '../models/weight_log.dart';
import '../remote/supabase_client.dart';

class HealthRepository {
  HealthRepository(this._storage);

  static const _profileKey = 'health_profile_v1';
  static const _weightLogsKey = 'weight_logs_v1';
  final LocalStorageService _storage;

  Future<HealthProfile> loadProfile() async {
    final client = AppSupabase.clientOrNull;
    final userId = AppSupabase.currentUserId;
    if (client != null && userId != null) {
      try {
        final rows = await client.from('profiles').select().eq('user_id', userId).limit(1);
        if (rows.isNotEmpty) {
          return HealthProfile.fromJson(rows.first).recalculated();
        }
      } catch (_) {
        // Local fallback keeps the web demo usable when Supabase is not configured yet.
      }
    }

    try {
      final raw = _storage.getString(_profileKey);
      if (raw == null || raw.isEmpty) {
        return HealthProfile.defaultProfile().recalculated();
      }
      return HealthProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>).recalculated();
    } catch (_) {
      return HealthProfile.defaultProfile().recalculated();
    }
  }

  Future<void> saveProfile(HealthProfile profile, {double? previousWeightKg}) async {
    final recalculated = profile.recalculated();
    await _storage.setString(_profileKey, jsonEncode(recalculated.toJson()));

    if (previousWeightKg == null || (previousWeightKg - recalculated.weightKg).abs() >= 0.1) {
      await addWeightLog(WeightLog(weightKg: recalculated.weightKg, bmi: recalculated.bmi, loggedAt: DateTime.now()));
    }

    final client = AppSupabase.clientOrNull;
    final userId = AppSupabase.currentUserId;
    if (client == null || userId == null) {
      return;
    }
    try {
      await client.from('profiles').upsert(recalculated.toSupabaseJson(userId), onConflict: 'user_id');
      if (previousWeightKg == null || (previousWeightKg - recalculated.weightKg).abs() >= 0.1) {
        await client.from('weight_logs').insert({
          'user_id': userId,
          'weight_kg': recalculated.weightKg,
          'bmi': recalculated.bmi,
          'logged_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {
      // Keep local save as the source of truth for the MVP demo.
    }
  }

  Future<List<WeightLog>> loadWeightLogs() async {
    try {
      final raw = _storage.getString(_weightLogsKey);
      if (raw == null || raw.isEmpty) {
        return [];
      }
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => WeightLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addWeightLog(WeightLog log) async {
    final logs = await loadWeightLogs();
    final nextLogs = [...logs, log].take(100).toList();
    await _storage.setString(_weightLogsKey, jsonEncode(nextLogs.map((item) => item.toJson()).toList()));
  }
}

typedef ProfileRepository = HealthRepository;
