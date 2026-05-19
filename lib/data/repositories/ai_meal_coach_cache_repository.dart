import 'dart:convert';

import '../local/local_storage_service.dart';
import '../models/ai_meal_coach_result.dart';

class AiMealCoachCacheRepository {
  AiMealCoachCacheRepository(this._storage);

  static const _todayPlanPrefix = 'ai_today_plan_';
  static const _improvementReportPrefix = 'ai_improvement_report_';
  static const _exerciseRecommendationPrefix = 'ai_exercise_recommendation_';

  final LocalStorageService _storage;

  Future<AiTodayPlanResult?> getTodayPlan(String dateKey) async {
    final raw = _storage.getString('$_todayPlanPrefix$dateKey');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AiTodayPlanResult.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTodayPlan(String dateKey, AiTodayPlanResult result) async {
    await _storage.setString(
      '$_todayPlanPrefix$dateKey',
      jsonEncode(result.toJson()),
    );
  }

  Future<void> clearTodayPlan(String dateKey) async {
    await _storage.setString('$_todayPlanPrefix$dateKey', '');
  }

  Future<AiExerciseRecommendation?> getExerciseRecommendation(
    String dateKey,
  ) async {
    final raw = _storage.getString('$_exerciseRecommendationPrefix$dateKey');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AiExerciseRecommendation.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveExerciseRecommendation(
    String dateKey,
    AiExerciseRecommendation result,
  ) async {
    await _storage.setString(
      '$_exerciseRecommendationPrefix$dateKey',
      jsonEncode(result.toJson()),
    );
  }

  Future<void> clearExerciseRecommendation(String dateKey) async {
    await _storage.setString('$_exerciseRecommendationPrefix$dateKey', '');
  }

  Future<AiImprovementReportResult?> getImprovementReport(
    String dateKey,
  ) async {
    final raw = _storage.getString('$_improvementReportPrefix$dateKey');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AiImprovementReportResult.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveImprovementReport(
    String dateKey,
    AiImprovementReportResult result,
  ) async {
    await _storage.setString(
      '$_improvementReportPrefix$dateKey',
      jsonEncode(result.toJson()),
    );
  }
}
