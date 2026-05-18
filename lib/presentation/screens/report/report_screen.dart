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
import '../../../data/models/weight_record.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/ai_improvement_report_card.dart';
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
      weightRecords: controller.weightRecords,
    );
    final weekly = _weeklySummaries(controller);
    final streak = _streakDays(controller);
    final health = controller.healthProfile;
    final latestWeight = controller.latestWeightKg;
    final latestBmi = controller.latestBmi;
    final hasTodayRecords = summary.records.isNotEmpty;
    final hasWeeklyRecords = weekly.any(
      (summary) => summary.records.isNotEmpty,
    );
    final recordedDays7 =
        weekly.where((summary) => summary.records.isNotEmpty).length;

    return AppScaffold(
      controller: scrollController,
      children: [
        const AppPageHeader(
          title: '기록 요약',
          subtitle: '오늘 식단과 몸무게 기록을 한눈에 정리했어요',
          icon: Icons.insights_rounded,
        ),
        _DailyReportHero(
          summary: summary,
          targetKcal: controller.profile.targetKcal,
          hasRecords: hasTodayRecords,
        ),
        const SectionHeader(title: 'AI 개선 리포트'),
        AiImprovementReportCard(
          result: controller.cachedAiImprovementReport,
          loading: controller.isGeneratingAiImprovementReport,
          errorMessage: controller.aiImprovementReportError,
          onGenerate: () => controller.generateAiImprovementReport(),
          onRegenerate: () =>
              controller.generateAiImprovementReport(forceRefresh: true),
        ),
        const SectionHeader(title: '오늘 식단 피드백'),
        if (hasTodayRecords)
          for (final message in messages.take(3))
            ReportMessageCard(message: message)
        else
          AppEmptyState(
            message: '아직 분석할 식단 기록이 없습니다. 식사 기록이 쌓이면 섭취 패턴을 요약해드려요.',
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
        _StreakCard(
          streak: streak,
          recordCount: controller.records.length,
          recordedDays7: recordedDays7,
          weightRecordCount: controller.weightRecords.length,
        ),
        const SectionHeader(title: '몸상태 요약'),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: '현재 체중',
                value: _weightText(latestWeight),
                subtitle: '목표 ${health.targetWeightKg.toStringAsFixed(1)}kg',
                icon: Icons.monitor_weight_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: 'BMI',
                value: latestBmi <= 0 ? '미입력' : latestBmi.toStringAsFixed(1),
                subtitle: '${HealthCalculator.getBmiCategory(latestBmi)} · 참고용',
                icon: Icons.favorite_outline,
                color: AppColors.coral,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _WeightTrendCard(
          records: controller.weightRecords,
          startingWeight: controller.startingWeightKg,
          latestFallbackWeight: latestWeight,
          targetWeight: health.targetWeightKg,
          latestBmi: latestBmi,
          trend7Days: controller.weightTrend7Days,
        ),
      ],
    );
  }

  static String _weightText(double? value) {
    if (value == null || value <= 0) {
      return '미입력';
    }
    return '${value.toStringAsFixed(1)}kg';
  }

  List<DailySummary> _weeklySummaries(TodayMealController controller) {
    final now = DateTime.now();
    return [
      for (var i = 6; i >= 0; i--)
        controller.summaryFor(
          AppDateUtils.dateKey(now.subtract(Duration(days: i))),
        ),
    ];
  }

  int _streakDays(TodayMealController controller) {
    final now = DateTime.now();
    var streak = 0;
    for (var i = 0; i < 60; i++) {
      final summary = controller.summaryFor(
        AppDateUtils.dateKey(now.subtract(Duration(days: i))),
      );
      if (summary.records.isEmpty) {
        break;
      }
      streak++;
    }
    return streak;
  }
}

class _DailyReportHero extends StatelessWidget {
  const _DailyReportHero({
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
      summary.totalKcal,
      targetKcal,
    );
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
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.summarize_outlined,
                  color: hasRecords ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasRecords ? '오늘 식단 요약' : '아직 분석할 식단 기록이 없습니다',
                      style: TextStyle(
                        color:
                            hasRecords ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasRecords
                          ? '목표 대비 ${percent.round()}% · 식사 기록 ${summary.records.length}개'
                          : '식사 기록이 쌓이면 오늘의 섭취 패턴을 요약해드려요.',
                      style: TextStyle(
                        color: hasRecords
                            ? Colors.white.withValues(alpha: 0.78)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                Text(
                  summary.totalKcal.round().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'kcal',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
  const _WeeklyCaloriesChart({
    required this.summaries,
    required this.targetKcal,
    required this.hasData,
    required this.onAddMeal,
  });

  final List<DailySummary> summaries;
  final double targetKcal;
  final bool hasData;
  final VoidCallback onAddMeal;

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(
      targetKcal,
      summaries.map((summary) => summary.totalKcal).fold<double>(0, math.max),
    );
    final recordedDays =
        summaries.where((summary) => summary.records.isNotEmpty).length;
    final todayKcal = summaries.isEmpty ? 0 : summaries.last.totalKcal.round();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hasData
                      ? '최근 7일 중 $recordedDays일 기록 · 오늘 ${todayKcal}kcal'
                      : '최근 7일 식사 기록 대기 중',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (targetKcal > 0)
                Text('권장 ${targetKcal.round()}kcal',
                    style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 158,
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
                          SizedBox(
                            height: 20,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                summaries[i].totalKcal > 0
                                    ? summaries[i].totalKcal.round().toString()
                                    : '',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: hasData
                                    ? summaries[i].totalKcal <= 0
                                        ? 0.03
                                        : (summaries[i].totalKcal / maxValue)
                                            .clamp(0.14, 1.0)
                                    : (0.22 + i * 0.035).clamp(0.2, 0.48),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: hasData
                                        ? (i == summaries.length - 1
                                            ? AppColors.primary
                                            : AppColors.primarySoft)
                                        : AppColors.border.withValues(
                                            alpha: 0.8,
                                          ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _weekdayLabel(summaries[i].dateKey),
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!hasData) ...[
            const SizedBox(height: 14),
            const Text(
              '식사 기록이 쌓이면 주간 추이가 표시됩니다.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
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

  String _weekdayLabel(String dateKey) {
    final date = DateTime.tryParse(dateKey);
    if (date == null) {
      return '';
    }
    return const ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];
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
                    Text(
                      hasData ? summary.totalKcal.round().toString() : '대기',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      hasData ? 'kcal' : '기록 필요',
                      style: AppTextStyles.caption,
                    ),
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
                  color:
                      hasData ? AppColors.macroCarb : AppColors.textSecondary,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  label: '단백질',
                  value: summary.totalProtein,
                  color: hasData
                      ? AppColors.macroProtein
                      : AppColors.textSecondary,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  label: '지방',
                  value: summary.totalFat,
                  color: hasData ? AppColors.macroFat : AppColors.textSecondary,
                ),
                if (!hasData) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '식사 기록이 쌓이면 탄단지 균형이 표시됩니다.',
                    style: AppTextStyles.caption,
                  ),
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
  const _RingPainter({
    required this.carb,
    required this.protein,
    required this.fat,
    required this.muted,
  });

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
        color: muted ? AppColors.divider : AppColors.macroProtein,
      ),
      (
        value: fat,
        color: muted ? AppColors.lightGreenBackground : AppColors.macroFat,
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
  const _LegendRow({
    required this.label,
    required this.value,
    required this.color,
  });

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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.caption)),
        Text(
          '${value.toStringAsFixed(0)}g',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.streak,
    required this.recordCount,
    required this.recordedDays7,
    required this.weightRecordCount,
  });

  final int streak;
  final int recordCount;
  final int recordedDays7;
  final int weightRecordCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Icon(
                        Icons.checklist_rtl_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$streak일 연속 식사 기록',
                              style: AppTextStyles.section),
                          const SizedBox(height: 3),
                          const Text('식단과 몸무게 기록 습관을 보여줘요',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ActivityStat(label: '이번 주', value: '$recordedDays7일'),
                    _ActivityStat(label: '식사 기록', value: '$recordCount개'),
                    _ActivityStat(label: '몸무게', value: '$weightRecordCount개'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  const _ActivityStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _WeightTrendCard extends StatelessWidget {
  const _WeightTrendCard({
    required this.records,
    required this.startingWeight,
    required this.latestFallbackWeight,
    required this.targetWeight,
    required this.latestBmi,
    required this.trend7Days,
  });

  final List<WeightRecord> records;
  final double? startingWeight;
  final double? latestFallbackWeight;
  final double targetWeight;
  final double latestBmi;
  final double? trend7Days;

  @override
  Widget build(BuildContext context) {
    final sortedRecords = [...records]
      ..sort((a, b) => a.date.compareTo(b.date));
    final hasRecords = sortedRecords.isNotEmpty;
    final baselineWeight = startingWeight != null && startingWeight! > 0
        ? startingWeight
        : hasRecords
            ? sortedRecords.first.weightKg
            : latestFallbackWeight;
    final latestWeight =
        hasRecords ? sortedRecords.last.weightKg : latestFallbackWeight;
    final totalDiff = baselineWeight == null || latestWeight == null
        ? null
        : latestWeight - baselineWeight;
    final targetDiff = latestWeight == null || targetWeight <= 0
        ? null
        : targetWeight - latestWeight;
    return AppCard(
      color: AppColors.creamBackground,
      borderColor: AppColors.orange.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: AppColors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasRecords ? '몸무게 변화 추이' : '몸무게 기록 대기',
                  style: AppTextStyles.section,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasRecords)
            const Text(
              '아직 몸무게 기록이 없습니다. 홈에서 오늘 몸무게를 기록해 보세요.',
              style: AppTextStyles.body,
            )
          else ...[
            _WeightLineChart(
              points: _chartPoints(baselineWeight, sortedRecords),
              targetWeight: targetWeight > 0 ? targetWeight : null,
              totalDiff: totalDiff,
            ),
            const SizedBox(height: 14),
            _TrendRow(
              label: '설정 시작 → 최신',
              value:
                  '${baselineWeight!.toStringAsFixed(1)}kg → ${latestWeight!.toStringAsFixed(1)}kg',
            ),
            const SizedBox(height: 8),
            _TrendRow(
              label: '최근 7일',
              value: trend7Days == null
                  ? '2개 이상 기록하면 표시돼요'
                  : '${trend7Days! >= 0 ? '+' : ''}${trend7Days!.toStringAsFixed(1)}kg 변화',
            ),
            const SizedBox(height: 8),
            _TrendRow(
              label: '목표까지',
              value: targetDiff == null
                  ? '목표 체중 미입력'
                  : targetDiff.abs() < 0.1
                      ? '목표 체중에 가까워요'
                      : '목표 체중까지 ${targetDiff.abs().toStringAsFixed(1)}kg 남았어요',
            ),
            const SizedBox(height: 8),
            _TrendRow(
              label: '최신 BMI',
              value: latestBmi <= 0
                  ? '키와 몸무게 입력 필요'
                  : '${latestBmi.toStringAsFixed(1)} · 참고용',
            ),
          ],
        ],
      ),
    );
  }

  List<_WeightChartPoint> _chartPoints(
    double? baselineWeight,
    List<WeightRecord> sortedRecords,
  ) {
    final points = <_WeightChartPoint>[];
    if (baselineWeight != null && baselineWeight > 0) {
      points.add(_WeightChartPoint(label: '시작', weightKg: baselineWeight));
    }

    final visibleRecords = sortedRecords.length > 5
        ? sortedRecords.sublist(sortedRecords.length - 5)
        : sortedRecords;
    for (var i = 0; i < visibleRecords.length; i++) {
      final record = visibleRecords[i];
      final isLast = i == visibleRecords.length - 1;
      points.add(
        _WeightChartPoint(
          label: isLast ? '최신' : '${record.date.month}/${record.date.day}',
          weightKg: record.weightKg,
        ),
      );
    }

    if (points.length == 1) {
      points.add(
        _WeightChartPoint(label: '최신', weightKg: points.first.weightKg),
      );
    }
    return points;
  }
}

class _WeightChartPoint {
  const _WeightChartPoint({required this.label, required this.weightKg});

  final String label;
  final double weightKg;
}

class _WeightLineChart extends StatelessWidget {
  const _WeightLineChart({
    required this.points,
    required this.targetWeight,
    required this.totalDiff,
  });

  final List<_WeightChartPoint> points;
  final double? targetWeight;
  final double? totalDiff;

  @override
  Widget build(BuildContext context) {
    final diff = totalDiff;
    final trendColor =
        diff == null || diff <= 0 ? AppColors.primary : AppColors.orange;
    final trendText = diff == null
        ? '기록 대기'
        : diff.abs() < 0.1
            ? '변화 거의 없음'
            : diff < 0
                ? '${diff.abs().toStringAsFixed(1)}kg 감량'
                : '${diff.toStringAsFixed(1)}kg 증가';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '몸무게 그래프',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                trendText,
                style: TextStyle(
                  color: trendColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 128,
            child: CustomPaint(
              painter: _WeightLineChartPainter(
                points: points,
                targetWeight: targetWeight,
                lineColor: trendColor,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final point in points)
                Expanded(
                  child: Text(
                    point.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          if (targetWeight != null) ...[
            const SizedBox(height: 6),
            Text(
              '점선은 목표 체중 ${targetWeight!.toStringAsFixed(1)}kg 기준이에요.',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }
}

class _WeightLineChartPainter extends CustomPainter {
  const _WeightLineChartPainter({
    required this.points,
    required this.targetWeight,
    required this.lineColor,
  });

  final List<_WeightChartPoint> points;
  final double? targetWeight;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final weights = [
      for (final point in points) point.weightKg,
      if (targetWeight != null) targetWeight!,
    ];
    var minWeight = weights.reduce(math.min);
    var maxWeight = weights.reduce(math.max);
    if ((maxWeight - minWeight).abs() < 0.5) {
      minWeight -= 0.25;
      maxWeight += 0.25;
    } else {
      final padding = (maxWeight - minWeight) * 0.18;
      minWeight -= padding;
      maxWeight += padding;
    }

    const chartPadding = EdgeInsets.fromLTRB(8, 8, 8, 10);
    final chartWidth = size.width - chartPadding.horizontal;
    final chartHeight = size.height - chartPadding.vertical;
    final origin = Offset(chartPadding.left, chartPadding.top);

    double xFor(int index) {
      if (points.length <= 1) {
        return origin.dx + chartWidth / 2;
      }
      return origin.dx + chartWidth * index / (points.length - 1);
    }

    double yFor(double weight) {
      final ratio = (maxWeight - weight) / (maxWeight - minWeight);
      return origin.dy + chartHeight * ratio.clamp(0.0, 1.0);
    }

    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.75)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = origin.dy + chartHeight * i / 3;
      canvas.drawLine(
          Offset(origin.dx, y), Offset(origin.dx + chartWidth, y), gridPaint);
    }

    final target = targetWeight;
    if (target != null && target >= minWeight && target <= maxWeight) {
      final y = yFor(target);
      final dashPaint = Paint()
        ..color = AppColors.textMuted.withValues(alpha: 0.45)
        ..strokeWidth = 1.2;
      var x = origin.dx;
      while (x < origin.dx + chartWidth) {
        canvas.drawLine(Offset(x, y),
            Offset(math.min(x + 7, origin.dx + chartWidth), y), dashPaint);
        x += 12;
      }
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final offset = Offset(xFor(i), yFor(points[i].weightKg));
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(xFor(points.length - 1), origin.dy + chartHeight)
      ..lineTo(xFor(0), origin.dy + chartHeight)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.16),
          lineColor.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = lineColor;
    final pointBorderPaint = Paint()..color = AppColors.cardWhite;
    for (var i = 0; i < points.length; i++) {
      final offset = Offset(xFor(i), yFor(points[i].weightKg));
      canvas.drawCircle(offset, 6, pointBorderPaint);
      canvas.drawCircle(offset, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightLineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.targetWeight != targetWeight ||
        oldDelegate.lineColor != lineColor;
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 86, child: Text(label, style: AppTextStyles.caption)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
