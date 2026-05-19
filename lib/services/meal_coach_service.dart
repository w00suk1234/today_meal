import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_config.dart';
import '../data/models/ai_meal_coach_result.dart';

abstract class MealCoachService {
  const MealCoachService();

  Future<AiTodayPlanResult> generateTodayPlan({
    required String date,
    required Map<String, Object?> todaySummary,
    required Map<String, Object?> recentSummary,
    required Map<String, Object?> healthContext,
  });

  Future<AiImprovementReportResult> generateImprovementReport({
    required String date,
    required Map<String, Object?> todaySummary,
    required Map<String, Object?> recentSummary,
    required Map<String, Object?> healthContext,
  });

  Future<AiExerciseRecommendation> generateExerciseRecommendation({
    required String date,
    required Map<String, Object?> todaySummary,
    required Map<String, Object?> recentSummary,
    required Map<String, Object?> healthContext,
  });
}

class MealCoachException implements Exception {
  const MealCoachException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class FallbackMealCoachService extends MealCoachService {
  const FallbackMealCoachService();

  @override
  Future<AiTodayPlanResult> generateTodayPlan({
    required String date,
    required Map<String, Object?> todaySummary,
    required Map<String, Object?> recentSummary,
    required Map<String, Object?> healthContext,
  }) async {
    return AiTodayPlanResult.fallback().copyWith(
      isFallback: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<AiImprovementReportResult> generateImprovementReport({
    required String date,
    required Map<String, Object?> todaySummary,
    required Map<String, Object?> recentSummary,
    required Map<String, Object?> healthContext,
  }) async {
    return AiImprovementReportResult.fallback().copyWith(
      isFallback: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<AiExerciseRecommendation> generateExerciseRecommendation({
    required String date,
    required Map<String, Object?> todaySummary,
    required Map<String, Object?> recentSummary,
    required Map<String, Object?> healthContext,
  }) async {
    return AiExerciseRecommendation.fallback().copyWith(
      isFallback: true,
      createdAt: DateTime.now(),
    );
  }
}

class RemoteMealCoachService extends MealCoachService {
  RemoteMealCoachService({
    this.baseUrl = AppConfig.aiApiBaseUrl,
    this.client,
    this.timeout = const Duration(seconds: 32),
    this.fallback = const FallbackMealCoachService(),
  });

  static const _clientIdKey = 'today_meal_ai_client_id_v1';

  final String baseUrl;
  final http.Client? client;
  final Duration timeout;
  final MealCoachService fallback;

  @override
  Future<AiTodayPlanResult> generateTodayPlan({
    required String date,
    required Map<String, Object?> todaySummary,
    required Map<String, Object?> recentSummary,
    required Map<String, Object?> healthContext,
  }) async {
    try {
      final decoded = await _post(
        mode: 'today_plan',
        date: date,
        todaySummary: todaySummary,
        recentSummary: recentSummary,
        healthContext: healthContext,
      );
      final result = decoded['result'];
      if (result is! Map<String, dynamic>) {
        throw const MealCoachException('AI 플랜 응답 형식이 올바르지 않습니다.');
      }
      return AiTodayPlanResult.fromJson({
        ...result,
        'model': decoded['model'],
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      debugPrint('[MEAL_COACH_FALLBACK] today_plan error=$error');
      return fallback.generateTodayPlan(
        date: date,
        todaySummary: todaySummary,
        recentSummary: recentSummary,
        healthContext: healthContext,
      );
    }
  }

  @override
  Future<AiImprovementReportResult> generateImprovementReport({
    required String date,
    required Map<String, Object?> todaySummary,
    required Map<String, Object?> recentSummary,
    required Map<String, Object?> healthContext,
  }) async {
    try {
      final decoded = await _post(
        mode: 'improvement_report',
        date: date,
        todaySummary: todaySummary,
        recentSummary: recentSummary,
        healthContext: healthContext,
      );
      final result = decoded['result'];
      if (result is! Map<String, dynamic>) {
        throw const MealCoachException('AI 리포트 응답 형식이 올바르지 않습니다.');
      }
      return AiImprovementReportResult.fromJson({
        ...result,
        'model': decoded['model'],
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      debugPrint('[MEAL_COACH_FALLBACK] improvement_report error=$error');
      return fallback.generateImprovementReport(
        date: date,
        todaySummary: todaySummary,
        recentSummary: recentSummary,
        healthContext: healthContext,
      );
    }
  }

  @override
  Future<AiExerciseRecommendation> generateExerciseRecommendation({
    required String date,
    required Map<String, Object?> todaySummary,
    required Map<String, Object?> recentSummary,
    required Map<String, Object?> healthContext,
  }) async {
    try {
      final decoded = await _post(
        mode: 'exercise_recommendation',
        date: date,
        todaySummary: todaySummary,
        recentSummary: recentSummary,
        healthContext: healthContext,
      );
      final result = decoded['result'];
      if (result is! Map<String, dynamic>) {
        throw const MealCoachException('AI 운동 추천 응답 형식이 올바르지 않습니다.');
      }
      return AiExerciseRecommendation.fromJson({
        ...result,
        'model': decoded['model'],
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      debugPrint('[MEAL_COACH_FALLBACK] exercise_recommendation error=$error');
      return fallback.generateExerciseRecommendation(
        date: date,
        todaySummary: todaySummary,
        recentSummary: recentSummary,
        healthContext: healthContext,
      );
    }
  }

  Future<Map<String, dynamic>> _post({
    required String mode,
    required String date,
    required Map<String, Object?> todaySummary,
    required Map<String, Object?> recentSummary,
    required Map<String, Object?> healthContext,
  }) async {
    final normalizedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalizedBaseUrl.isEmpty) {
      throw const MealCoachException('AI 코치 서버 URL이 설정되지 않았습니다.');
    }

    final closeClient = client == null;
    final requestClient = client ?? http.Client();
    final clientId = await _clientId();
    final uri = Uri.parse('$normalizedBaseUrl/api/meal-coach');
    debugPrint('[MEAL_COACH_REMOTE_REQUEST] mode=$mode url=$uri');

    try {
      final response = await requestClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'X-Client-Id': clientId,
            },
            body: jsonEncode({
              'mode': mode,
              'date': date,
              'todaySummary': todaySummary,
              'recentSummary': recentSummary,
              'healthContext': healthContext,
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw MealCoachException(
          'AI 코치 응답 형식이 올바르지 않습니다.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MealCoachException(
          _errorMessage(decoded) ?? 'AI 코치 요청에 실패했습니다.',
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on TimeoutException {
      throw const MealCoachException('AI 코치 요청 시간이 초과되었습니다.');
    } finally {
      if (closeClient) {
        requestClient.close();
      }
    }
  }

  Future<String> _clientId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_clientIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final next =
        'tm_${DateTime.now().microsecondsSinceEpoch}_${base64UrlEncode(bytes)}';
    await preferences.setString(_clientIdKey, next);
    return next;
  }

  String? _errorMessage(Map<String, dynamic> decoded) {
    final error = decoded['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return null;
  }
}
