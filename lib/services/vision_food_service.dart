import 'package:image_picker/image_picker.dart';

import '../data/models/detected_food_candidate.dart';

abstract class VisionFoodService {
  Future<List<DetectedFoodCandidate>> detectFoodsFromImage(XFile image);
}

class MockVisionFoodService implements VisionFoodService {
  const MockVisionFoodService();

  @override
  Future<List<DetectedFoodCandidate>> detectFoodsFromImage(XFile image) async {
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

class RemoteVisionFoodService implements VisionFoodService {
  const RemoteVisionFoodService();

  @override
  Future<List<DetectedFoodCandidate>> detectFoodsFromImage(XFile image) async {
    // Future extension only. Do not put OpenAI/Gemini API keys in Flutter Web or mobile client code.
    //
    // Recommended production path:
    // Flutter App
    // -> Vercel API Route or Supabase Edge Function
    // -> OpenAI/Gemini VLM API
    // -> JSON response
    // -> Flutter App display
    //
    // Expected JSON shape:
    // {
    //   "foods": [
    //     {
    //       "name": "고등어구이",
    //       "confidence": "high",
    //       "description": "구운 생선으로 보입니다.",
    //       "estimatedPortionText": "약 1인분",
    //       "matchedKeyword": "고등어"
    //     }
    //   ],
    //   "warning": "사진 기반 분석은 참고용이며 실제 섭취량 확인이 필요합니다."
    // }
    //
    // Cost-control rules for a real implementation:
    // - call only after explicit button tap
    // - analyze one resized image at a time
    // - enforce a daily request limit
    // - keep API keys server-side only
    // - request strict JSON output
    return [];
  }
}
