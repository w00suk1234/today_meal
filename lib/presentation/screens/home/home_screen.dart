import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/health_calculator.dart';
import '../../../core/utils/meal_timing_analyzer.dart';
import '../../../data/models/meal_record.dart';
import '../../widgets/ai_suggestion_card.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/meal_status_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/section_header.dart';
import 'widgets/daily_summary_card.dart';
import 'widgets/macro_summary_card.dart';
import 'widgets/today_meal_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onAnalyzeFood,
    this.scrollController,
    super.key,
  });

  final VoidCallback onAnalyzeFood;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final summary = controller.todaySummary;
    final profile = controller.profile;
    final health = controller.healthProfile;
    final timingMessages = MealTimingAnalyzer.generateFeedback(
        records: summary.records, sleepTime: health.sleepTime);
    final timingMessage = summary.records.isEmpty
        ? '오늘은 아직 식사 기록이 없습니다. 규칙적인 식사 패턴을 기록해보세요.'
        : timingMessages.first;
    final nickname = health.nickname.trim().isEmpty
        ? profile.nickname.trim()
        : health.nickname.trim();

    return AppScaffold(
      controller: scrollController,
      children: [
        AppPageHeader(
          title: AppConstants.appName,
          subtitle:
              '${AppDateUtils.koreanDate(DateTime.now())}\n${_greeting(nickname)}',
          icon: Icons.auto_awesome,
          trailing: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.primary, size: 18),
          ),
        ),
        DailySummaryCard(summary: summary, targetKcal: profile.targetKcal),
        const SectionHeader(
            title: '영양 밸런스', subtitle: '오늘 기록된 탄단지 비율을 한눈에 확인해요'),
        MacroSummaryCard(summary: summary, targetKcal: profile.targetKcal),
        const SizedBox(height: 4),
        const SectionHeader(title: '건강 지표'),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'BMI',
                value: health.bmi <= 0 ? '미입력' : health.bmi.toStringAsFixed(1),
                subtitle: HealthCalculator.getBmiCategory(health.bmi),
                icon: Icons.monitor_heart_outlined,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: 'BMR / 목표',
                value: '${health.bmr.round()} / ${health.targetKcal.round()}',
                subtitle: 'kcal 추정',
                icon: Icons.local_fire_department_outlined,
                color: AppColors.orange,
              ),
            ),
          ],
        ),
        const SectionHeader(title: '식사 기록 상태'),
        MealStatusCard(
          items: [
            MealStatusItem(
                label: '아침',
                done: _hasMeal(summary.records, 'breakfast'),
                icon: Icons.wb_sunny_outlined),
            MealStatusItem(
                label: '점심',
                done: _hasMeal(summary.records, 'lunch'),
                icon: Icons.restaurant_rounded),
            MealStatusItem(
                label: '저녁',
                done: _hasMeal(summary.records, 'dinner'),
                icon: Icons.nightlight_round),
            MealStatusItem(
                label: '간식',
                done: _hasMeal(summary.records, 'snack'),
                icon: Icons.icecream_outlined),
          ],
        ),
        const SectionHeader(title: '식사 시간 피드백'),
        AppCard(
          color: AppColors.creamBackground,
          borderColor: AppColors.orange.withValues(alpha: 0.18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tips_and_updates_outlined,
                    color: AppColors.orange, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(timingMessage, style: AppTextStyles.body)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AiSuggestionCard(onPressed: onAnalyzeFood),
        const SectionHeader(title: '오늘 식단'),
        TodayMealList(records: summary.records, onAddMeal: onAnalyzeFood),
        const SizedBox(height: 8),
        const Text(AppConstants.estimateNotice, style: AppTextStyles.caption),
      ],
    );
  }

  static bool _hasMeal(List<MealRecord> records, String type) {
    return records.any((record) => record.mealType == type);
  }

  String _greeting(String nickname) {
    if (nickname.isEmpty) {
      return '안녕하세요, 오늘 하루도 건강하게 시작해볼까요?';
    }
    return '$nickname님, 오늘 하루도 건강하게 시작해볼까요?';
  }
}
