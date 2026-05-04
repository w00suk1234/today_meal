import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/health_calculator.dart';
import '../../../core/utils/meal_timing_analyzer.dart';
import '../../widgets/app_section_title.dart';
import 'widgets/daily_summary_card.dart';
import 'widgets/macro_summary_card.dart';
import 'widgets/today_meal_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final summary = controller.todaySummary;
    final profile = controller.profile;
    final health = controller.healthProfile;
    final timingMessages = MealTimingAnalyzer.generateFeedback(records: summary.records, sleepTime: health.sleepTime);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text(AppConstants.appName, style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(AppDateUtils.koreanDate(DateTime.now()), style: AppTextStyles.muted),
          const SizedBox(height: 18),
          DailySummaryCard(summary: summary, targetKcal: profile.targetKcal),
          const SizedBox(height: 14),
          MacroSummaryCard(summary: summary),
          const AppSectionTitle('건강 지표'),
          Row(
            children: [
              Expanded(
                child: _HomeMetricCard(
                  title: 'BMI',
                  value: health.bmi <= 0 ? '미입력' : health.bmi.toStringAsFixed(1),
                  subtitle: HealthCalculator.getBmiCategory(health.bmi),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HomeMetricCard(
                  title: 'BMR / 목표',
                  value: '${health.bmr.round()} / ${health.targetKcal.round()}',
                  subtitle: 'kcal 추정',
                ),
              ),
            ],
          ),
          const AppSectionTitle('식사 기록 상태'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _MealStatus(label: '아침', done: summary.records.any((record) => record.mealType == 'breakfast')),
                  _MealStatus(label: '점심', done: summary.records.any((record) => record.mealType == 'lunch')),
                  _MealStatus(label: '저녁', done: summary.records.any((record) => record.mealType == 'dinner')),
                  _MealStatus(label: '간식', done: summary.records.any((record) => record.mealType == 'snack')),
                ],
              ),
            ),
          ),
          const AppSectionTitle('식사 시간 피드백'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(timingMessages.first),
            ),
          ),
          const AppSectionTitle('오늘 피드백'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(_feedback(summary.totalKcal, profile.targetKcal)),
            ),
          ),
          const AppSectionTitle('오늘 식단'),
          TodayMealList(records: summary.records),
          const SizedBox(height: 12),
          const Text(AppConstants.estimateNotice, style: AppTextStyles.muted),
        ],
      ),
    );
  }

  String _feedback(double total, double target) {
    if (total == 0) {
      return '아직 기록된 식단이 없습니다. 첫 식단을 추가해보세요.';
    }
    if (target <= 0) {
      return '목표 칼로리를 설정하면 오늘의 진행률을 더 정확히 볼 수 있습니다.';
    }
    final percent = total / target;
    if (percent >= 1.1) {
      return '목표보다 조금 높게 기록되었습니다. 다음 식사는 가볍게 균형을 맞춰보세요.';
    }
    if (percent <= 0.8) {
      return '목표보다 낮은 편입니다. 끼니를 놓쳤다면 영양을 보완해보세요.';
    }
    return '목표에 가깝게 잘 기록되고 있습니다.';
  }
}

class _HomeMetricCard extends StatelessWidget {
  const _HomeMetricCard({required this.title, required this.value, required this.subtitle});

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.muted),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(subtitle, style: AppTextStyles.muted),
          ],
        ),
      ),
    );
  }
}

class _MealStatus extends StatelessWidget {
  const _MealStatus({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? Theme.of(context).colorScheme.primary : Colors.grey),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
