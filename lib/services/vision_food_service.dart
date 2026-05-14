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
    List<FoodItem> availableFoods = const [],
  });
}

class VisionFoodException implements Exception {
  const VisionFoodException(
    this.message, {
    this.statusCode,
    this.code,
    this.canFallback = true,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final bool canFallback;

  @override
  String toString() => message;
}

class MockVisionFoodService extends VisionFoodService {
  const MockVisionFoodService();

  @override
  Future<List<DetectedFoodCandidate>> detectFoodsFromImage(
    XFile image, {
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
    debugPrint(
      '[AI_REMOTE_REQUEST] url=$uri '
      'imageBase64Length=${imageBase64.length} mime=$mimeType '
      'foods=${availableFoods.length}',
    );

    try {
      final response = await requestClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'imageBase64': imageBase64,
              'mimeType': mimeType,
              'availableFoods': availableFoods
                  .map((food) => {
                        'id': food.id,
                        'name': food.name,
                        'category': food.category,
                      })
                  .toList(),
            }),
          )
          .timeout(timeout);

      debugPrint(
        '[AI_REMOTE_RESPONSE] status=${response.statusCode} '
        'bodyPreview=${_preview(response.body)}',
      );

      final Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (error, stackTrace) {
        debugPrint('[AI_REMOTE_PARSE_FAIL] error=$error');
        debugPrintStack(stackTrace: stackTrace);
        throw VisionFoodException(
          'AI 분석 응답 형식이 올바르지 않습니다.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _errorMessage(decoded) ?? 'AI 분석 서버 요청에 실패했습니다.';
        throw VisionFoodException(
          message,
          statusCode: response.statusCode,
          code: _errorCode(decoded),
          canFallback: _canFallbackForStatus(response.statusCode),
        );
      }

      final foods = decoded['foods'];
      if (foods is! List) {
        debugPrint('[AI_REMOTE_PARSE_FAIL] error=foods field is not a list');
        throw const VisionFoodException('AI 분석 응답 형식이 올바르지 않습니다.');
      }
      debugPrint('[AI_REMOTE_PARSE_OK] foods=${foods.length}');

      return [
        for (var index = 0; index < foods.length && index < 5; index++)
          _candidateFromJson(foods[index], index),
      ];
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('[AI_REMOTE_ERROR] error=$error');
      debugPrintStack(stackTrace: stackTrace);
      throw const VisionFoodException('AI 분석 요청 시간이 초과되었습니다.');
    } on VisionFoodException catch (error, stackTrace) {
      debugPrint(
        '[AI_REMOTE_ERROR] error=$error '
        'status=${error.statusCode} code=${error.code}',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('[AI_REMOTE_ERROR] error=$error');
      debugPrintStack(stackTrace: stackTrace);
      throw const VisionFoodException('AI 분석 결과를 불러오지 못했습니다.');
    } finally {
      if (closeClient) {
        requestClient.close();
      }
    }
  }

  DetectedFoodCandidate _candidateFromJson(Object? value, int index) {
    final item = value is Map<String, dynamic> ? value : <String, dynamic>{};
    final name = '${item['name'] ?? '음식 후보 ${index + 1}'}'.trim();
    final estimatedGram = item['estimatedGram'];
    final matchedFoodItemId = item['matchedFoodItemId'];
    return DetectedFoodCandidate(
      id: 'remote_${DateTime.now().microsecondsSinceEpoch}_$index',
      name: name.isEmpty ? '음식 후보 ${index + 1}' : name,
      confidenceLabel: _confidenceLabel(item['confidence']),
      description: '${item['description'] ?? '사진 기반 음식 후보입니다.'}',
      estimatedPortionText: '${item['estimatedPortionText'] ?? '확인 필요'}',
      matchedFoodItemId:
          matchedFoodItemId is String && matchedFoodItemId.trim().isNotEmpty
              ? matchedFoodItemId
              : null,
      selected: true,
      intakeGram: _toPositiveDouble(estimatedGram) ?? 100,
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

  double? _toPositiveDouble(Object? value) {
    final parsed = value is num ? value.toDouble() : double.tryParse('$value');
    if (parsed == null || parsed <= 0) {
      return null;
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

  String? _errorCode(Map<String, dynamic> decoded) {
    final error = decoded['error'];
    if (error is Map<String, dynamic>) {
      final code = error['code'];
      if (code is String && code.trim().isNotEmpty) {
        return code;
      }
    }
    return null;
  }

  bool _canFallbackForStatus(int statusCode) {
    return statusCode != 400 && statusCode != 413 && statusCode != 415;
  }

  String _preview(String body) {
    final compact = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 500) {
      return compact;
    }
    return '${compact.substring(0, 500)}...';
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
    List<FoodItem> availableFoods = const [],
  }) async {
    _lastUserMessage = null;
    try {
      return await primary.detectFoodsFromImage(
        image,
        availableFoods: availableFoods,
      );
    } on VisionFoodException catch (error, stackTrace) {
      if (!error.canFallback) {
        debugPrint(
          '[AI_FALLBACK] skipped status=${error.statusCode} code=${error.code}',
        );
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }
      // Portfolio/demo mode keeps a mock fallback so the UI can be shown even
      // when AI_API_BASE_URL or the remote provider is temporarily unavailable.
      // Production can remove this wrapper to surface VisionFoodException.
      debugPrint(
        '[AI_FALLBACK] using MockVisionFoodService after remote failure '
        'error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      _lastUserMessage = '원격 AI 분석에 실패해 데모 후보를 표시합니다.';
      return fallback.detectFoodsFromImage(
        image,
        availableFoods: availableFoods,
      );
    } catch (error, stackTrace) {
      // Portfolio/demo mode keeps a mock fallback so the UI can be shown even
      // when AI_API_BASE_URL or the remote provider is temporarily unavailable.
      // Production can remove this wrapper to surface VisionFoodException.
      debugPrint(
        '[AI_FALLBACK] using MockVisionFoodService after remote failure '
        'error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      _lastUserMessage = '원격 AI 분석에 실패해 데모 후보를 표시합니다.';
      return fallback.detectFoodsFromImage(
        image,
        availableFoods: availableFoods,
      );
    }
  }
}
