import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_config.dart';
import '../core/utils/ai_candidate_review.dart';
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
  RemoteVisionFoodService({
    this.baseUrl = AppConfig.aiApiBaseUrl,
    this.client,
    this.timeout = const Duration(seconds: 25),
  });

  static const _clientIdKey = 'today_meal_ai_client_id_v1';
  static const _cacheIndexPrefix = 'today_meal_ai_analysis_cache_index_v1';
  static const _cacheEntryPrefix = 'today_meal_ai_analysis_cache_v1';
  static const _cacheVersion = 2;
  static const _localCacheTtl = Duration(hours: 24);

  final String baseUrl;
  final http.Client? client;
  final Duration timeout;
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
    final normalizedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalizedBaseUrl.isEmpty) {
      throw const VisionFoodException('AI 분석 서버 URL이 설정되지 않았습니다.');
    }
    if (forceRefresh) {
      debugPrint('[AI_FORCE_REFRESH] cacheBypassed=true');
    }

    if (!forceRefresh && imageHash != null && imageHash.isNotEmpty) {
      final cachedCandidates =
          await _readCachedCandidates(normalizedBaseUrl, imageHash);
      if (cachedCandidates != null) {
        _lastUserMessage = '같은 사진의 이전 분석 결과를 다시 표시합니다.';
        debugPrint('[AI_LOCAL_CACHE_HIT] imageHash=${_shortHash(imageHash)}');
        return cachedCandidates;
      }
    }

    final bytes = await image.readAsBytes();
    final mimeType = _mimeTypeFor(image);
    final imageBase64 = base64Encode(bytes);
    final uri = Uri.parse('$normalizedBaseUrl/api/analyze-food');
    final closeClient = client == null;
    final requestClient = client ?? http.Client();
    final clientId = await _clientId();
    debugPrint('[AI_REMOTE_REQUEST] url=$uri model is server-side');

    try {
      final response = await requestClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'X-Client-Id': clientId,
            },
            body: jsonEncode({
              'imageBase64': imageBase64,
              'mimeType': mimeType,
              if (imageHash != null && imageHash.isNotEmpty)
                'imageHash': imageHash,
              if (forceRefresh) 'forceRefresh': true,
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

      final candidates = <DetectedFoodCandidate>[];
      for (var index = 0;
          index < foods.length && candidates.length < 5;
          index++) {
        final candidate = _candidateFromJson(
          foods[index],
          candidates.length,
        );
        if (candidate != null) {
          candidates.add(candidate);
        }
      }
      if (decoded['cached'] == true) {
        _lastUserMessage = '같은 사진의 이전 분석 결과를 다시 표시합니다.';
      }
      if (imageHash != null && imageHash.isNotEmpty && candidates.isNotEmpty) {
        await _writeCachedCandidates(
          normalizedBaseUrl,
          imageHash,
          model: '${decoded['model'] ?? 'server'}',
          detail: '${decoded['detail'] ?? 'server'}',
          candidates: candidates,
        );
      } else if (imageHash != null && imageHash.isNotEmpty) {
        debugPrint('[AI_LOCAL_CACHE_SKIP] reason=empty_foods');
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
  ) {
    final item = value is Map<String, dynamic> ? value : <String, dynamic>{};
    final name = '${item['name'] ?? ''}'.trim();
    if (name.isEmpty) {
      return null;
    }
    final estimatedGram = item['estimatedGram'];
    final confidenceLabel = _confidenceLabel(item['confidence']);
    final needsReview = AiCandidateReview.isGenericName(name) ||
        AiCandidateReview.isLowConfidence(confidenceLabel) ||
        AiCandidateReview.isTooBroadOrShort(name);
    return DetectedFoodCandidate(
      id: 'remote_${DateTime.now().microsecondsSinceEpoch}_$index',
      name: name,
      confidenceLabel: AiCandidateReview.isGenericName(name) &&
              confidenceLabel == '높음'
          ? '보통'
          : confidenceLabel,
      description: '${item['description'] ?? '사진 기반 음식 후보입니다.'}',
      estimatedPortionText: '${item['estimatedPortionText'] ?? '확인 필요'}',
      selected: !needsReview,
      intakeGram: _normalizedGram(estimatedGram),
    );
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

  Future<List<DetectedFoodCandidate>?> _readCachedCandidates(
    String normalizedBaseUrl,
    String imageHash,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final indexKey = _cacheIndexKey(normalizedBaseUrl, imageHash);
      final entryKey = preferences.getString(indexKey);
      if (entryKey == null || entryKey.isEmpty) {
        return null;
      }
      final raw = preferences.getString(entryKey);
      if (raw == null || raw.isEmpty) {
        await preferences.remove(indexKey);
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _dropCachedEntry(
          preferences,
          entryKey,
          indexKey,
          reason: 'empty_foods_or_old_version',
        );
        return null;
      }
      final version = decoded['version'];
      if (version != _cacheVersion) {
        await _dropCachedEntry(
          preferences,
          entryKey,
          indexKey,
          reason: 'empty_foods_or_old_version',
        );
        return null;
      }
      if ('${decoded['imageHash'] ?? ''}' != imageHash) {
        await _dropCachedEntry(
          preferences,
          entryKey,
          indexKey,
          reason: 'image_hash_mismatch',
        );
        return null;
      }
      if ('${decoded['cacheModelKey'] ?? ''}' != _cacheModelKey ||
          '${decoded['cacheDetailKey'] ?? ''}' != _cacheDetailKey) {
        await _dropCachedEntry(
          preferences,
          entryKey,
          indexKey,
          reason: 'model_or_detail_changed',
        );
        return null;
      }
      final createdAt = DateTime.tryParse('${decoded['createdAt'] ?? ''}');
      if (createdAt == null ||
          DateTime.now().difference(createdAt) > _localCacheTtl) {
        await _dropCachedEntry(
          preferences,
          entryKey,
          indexKey,
          reason: 'expired_or_missing_created_at',
        );
        return null;
      }
      final foods = decoded['foods'];
      if (foods is! List || foods.isEmpty) {
        await _dropCachedEntry(
          preferences,
          entryKey,
          indexKey,
          reason: 'empty_foods_or_old_version',
        );
        return null;
      }
      final candidates = <DetectedFoodCandidate>[];
      for (var index = 0;
          index < foods.length && candidates.length < 5;
          index++) {
        final candidate = _candidateFromJson(foods[index], index);
        if (candidate != null) {
          candidates.add(candidate);
        }
      }
      if (candidates.isEmpty) {
        await _dropCachedEntry(
          preferences,
          entryKey,
          indexKey,
          reason: 'empty_foods_or_old_version',
        );
        return null;
      }
      return candidates;
    } catch (error) {
      debugPrint('[AI_LOCAL_CACHE_ERROR] error=$error');
      return null;
    }
  }

  Future<void> _writeCachedCandidates(
    String normalizedBaseUrl,
    String imageHash, {
    required String model,
    required String detail,
    required List<DetectedFoodCandidate> candidates,
  }) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final entryKey = _cacheEntryKey(
        normalizedBaseUrl,
        imageHash,
        model,
        detail,
      );
      final indexKey = _cacheIndexKey(normalizedBaseUrl, imageHash);
      await preferences.setString(
        entryKey,
        jsonEncode({
          'version': _cacheVersion,
          'imageHash': imageHash,
          'cacheModelKey': _cacheModelKey,
          'cacheDetailKey': _cacheDetailKey,
          'model': model,
          'detail': detail,
          'createdAt': DateTime.now().toIso8601String(),
          'foods': candidates.map(_candidateToJson).toList(),
        }),
      );
      await preferences.setString(indexKey, entryKey);
    } catch (error) {
      debugPrint('[AI_LOCAL_CACHE_WRITE_ERROR] error=$error');
    }
  }

  Future<void> _dropCachedEntry(
    SharedPreferences preferences,
    String entryKey,
    String indexKey, {
    required String reason,
  }) async {
    await preferences.remove(entryKey);
    await preferences.remove(indexKey);
    debugPrint('[AI_LOCAL_CACHE_DROP] reason=$reason');
  }

  Map<String, Object?> _candidateToJson(DetectedFoodCandidate candidate) {
    return {
      'name': candidate.name,
      'confidence': _confidenceValue(candidate.confidenceLabel),
      'description': candidate.description,
      'estimatedPortionText': candidate.estimatedPortionText,
      'estimatedGram': candidate.intakeGram,
    };
  }

  String _cacheIndexKey(String normalizedBaseUrl, String imageHash) {
    return '$_cacheIndexPrefix:${_hashText('$normalizedBaseUrl:$imageHash:${AppConfig.aiLocalCacheVariant}')}';
  }

  String _cacheEntryKey(
    String normalizedBaseUrl,
    String imageHash,
    String model,
    String detail,
  ) {
    return '$_cacheEntryPrefix:${_hashText('$normalizedBaseUrl:$imageHash:${AppConfig.aiLocalCacheVariant}:$model:$detail')}';
  }

  String _hashText(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  String get _cacheModelKey {
    final value = AppConfig.aiModelCacheKey.trim();
    return value.isEmpty ? 'server-default-model' : value;
  }

  String get _cacheDetailKey {
    final value = AppConfig.aiImageDetailCacheKey.trim();
    return value.isEmpty ? 'server-default-detail' : value;
  }

  String _shortHash(String value) =>
      value.length > 12 ? value.substring(0, 12) : value;

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

  String _confidenceValue(String label) {
    return switch (label) {
      '높음' => 'high',
      '보통' => 'medium',
      _ => 'low',
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
      final candidates = await primary.detectFoodsFromImage(
        image,
        imageHash: imageHash,
        forceRefresh: forceRefresh,
        availableFoods: availableFoods,
      );
      _lastUserMessage = primary.lastUserMessage;
      return candidates;
    } on VisionFoodException catch (error) {
      if (error.statusCode == 429) {
        rethrow;
      }
      // Portfolio/demo fallback: remote AI failures still show safe sample
      // candidates, but quota limit errors intentionally guide manual search.
      debugPrint('[AI_FALLBACK] reason=$error');
      _lastUserMessage = '원격 AI 분석에 실패해 데모 후보를 표시합니다.';
      return fallback.detectFoodsFromImage(
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
