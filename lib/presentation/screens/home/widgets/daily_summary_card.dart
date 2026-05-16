import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/daily_summary.dart';
import '../../../widgets/app_card.dart';

final _kcalFormatter = NumberFormat.decimalPattern('ko_KR');

class DailySummaryCard extends StatelessWidget {
  const DailySummaryCard({
    required this.summary,
    required this.targetKcal,
    super.key,
  });

  final DailySummary summary;
  final double targetKcal;

  @override
  Widget build(BuildContext context) {
    final percent = NutritionCalculator.calculateTargetPercent(
      summary.totalKcal,
      targetKcal,
    );
    final remaining = targetKcal - summary.totalKcal;
    final progress = (percent / 100).clamp(0.0, 1.0);
    final isOverTarget = remaining < 0;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      color: AppColors.cardWhite,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          final ringSize = compact ? 84.0 : 94.0;
          final ringStroke = compact ? 8.0 : 9.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '오늘 총 섭취',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatKcalNumber(summary.totalKcal),
                                style: AppTextStyles.metric.copyWith(
                                  fontSize: compact ? 29 : 31,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  'kcal',
                                  style: AppTextStyles.muted.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _RemainingPill(
                          label: isOverTarget
                              ? '초과 ${_formatKcal(remaining.abs())}'
                              : '남은 ${_formatKcal(remaining)}',
                          isOverTarget: isOverTarget,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: ringStroke,
                            backgroundColor: AppColors.primarySoft,
                            color: AppColors.primary,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${percent.round()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: compact ? 16 : 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text('달성', style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Metric(label: '목표', value: _formatKcal(targetKcal)),
                  const SizedBox(width: 10),
                  _Metric(label: '오늘 기록', value: '${summary.records.length}개'),
                  const SizedBox(width: 10),
                  _Metric(
                    label: isOverTarget ? '초과' : '남은 칼로리',
                    value: _formatKcal(remaining.abs()),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RemainingPill extends StatelessWidget {
  const _RemainingPill({
    required this.label,
    required this.isOverTarget,
  });

  final String label;
  final bool isOverTarget;

  @override
  Widget build(BuildContext context) {
    final color = isOverTarget ? AppColors.coral : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
    );
  }
}

String _formatKcal(double value) => '${_formatKcalNumber(value)} kcal';

String _formatKcalNumber(double value) => _kcalFormatter.format(value.round());

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
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
