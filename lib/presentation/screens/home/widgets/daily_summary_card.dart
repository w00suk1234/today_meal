import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/daily_summary.dart';
import '../../../widgets/app_card.dart';

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard(
      {required this.summary, required this.targetKcal, super.key});

  final DailySummary summary;
  final double targetKcal;

  @override
  Widget build(BuildContext context) {
    final percent = NutritionCalculator.calculateTargetPercent(
        summary.totalKcal, targetKcal);
    final remaining = targetKcal - summary.totalKcal;
    final progress = (percent / 100).clamp(0.0, 1.0);

    return AppCard(
      padding: const EdgeInsets.all(22),
      color: AppColors.cardWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('오늘 총 섭취',
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(summary.totalKcal.round().toString(),
                            style: AppTextStyles.metric),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text('kcal',
                              style: AppTextStyles.muted
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      remaining >= 0
                          ? '남은 칼로리 ${remaining.round()}kcal'
                          : '목표보다 ${remaining.abs().round()}kcal 초과',
                      style: TextStyle(
                        color: remaining >= 0
                            ? AppColors.primary
                            : AppColors.coral,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        backgroundColor: AppColors.primarySoft,
                        color: AppColors.primary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${percent.round()}%',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 18)),
                        const SizedBox(height: 2),
                        const Text('달성', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(label: '목표', value: NutritionCalculator.kcal(targetKcal)),
              _Metric(label: '오늘 기록', value: '${summary.records.length}개'),
              _Metric(
                  label: remaining >= 0 ? '남은 칼로리' : '초과',
                  value: NutritionCalculator.kcal(remaining.abs())),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
