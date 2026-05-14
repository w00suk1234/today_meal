import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/health_calculator.dart';
import '../../../core/utils/nutrition_calculator.dart';
import '../../../core/utils/report_generator.dart';
import '../../../data/models/daily_summary.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/section_header.dart';
import 'widgets/report_message_card.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({
    required this.onAddMeal,
    this.scrollController,
    super.key,
  });

  final VoidCallback onAddMeal;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final summary = controller.todaySummary;
    final messages = ReportGenerator.generateAdvancedDailyReport(
      summary: summary,
      profile: controller.profile,
      healthProfile: controller.healthProfile,
      weightLogs: controller.weightLogs,
    );
    final weekly = _weeklySummaries(controller);
    final streak = _streakDays(controller);
    final health = controller.healthProfile;
    final hasTodayRecords = summary.records.isNotEmpty;
    final hasWeeklyRecords =
        weekly.any((summary) => summary.records.isNotEmpty);

    return AppScaffold(
      controller: scrollController,
      children: [
        const AppPageHeader(
          title: '리포트',
          subtitle: '오늘의 기록을 AI 코칭 리포트처럼 정리했어요',
          icon: Icons.insights_rounded,
        ),
        _AiReportHero(
            summary: summary,
            targetKcal: controller.profile.targetKcal,
            hasRecords: hasTodayRecords),
        const SectionHeader(title: 'AI 영양 분석 리포트'),
        if (hasTodayRecords)
          for (final message in messages.take(3))
            ReportMessageCard(message: message)
        else
          AppEmptyState(
            message: '아직 분석할 식단 기록이 없습니다. 식사 기록이 쌓이면 AI가 섭취 패턴을 요약해드려요.',
            icon: Icons.auto_graph_outlined,
            actionLabel: '식사 추가하기',
            onAction: onAddMeal,
          ),
        const SectionHeader(title: '주간 칼로리 추이'),
        _WeeklyCaloriesChart(
          summaries: weekly,
          targetKcal: controller.profile.targetKcal,
          hasData: hasWeeklyRecords,
          onAddMeal: onAddMeal,
        ),
        const SectionHeader(title: '영양 밸런스'),
        _NutritionBalanceCard(summary: summary),
        const SectionHeader(title: '활동 기록'),
        _StreakCard(streak: streak, recordCount: controller.records.length),
        const SectionHeader(title: '몸상태 요약'),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '현재 체중',
                value: '${health.weightKg.toStringAsFixed(1)}kg',
                subtitle: '목표 ${health.targetWeightKg.toStringAsFixed(1)}kg',
                icon: Icons.monitor_weight_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: 'BMI',
                value: health.bmi <= 0 ? '미입력' : health.bmi.toStringAsFixed(1),
                subtitle: HealthCalculator.getBmiCategory(health.bmi),
                icon: Icons.favorite_outline,
                color: AppColors.coral,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _WeightTrendCard(
            weights: controller.weightLogs.map((log) => log.weightKg).toList()),
        if (controller.weightLogs.isEmpty) ...[
          const SizedBox(height: 10),
          AppEmptyState(
            message: '몸상태 기록이 쌓이면 체중 변화 추이를 더 자연스럽게 보여드릴게요.',
            icon: Icons.monitor_weight_outlined,
            actionLabel: '식사 추가하기',
            onAction: onAddMeal,
          ),
        ],
      ],
    );
  }

  List<DailySummary> _weeklySummaries(TodayMealController controller) {
    final now = DateTime.now();
    return [
      for (var i = 6; i >= 0; i--)
        controller
            .summaryFor(AppDateUtils.dateKey(now.subtract(Duration(days: i)))),
    ];
  }

  int _streakDays(TodayMealController controller) {
    final now = DateTime.now();
    var streak = 0;
    for (var i = 0; i < 60; i++) {
      final summary = controller
          .summaryFor(AppDateUtils.dateKey(now.subtract(Duration(days: i))));
      if (summary.records.isEmpty) {
        break;
      }
      streak++;
    }
    return streak;
  }
}

class _AiReportHero extends StatelessWidget {
  const _AiReportHero({
    required this.summary,
    required this.targetKcal,
    required this.hasRecords,
  });

  final DailySummary summary;
  final double targetKcal;
  final bool hasRecords;

  @override
  Widget build(BuildContext context) {
    final percent = NutritionCalculator.calculateTargetPercent(
        summary.totalKcal, targetKcal);
    return AppCard(
      color:
          hasRecords ? AppColors.primaryDark : AppColors.lightGreenBackground,
      borderColor: hasRecords ? AppColors.primaryDark : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: hasRecords
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.cardWhite,
                    shape: BoxShape.circle),
                child: Icon(Icons.auto_awesome,
                    color: hasRecords ? Colors.white : AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hasRecords ? 'AI 영양 분석 리포트' : '아직 분석할 식단 기록이 없습니다',
                        style: TextStyle(
                            color: hasRecords
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(
                        hasRecords
                            ? '목표 대비 ${percent.round()}% · 식사 기록 ${summary.records.length}개'
                            : '식사 기록이 쌓이면 오늘의 섭취 패턴을 요약해드려요.',
                        style: TextStyle(
                            color: hasRecords
                                ? Colors.white.withValues(alpha: 0.78)
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          if (hasRecords) ...[
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(summary.totalKcal.round().toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('kcal',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyCaloriesChart extends StatelessWidget {
  const _WeeklyCaloriesChart(
      {required this.summaries,
      required this.targetKcal,
      required this.hasData,
      required this.onAddMeal});

  final List<DailySummary> summaries;
  final double targetKcal;
  final bool hasData;
  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(
        targetKcal,
        summaries
            .map((summary) => summary.totalKcal)
            .fold<double>(0, math.max));
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return AppCard(
      child: Column(
        children: [
          SizedBox(
            height: 168,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < summaries.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: hasData
                                    ? (summaries[i].totalKcal / maxValue)
                                        .clamp(0.08, 1.0)
                                    : (0.22 + i * 0.035).clamp(0.2, 0.48),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: hasData
                                        ? (i == summaries.length - 1
                                            ? AppColors.primary
                                            : AppColors.primarySoft)
                                        : AppColors.border
                                            .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(labels[i],
                              style: AppTextStyles.caption
                                  .copyWith(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!hasData) ...[
            const SizedBox(height: 14),
            const Text('식사 기록이 쌓이면 주간 추이가 표시됩니다.',
                textAlign: TextAlign.center, style: AppTextStyles.caption),
            const SizedBox(height: 12),
            SizedBox(
              width: 170,
              height: 44,
              child: FilledButton.icon(
                onPressed: onAddMeal,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('식사 추가하기'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NutritionBalanceCard extends StatelessWidget {
  const _NutritionBalanceCard({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.totalCarbs + summary.totalProtein + summary.totalFat;
    final hasData = total > 0;
    return AppCard(
      child: Row(
        children: [
          SizedBox(
            width: 112,
            height: 112,
            child: CustomPaint(
              painter: _RingPainter(
                carb: hasData ? summary.totalCarbs / total : 0.34,
                protein: hasData ? summary.totalProtein / total : 0.33,
                fat: hasData ? summary.totalFat / total : 0.33,
                muted: !hasData,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(hasData ? summary.totalKcal.round().toString() : '대기',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(hasData ? 'kcal' : '기록 필요',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                _LegendRow(
                    label: '탄수화물',
                    value: summary.totalCarbs,
                    color: hasData
                        ? AppColors.macroCarb
                        : AppColors.textSecondary),
                const SizedBox(height: 10),
                _LegendRow(
                    label: '단백질',
                    value: summary.totalProtein,
                    color: hasData
                        ? AppColors.macroProtein
                        : AppColors.textSecondary),
                const SizedBox(height: 10),
                _LegendRow(
                    label: '지방',
                    value: summary.totalFat,
                    color:
                        hasData ? AppColors.macroFat : AppColors.textSecondary),
                if (!hasData) ...[
                  const SizedBox(height: 12),
                  const Text('식사 기록이 쌓이면 탄단지 균형이 표시됩니다.',
                      style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(
      {required this.carb,
      required this.protein,
      required this.fat,
      required this.muted});

  final double carb;
  final double protein;
  final double fat;
  final bool muted;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    var start = -math.pi / 2;
    for (final segment in [
      (value: carb, color: muted ? AppColors.border : AppColors.macroCarb),
      (
        value: protein,
        color: muted ? AppColors.divider : AppColors.macroProtein
      ),
      (
        value: fat,
        color: muted ? AppColors.lightGreenBackground : AppColors.macroFat
      ),
    ]) {
      paint.color = segment.color;
      final sweep = math.max(segment.value, 0.04) * math.pi * 2;
      canvas.drawArc(rect.deflate(8), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.carb != carb ||
        oldDelegate.protein != protein ||
        oldDelegate.fat != fat ||
        oldDelegate.muted != muted;
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(
      {required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.caption)),
        Text('${value.toStringAsFixed(0)}g',
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.recordCount});

  final int streak;
  final int recordCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.local_fire_department_outlined,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$streak일 연속 기록', style: AppTextStyles.section),
                const SizedBox(height: 5),
                Text('누적 식사 기록 $recordCount개', style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightTrendCard extends StatelessWidget {
  const _WeightTrendCard({required this.weights});

  final List<double> weights;

  @override
  Widget build(BuildContext context) {
    final latest = weights.isEmpty ? 0.0 : weights.last;
    final first = weights.isEmpty ? latest : weights.first;
    final diff = latest - first;
    return AppCard(
      color: AppColors.creamBackground,
      borderColor: AppColors.orange.withValues(alpha: 0.18),
      child: Row(
        children: [
          const Icon(Icons.show_chart_rounded, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              weights.isEmpty
                  ? '아직 체중 변화 기록이 없습니다.'
                  : '최근 체중 변화 ${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}kg',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
