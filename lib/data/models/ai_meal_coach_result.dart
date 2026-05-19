class AiNextMealSuggestion {
  const AiNextMealSuggestion({
    required this.mealType,
    required this.title,
    required this.reason,
    required this.estimatedKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String mealType;
  final String title;
  final String reason;
  final int estimatedKcal;
  final int proteinG;
  final int carbsG;
  final int fatG;

  factory AiNextMealSuggestion.fromJson(Map<String, dynamic> json) {
    return AiNextMealSuggestion(
      mealType: _string(json['mealType'], 'dinner'),
      title: _string(json['title'], '단백질이 포함된 저녁 메뉴'),
      reason: _string(json['reason'], '부담 없이 균형을 보완하기 좋은 선택입니다.'),
      estimatedKcal: _int(json['estimatedKcal'], 520),
      proteinG: _int(json['proteinG'], 30),
      carbsG: _int(json['carbsG'], 55),
      fatG: _int(json['fatG'], 15),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      'title': title,
      'reason': reason,
      'estimatedKcal': estimatedKcal,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
    };
  }
}

class AiExerciseRecommendation {
  const AiExerciseRecommendation({
    required this.title,
    required this.reason,
    required this.durationMinutes,
    required this.intensity,
    required this.type,
    required this.caution,
    this.isFallback = false,
    this.model,
    this.createdAt,
  });

  final String title;
  final String reason;
  final int durationMinutes;
  final String intensity;
  final String type;
  final String caution;
  final bool isFallback;
  final String? model;
  final DateTime? createdAt;

  factory AiExerciseRecommendation.fromJson(Map<String, dynamic> json) {
    return AiExerciseRecommendation(
      title: _string(json['title'], '가볍게 걷기 20분'),
      reason: _string(
        json['reason'],
        '오늘 기록을 참고하면 부담 없는 활동 정도가 좋아요.',
      ),
      durationMinutes: _int(json['durationMinutes'], 20).clamp(0, 240).toInt(),
      intensity: _string(json['intensity'], 'light'),
      type: _string(json['type'], 'walk'),
      caution: _string(json['caution'], '컨디션이 좋지 않으면 쉬어도 괜찮아요.'),
      isFallback: json['isFallback'] == true,
      model: json['model'] as String?,
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
    );
  }

  factory AiExerciseRecommendation.fallback() {
    return const AiExerciseRecommendation(
      title: '가볍게 걷기 20분',
      reason: '오늘은 가볍게 움직여도 충분해요.',
      durationMinutes: 20,
      intensity: 'light',
      type: 'walk',
      caution: '컨디션이 좋지 않으면 쉬어도 괜찮아요.',
      isFallback: true,
    );
  }

  AiExerciseRecommendation copyWith({
    bool? isFallback,
    String? model,
    DateTime? createdAt,
  }) {
    return AiExerciseRecommendation(
      title: title,
      reason: reason,
      durationMinutes: durationMinutes,
      intensity: intensity,
      type: type,
      caution: caution,
      isFallback: isFallback ?? this.isFallback,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'reason': reason,
      'durationMinutes': durationMinutes,
      'intensity': intensity,
      'type': type,
      'caution': caution,
      'isFallback': isFallback,
      'model': model,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class AiTodayPlanResult {
  const AiTodayPlanResult({
    required this.title,
    required this.summary,
    required this.statusLabel,
    required this.recommendedFocus,
    required this.nextMealSuggestion,
    required this.missions,
    required this.caution,
    this.exerciseRecommendation,
    this.isFallback = false,
    this.model,
    this.createdAt,
  });

  final String title;
  final String summary;
  final String statusLabel;
  final List<String> recommendedFocus;
  final AiNextMealSuggestion nextMealSuggestion;
  final List<String> missions;
  final String caution;
  final AiExerciseRecommendation? exerciseRecommendation;
  final bool isFallback;
  final String? model;
  final DateTime? createdAt;

  factory AiTodayPlanResult.fromJson(Map<String, dynamic> json) {
    final suggestion = json['nextMealSuggestion'];
    final exerciseRecommendation = json['exerciseRecommendation'];
    return AiTodayPlanResult(
      title: _string(json['title'], '오늘은 균형을 조금 보완해보세요.'),
      summary: _string(
        json['summary'],
        '현재 기록 기준으로 무리하지 않고 단백질이 포함된 식사를 선택해보세요.',
      ),
      statusLabel: _string(json['statusLabel'], '균형 보완'),
      recommendedFocus: _stringList(json['recommendedFocus'], const ['단백질 보완']),
      nextMealSuggestion: suggestion is Map<String, dynamic>
          ? AiNextMealSuggestion.fromJson(suggestion)
          : AiNextMealSuggestion.fromJson(<String, dynamic>{}),
      missions: _stringList(json['missions'], const [
        '다음 식사에 단백질 식품 하나 포함하기',
        '오늘 기록을 가볍게 마무리하기',
      ]),
      caution: _string(json['caution'], _defaultCaution),
      exerciseRecommendation: exerciseRecommendation is Map<String, dynamic>
          ? AiExerciseRecommendation.fromJson(exerciseRecommendation)
          : null,
      isFallback: json['isFallback'] == true,
      model: json['model'] as String?,
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
    );
  }

  factory AiTodayPlanResult.fallback() {
    return const AiTodayPlanResult(
      title: 'AI 플랜을 불러오지 못했어요',
      summary: '현재 기록 기준으로 무리하지 않고 단백질이 포함된 식사를 선택해 보세요.',
      statusLabel: '기본 제안',
      recommendedFocus: ['단백질 포함', '무리 없는 선택'],
      nextMealSuggestion: AiNextMealSuggestion(
        mealType: 'dinner',
        title: '단백질이 포함된 가벼운 저녁',
        reason: '현재 기록만으로도 부담 없이 균형을 보완하기 좋은 방향입니다.',
        estimatedKcal: 520,
        proteinG: 30,
        carbsG: 55,
        fatG: 15,
      ),
      missions: ['다음 식사에 단백질 식품 하나 포함하기', '오늘 기록을 가볍게 마무리하기'],
      caution: _defaultCaution,
      isFallback: true,
      createdAt: null,
    );
  }

  AiTodayPlanResult copyWith({
    bool? isFallback,
    String? model,
    DateTime? createdAt,
    AiExerciseRecommendation? exerciseRecommendation,
  }) {
    return AiTodayPlanResult(
      title: title,
      summary: summary,
      statusLabel: statusLabel,
      recommendedFocus: recommendedFocus,
      nextMealSuggestion: nextMealSuggestion,
      missions: missions,
      caution: caution,
      exerciseRecommendation:
          exerciseRecommendation ?? this.exerciseRecommendation,
      isFallback: isFallback ?? this.isFallback,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'today_plan',
      'title': title,
      'summary': summary,
      'statusLabel': statusLabel,
      'recommendedFocus': recommendedFocus,
      'nextMealSuggestion': nextMealSuggestion.toJson(),
      'missions': missions,
      'caution': caution,
      'exerciseRecommendation': exerciseRecommendation?.toJson(),
      'isFallback': isFallback,
      'model': model,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class AiImprovementReportResult {
  const AiImprovementReportResult({
    required this.title,
    required this.score,
    required this.summary,
    required this.goodPoints,
    required this.improvementPoints,
    required this.patterns,
    required this.nextActions,
    required this.caution,
    this.isFallback = false,
    this.model,
    this.createdAt,
  });

  final String title;
  final int score;
  final String summary;
  final List<String> goodPoints;
  final List<String> improvementPoints;
  final List<String> patterns;
  final List<String> nextActions;
  final String caution;
  final bool isFallback;
  final String? model;
  final DateTime? createdAt;

  factory AiImprovementReportResult.fromJson(Map<String, dynamic> json) {
    return AiImprovementReportResult(
      title: _string(json['title'], '최근 기록을 바탕으로 식단 흐름을 점검했어요.'),
      score: _int(json['score'], 70).clamp(0, 100).toInt(),
      summary: _string(
        json['summary'],
        '최근 기록을 기준으로 식사 기록 습관과 단백질 섭취를 함께 확인해 보세요.',
      ),
      goodPoints: _stringList(json['goodPoints'], const ['식단 기록을 남기고 있어요.']),
      improvementPoints: _stringList(json['improvementPoints'], const [
        '단백질과 수분 섭취를 함께 확인해 보세요.',
      ]),
      patterns: _stringList(json['patterns'], const [
        '기록이 더 쌓이면 반복 패턴을 더 정확히 볼 수 있어요.',
      ]),
      nextActions: _stringList(json['nextActions'], const [
        '다음 식사에 단백질 식품 하나를 추가해보세요.',
        '주 2회 이상 몸무게를 기록해보세요.',
      ]),
      caution: _string(json['caution'], _defaultCaution),
      isFallback: json['isFallback'] == true,
      model: json['model'] as String?,
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
    );
  }

  factory AiImprovementReportResult.fallback() {
    return const AiImprovementReportResult(
      title: 'AI 리포트를 불러오지 못했어요',
      score: 0,
      summary: '최근 기록을 기준으로 식사 기록을 꾸준히 남기고 단백질과 수분 섭취를 함께 확인해 보세요.',
      goodPoints: ['기록을 남기는 것 자체가 좋은 출발이에요.'],
      improvementPoints: ['단백질과 수분 섭취를 함께 확인해 보세요.'],
      patterns: ['기록이 더 쌓이면 반복 패턴을 더 정확히 볼 수 있어요.'],
      nextActions: ['다음 식사에 단백질 식품 하나를 추가해보세요.', '주 2회 이상 몸무게를 기록해보세요.'],
      caution: _defaultCaution,
      isFallback: true,
    );
  }

  AiImprovementReportResult copyWith({
    bool? isFallback,
    String? model,
    DateTime? createdAt,
  }) {
    return AiImprovementReportResult(
      title: title,
      score: score,
      summary: summary,
      goodPoints: goodPoints,
      improvementPoints: improvementPoints,
      patterns: patterns,
      nextActions: nextActions,
      caution: caution,
      isFallback: isFallback ?? this.isFallback,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'improvement_report',
      'title': title,
      'score': score,
      'summary': summary,
      'goodPoints': goodPoints,
      'improvementPoints': improvementPoints,
      'patterns': patterns,
      'nextActions': nextActions,
      'caution': caution,
      'isFallback': isFallback,
      'model': model,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

const _defaultCaution = '참고용 식단 제안이에요. 컨디션에 맞춰 선택해 주세요.';

String _string(Object? value, String fallback) {
  final text = _cleanText('$value');
  if (value == null || text.isEmpty || text == 'null') {
    return fallback;
  }
  return text;
}

int _int(Object? value, int fallback) {
  if (value is num) {
    return value.round();
  }
  return int.tryParse('$value') ?? fallback;
}

List<String> _stringList(Object? value, List<String> fallback) {
  if (value is! List) {
    return fallback;
  }
  final items = value
      .map((item) => _cleanText('$item'))
      .where((item) => item.isNotEmpty && item != 'null')
      .toList();
  return items.isEmpty ? fallback : items;
}

String _cleanText(String value) {
  return value
      .replaceAll(RegExp(r'\s*[\(\[\{][^\)\]\}]{1,160}[\)\]\}]'), '')
      .replaceAll(RegExp(r'\s*（[^）]{1,160}）'), '')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .replaceAllMapped(RegExp(r'\s+([,.!?])'), (match) => match.group(1)!)
      .trim();
}
