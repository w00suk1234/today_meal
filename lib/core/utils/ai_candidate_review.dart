class AiCandidateReview {
  const AiCandidateReview._();

  static const Set<String> _genericNames = {
    '나물',
    '국',
    '찌개',
    '반찬',
    '생선',
    '고기',
    '샐러드',
    '볶음',
    '튀김',
    '면',
    '밥',
    '죽',
    '나물류',
    '국류',
    '찌개류',
    '반찬류',
    '생선류',
    '고기류',
    '샐러드류',
    '볶음류',
    '튀김류',
    '면류',
    '밥류',
    '죽류',
  };

  static const Map<String, List<String>> _suggestions = {
    '나물': ['시금치나물', '콩나물무침', '고사리나물', '숙주나물'],
    '국': ['미역국', '된장국', '콩나물국', '북엇국'],
    '찌개': ['된장찌개', '김치찌개', '순두부찌개', '부대찌개'],
    '반찬': ['김치', '오이무침', '멸치볶음', '콩자반'],
    '생선': ['고등어구이', '갈치구이', '연어구이', '조기구이'],
    '고기': ['불고기', '제육볶음', '닭가슴살', '돼지고기구이'],
    '샐러드': ['닭가슴살 샐러드', '연어 샐러드', '그린 샐러드', '두부 샐러드'],
    '볶음': ['제육볶음', '멸치볶음', '김치볶음', '오징어볶음'],
    '튀김': ['새우튀김', '돈가스', '치킨', '고구마튀김'],
    '면': ['라면', '국수', '냉면', '우동'],
    '밥': ['공깃밥', '현미밥', '비빔밥', '잡곡밥'],
    '죽': ['전복죽', '야채죽', '닭죽', '호박죽'],
  };

  static bool isGenericName(String name) {
    final normalized = _normalize(name);
    if (normalized.isEmpty) {
      return false;
    }
    return _genericNames.contains(normalized);
  }

  static bool isLowConfidence(String confidenceLabel) {
    return confidenceLabel.trim() == '낮음';
  }

  static bool isTooBroadOrShort(String name) {
    final normalized = _normalize(name);
    return normalized.length <= 1 || isGenericName(normalized);
  }

  static bool needsReview({
    required String name,
    required String confidenceLabel,
    required bool hasMatchedFood,
  }) {
    return isGenericName(name) ||
        isLowConfidence(confidenceLabel) ||
        isTooBroadOrShort(name) ||
        !hasMatchedFood;
  }

  static List<String> suggestionsFor(String name) {
    final normalized = _normalize(name);
    final base = normalized.endsWith('류')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
    return _suggestions[base] ?? const [];
  }

  static String reviewTitle(String name) {
    if (isGenericName(name)) {
      return '음식 종류를 조금 더 구체적으로 선택해 주세요';
    }
    return '영양 계산 전 확인 필요';
  }

  static String reviewDescription(String name) {
    final normalized = _normalize(name);
    if (normalized == '나물' || normalized == '나물류') {
      return '나물 종류를 직접 검색으로 확인해 주세요.';
    }
    if (normalized == '국' || normalized == '국류') {
      return '국 종류를 직접 검색으로 확인해 주세요.';
    }
    if (normalized == '찌개' || normalized == '찌개류') {
      return '찌개 종류를 직접 검색으로 확인해 주세요.';
    }
    if (isGenericName(name)) {
      return '정확한 기록을 위해 음식명을 직접 검색으로 확인해 주세요.';
    }
    return '정확한 기록을 위해 음식명을 확인해 주세요.';
  }

  static String _normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }
}
