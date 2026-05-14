import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_config.dart';
import '../data/models/detected_food_candidate.dart';
import '../data/models/food_item.dart';

abstract class VisionFoodService {
  const VisionFoodService();

  String? get lastUserMessage => null;

  Future<List<DetectedFoodCandidate>> detectFoodsFromImage(
    XFile image, {
    String? imageHash,
    bool forceRefresh = false,
    List<FoodItem> availableFoods = const [],
  });
}

class VisionFoodException implements Exception {
  const VisionFoodException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class MockVisionFoodService extends VisionFoodService {
  const MockVisionFoodService();

  @override
  Future<List<DetectedFoodCandidate>> detectFoodsFromImage(
    XFile image, {
    String? imageHash,
    bool forceRefresh = false,
    List<FoodItem> availableFoods = const [],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    return const [
      DetectedFoodCandidate(
        id: 'mock_mackerel',
        name: '고등어구이',
        confidenceLabel: '높음',
        description: '구운 생선으로 보입니다.',
        estimatedPortionText: '약 1인분',
        matchedFoodItemId: 'grilled_mackerel',
        selected: true,
        intakeGram: 180,
      ),
      DetectedFoodCandidate(
        id: 'mock_mixed_rice',
        name: '잡곡밥',
        confidenceLabel: '높음',
        description: '밥류로 보입니다.',
        estimatedPortionText: '약 1공기',
        matchedFoodItemId: 'brown_rice',
        selected: true,
        intakeGram: 210,
      ),
      DetectedFoodCandidate(
        id: 'mock_doenjang_soup',
        name: '된장국',
        confidenceLabel: '보통',
        description: '된장 베이스의 국 또는 찌개로 보입니다.',
        estimatedPortionText: '약 1그릇',
        matchedFoodItemId: 'doenjang_stew',
        selected: true,
        intakeGram: 250,
      ),
      DetectedFoodCandidate(
        id: 'mock_cucumber',
        name: '오이무침',
        confidenceLabel: '보통',
        description: '오이 반찬으로 추정됩니다.',
        estimatedPortionText: '약 0.5인분',
        matchedFoodItemId: 'cucumber_salad',
        selected: true,
        intakeGram: 60,
      ),
      DetectedFoodCandidate(
        id: 'mock_kimchi',
        name: '김치',
        confidenceLabel: '낮음',
        description: '김치류 반찬일 가능성이 있습니다.',
        estimatedPortionText: '약 0.3인분',
        matchedFoodItemId: 'kimchi',
        selected: true,
        intakeGram: 40,
      ),
    ];
  }
}

class RemoteVisionFoodService extends VisionFoodService {
  const RemoteVisionFoodService({
    this.baseUrl = AppConfig.aiApiBaseUrl,
    this.client,
    this.timeout = const Duration(seconds: 25),
  });

  final String baseUrl;
  final http.Client? client;
  final Duration timeout;

  @override
  Future<List<DetectedFoodCandidate>> detectFoodsFromImage(
    XFile image, {
    String? imageHash,
    bool forceRefresh = false,
    List<FoodItem> availableFoods = const [],
  }) async {
    final normalizedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalizedBaseUrl.isEmpty) {
      throw const VisionFoodException('AI 분석 서버 URL이 설정되지 않았습니다.');
    }

    final bytes = await image.readAsBytes();
    final mimeType = _mimeTypeFor(image);
    final imageBase64 = base64Encode(bytes);
    final uri = Uri.parse('$normalizedBaseUrl/api/analyze-food');
    final closeClient = client == null;
    final requestClient = client ?? http.Client();
    debugPrint('[AI_REMOTE_REQUEST] url=$uri model is server-side');

    try {
      final response = await requestClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'imageBase64': imageBase64,
              'mimeType': mimeType,
              if (imageHash != null && imageHash.isNotEmpty)
                'imageHash': imageHash,
              if (forceRefresh) 'forceRefresh': true,
              // Keep the prompt compact: send only id/name/category and cap
              // the list. TODO: rank foods by recent usage/search context.
              'availableFoods': availableFoods
                  .take(200)
                  .map((food) => {
                        'id': food.id,
                        'name': food.name,
                        'category': food.category,
                      })
                  .toList(),
            }),
          )
          .timeout(timeout);

      final Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw VisionFoodException(
          'AI 분석 응답 형식이 올바르지 않습니다.',
          statusCode: response.statusCode,
        );
      }

      final responseFoods = decoded['foods'];
      debugPrint(
        '[AI_REMOTE_RESPONSE] status=${response.statusCode} '
        'foods=${responseFoods is List ? responseFoods.length : 0} '
        'cached=${decoded['cached'] == true}',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _errorMessage(decoded) ?? 'AI 분석 서버 요청에 실패했습니다.';
        throw VisionFoodException(
          message,
          statusCode: response.statusCode,
        );
      }

      final foods = decoded['foods'];
      if (foods is! List) {
        throw const VisionFoodException('AI 분석 응답 형식이 올바르지 않습니다.');
      }

      final allowedFoodIds = availableFoods.map((food) => food.id).toSet();
      final candidates = <DetectedFoodCandidate>[];
      for (var index = 0;
          index < foods.length && candidates.length < 5;
          index++) {
        final candidate = _candidateFromJson(
          foods[index],
          candidates.length,
          allowedFoodIds,
        );
        if (candidate != null) {
          candidates.add(candidate);
        }
      }
      return candidates;
    } on TimeoutException {
      throw const VisionFoodException('AI 분석 요청 시간이 초과되었습니다.');
    } on VisionFoodException {
      rethrow;
    } catch (_) {
      throw const VisionFoodException('AI 분석 결과를 불러오지 못했습니다.');
    } finally {
      if (closeClient) {
        requestClient.close();
      }
    }
  }

  DetectedFoodCandidate? _candidateFromJson(
    Object? value,
    int index,
    Set<String> allowedFoodIds,
  ) {
    final item = value is Map<String, dynamic> ? value : <String, dynamic>{};
    final name = '${item['name'] ?? ''}'.trim();
    if (name.isEmpty) {
      return null;
    }
    final estimatedGram = item['estimatedGram'];
    final matchedFoodItemId = item['matchedFoodItemId'];
    final normalizedMatchedFoodItemId = matchedFoodItemId is String &&
            allowedFoodIds.contains(matchedFoodItemId)
        ? matchedFoodItemId
        : null;
    return DetectedFoodCandidate(
      id: 'remote_${DateTime.now().microsecondsSinceEpoch}_$index',
      name: name,
      confidenceLabel: _confidenceLabel(item['confidence']),
      description: '${item['description'] ?? '사진 기반 음식 후보입니다.'}',
      estimatedPortionText: '${item['estimatedPortionText'] ?? '확인 필요'}',
      matchedFoodItemId: normalizedMatchedFoodItemId,
      selected: true,
      intakeGram: _normalizedGram(estimatedGram),
    );
  }

  String _mimeTypeFor(XFile image) {
    final explicit = image.mimeType;
    if (explicit != null && explicit.startsWith('image/')) {
      return explicit;
    }
    final path = image.path.toLowerCase();
    if (path.endsWith('.png')) {
      return 'image/png';
    }
    if (path.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _confidenceLabel(Object? value) {
    return switch (value) {
      'high' => '높음',
      'medium' => '보통',
      'low' => '낮음',
      '높음' => '높음',
      '보통' => '보통',
      '낮음' => '낮음',
      _ => '낮음',
    };
  }

  double _normalizedGram(Object? value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    if (parsed == null || parsed < 20 || parsed > 2000) {
      return 100;
    }
    return parsed;
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

class FallbackVisionFoodService extends VisionFoodService {
  FallbackVisionFoodService({
    required this.primary,
    this.fallback = const MockVisionFoodService(),
  });

  final VisionFoodService primary;
  final VisionFoodService fallback;
  String? _lastUserMessage;

  @override
  String? get lastUserMessage => _lastUserMessage;

  @override
  Future<List<DetectedFoodCandidate>> detectFoodsFromImage(
    XFile image, {
    String? imageHash,
    bool forceRefresh = false,
    List<FoodItem> availableFoods = const [],
  }) async {
    _lastUserMessage = null;
    try {
      return await primary.detectFoodsFromImage(
        image,
        imageHash: imageHash,
        forceRefresh: forceRefresh,
        availableFoods: availableFoods,
      );
    } catch (error) {
      debugPrint('[AI_FALLBACK] reason=$error');
      _lastUserMessage = '원격 AI 분석에 실패해 데모 후보를 표시합니다.';
      return fallback.detectFoodsFromImage(
        image,
        imageHash: imageHash,
        forceRefresh: forceRefresh,
        availableFoods: availableFoods,
      );
    }
  }
}
