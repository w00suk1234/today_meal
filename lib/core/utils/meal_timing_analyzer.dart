import '../../data/models/meal_record.dart';

class MealTimingAnalyzer {
  const MealTimingAnalyzer._();

  static List<String> generateFeedback({
    required List<MealRecord> records,
    required String sleepTime,
    int dinnerSleepGapHours = 3,
  }) {
    if (records.isEmpty) {
      return ['오늘은 아직 식사 시간 기록이 없습니다. 규칙적인 식사 패턴을 기록해보세요.'];
    }

    final sorted = [...records]..sort((a, b) => a.effectiveStartedAt.compareTo(b.effectiveStartedAt));
    final messages = <String>[];

    for (final type in ['breakfast', 'lunch', 'dinner']) {
      if (!records.any((record) => record.mealType == type)) {
        messages.add('오늘은 ${_label(type)} 기록이 없습니다. 규칙적인 식사 패턴을 유지해보세요.');
      }
    }

    for (final record in sorted) {
      final started = record.effectiveStartedAt;
      if (!_isRecommendedTime(record.mealType, started)) {
        messages.add('${_label(record.mealType)} 식사 시간이 권장 시간대보다 벗어난 편입니다.');
      }
      final duration = record.effectiveFinishedAt.difference(record.effectiveStartedAt);
      if (duration.inMinutes < 10) {
        messages.add('${record.foodName} 식사 시간이 짧게 기록되었습니다. 다음 식사는 조금 천천히 드셔보세요.');
      }
      if (started.hour >= 21) {
        messages.add('21:00 이후 식사 기록이 있습니다. 야식은 가볍게 조절해보세요.');
      }
    }

    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i].effectiveStartedAt.difference(sorted[i - 1].effectiveFinishedAt);
      if (gap.inHours >= 6) {
        messages.add('식사 간격이 6시간 이상 벌어진 구간이 있습니다. 긴 공복이 반복되는지 확인해보세요.');
        break;
      }
    }

    final dinners = sorted.where((record) => record.mealType == 'dinner').toList();
    if (dinners.isNotEmpty) {
      final lastDinner = dinners.last;
      final sleepDateTime = _sleepDateTime(lastDinner.effectiveFinishedAt, sleepTime);
      final gap = sleepDateTime.difference(lastDinner.effectiveFinishedAt);
      if (gap.inMinutes < dinnerSleepGapHours * 60) {
        messages.add('저녁 식사와 취침 예정 시간의 간격이 짧습니다. 소화 시간을 고려해 조금 더 여유를 두는 것이 좋습니다.');
      }
    }

    if (messages.isEmpty) {
      messages.add('오늘 식사 시간 패턴은 비교적 안정적으로 기록되었습니다.');
    }
    messages.add('식사 시간 피드백은 의학적 판단이 아닌 생활 습관 참고용입니다.');
    return messages.toSet().toList();
  }

  static bool _isRecommendedTime(String mealType, DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    return switch (mealType) {
      'breakfast' => minutes >= 6 * 60 && minutes <= 10 * 60,
      'lunch' => minutes >= 11 * 60 && minutes <= 14 * 60,
      'dinner' => minutes >= 17 * 60 && minutes <= 20 * 60,
      _ => true,
    };
  }

  static DateTime _sleepDateTime(DateTime base, String sleepTime) {
    final parts = sleepTime.split(':');
    final hour = int.tryParse(parts.first) ?? 23;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '30') ?? 30;
    var sleep = DateTime(base.year, base.month, base.day, hour, minute);
    if (sleep.isBefore(base)) {
      sleep = sleep.add(const Duration(days: 1));
    }
    return sleep;
  }

  static String _label(String type) {
    return switch (type) {
      'breakfast' => '아침',
      'lunch' => '점심',
      'dinner' => '저녁',
      _ => '간식',
    };
  }
}
