import '../../data/models/daily_summary.dart';
import '../../data/models/health_profile.dart';
import '../../data/models/meal_record.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/weight_log.dart';
import 'health_calculator.dart';
import 'meal_timing_analyzer.dart';

class ReportGenerator {
  const ReportGenerator._();

  static List<String> generateDailyReport(
      DailySummary summary, UserProfile profile) {
    return generateAdvancedDailyReport(
        summary: summary, profile: profile, healthProfile: null);
  }

  static List<String> generateAdvancedDailyReport({
    required DailySummary summary,
    required UserProfile profile,
    required HealthProfile? healthProfile,
    List<WeightLog> weightLogs = const [],
  }) {
    if (summary.records.isEmpty) {
      return [
        '아직 분석할 식단 기록이 없습니다.',
        '첫 식단을 추가하면 오늘 섭취량과 탄단지 균형을 요약해드릴게요.',
        _notice,
      ];
    }

    final target = healthProfile?.targetKcal ?? profile.targetKcal;
    final messages = <String>[
      '오늘 총 섭취 칼로리는 ${summary.totalKcal.round()}kcal입니다.',
    ];

    if (target <= 0) {
      messages.add('목표 칼로리가 아직 설정되지 않았습니다. 설정 화면에서 하루 목표를 입력해보세요.');
    } else {
      final ratio = summary.totalKcal / target;
      if (ratio >= 1.1) {
        messages.add('목표 칼로리보다 높게 섭취했습니다. 다음 식사는 조금 가볍게 조절해보세요.');
      } else if (ratio <= 0.8) {
        messages.add('목표 칼로리보다 낮게 섭취했습니다. 활동량이 많았다면 균형 잡힌 식사를 보완해보세요.');
      } else {
        messages.add('목표 칼로리에 비교적 가깝게 기록되었습니다.');
      }
    }

    final macroKcal = summary.totalCarbs * 4 +
        summary.totalProtein * 4 +
        summary.totalFat * 9;
    if (macroKcal > 0) {
      final proteinRatio = summary.totalProtein * 4 / macroKcal;
      final fatRatio = summary.totalFat * 9 / macroKcal;
      if (proteinRatio < 0.16) {
        messages.add('단백질 섭취 비중이 비교적 낮습니다. 다음 식사에서 단백질 식품을 보완해보세요.');
      }
      if (fatRatio > 0.38) {
        messages.add('지방 섭취 비중이 높은 편입니다. 기름진 음식의 양을 조절해보세요.');
      }
      messages.add(
        '탄단지 기록은 탄수화물 ${summary.totalCarbs.toStringAsFixed(1)}g, 단백질 ${summary.totalProtein.toStringAsFixed(1)}g, 지방 ${summary.totalFat.toStringAsFixed(1)}g입니다.',
      );
    }

    final highestMealType = _highestMealType(summary.records);
    if (highestMealType != null) {
      messages.add('${_mealTypeLabel(highestMealType)} 식사의 칼로리 비중이 가장 높습니다.');
    }

    if (healthProfile != null) {
      messages.add(
        '현재 BMI는 ${healthProfile.bmi.toStringAsFixed(1)}로 ${HealthCalculator.getBmiCategory(healthProfile.bmi)}입니다.',
      );
      messages.add(
          '추정 기초대사량은 ${healthProfile.bmr.round()}kcal, 유지 칼로리는 ${healthProfile.tdee.round()}kcal입니다.');
      final diff = HealthCalculator.calculateWeightDiff(
          healthProfile.weightKg, healthProfile.targetWeightKg);
      if (diff != 0) {
        messages.add('목표 체중까지 ${diff.toStringAsFixed(1)}kg 차이가 있습니다.');
      }
      if (weightLogs.length >= 2) {
        final sortedLogs = [...weightLogs]
          ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
        final change = sortedLogs.last.weightKg - sortedLogs.first.weightKg;
        messages.add(
            '최근 몸무게 기록 변화는 ${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}kg입니다.');
      }
      messages.addAll(
        MealTimingAnalyzer.generateFeedback(
          records: summary.records,
          sleepTime: healthProfile.sleepTime,
        ).where((message) => !message.contains('의학적 판단')),
      );
    }

    messages.add(_notice);
    return messages;
  }

  static String? _highestMealType(List<MealRecord> records) {
    final totals = <String, double>{};
    for (final record in records) {
      totals[record.mealType] = (totals[record.mealType] ?? 0) + record.kcal;
    }
    if (totals.isEmpty) {
      return null;
    }
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static String _mealTypeLabel(String type) {
    return switch (type) {
      'breakfast' => '아침',
      'lunch' => '점심',
      'dinner' => '저녁',
      _ => '간식',
    };
  }

  static const _notice = '이 내용은 건강 진단이나 처방이 아닌 식단 기록 참고용 추정 결과입니다.';
}
