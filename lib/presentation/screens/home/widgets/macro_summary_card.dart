import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/daily_summary.dart';
import '../../../widgets/app_card.dart';

class MacroSummaryCard extends StatelessWidget {
  const MacroSummaryCard(
      {required this.summary, required this.targetKcal, super.key});

  final DailySummary summary;
  final double targetKcal;

  @override
  Widget build(BuildContext context) {
    final carbsKcal = summary.totalCarbs * 4;
    final proteinKcal = summary.totalProtein * 4;
    final fatKcal = summary.totalFat * 9;
    final totalMacroKcal = carbsKcal + proteinKcal + fatKcal;
    final hasMacroData = totalMacroKcal > 0;
    final carbsRatio = hasMacroData ? carbsKcal / totalMacroKcal : 0.0;
    final proteinRatio = hasMacroData ? proteinKcal / totalMacroKcal : 0.0;
    final fatRatio = hasMacroData ? fatKcal / totalMacroKcal : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(104),
                  painter: _MacroBalanceRingPainter(
                    carbsRatio: carbsRatio,
                    proteinRatio: proteinRatio,
                    fatRatio: fatRatio,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasMacroData ? '비율' : '대기',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                _MacroRatioRow(
                  label: '탄수화물',
                  gram: summary.totalCarbs,
                  ratio: carbsRatio,
                  color: AppColors.macroCarb,
                ),
                const SizedBox(height: 10),
                _MacroRatioRow(
                  label: '단백질',
                  gram: summary.totalProtein,
                  ratio: proteinRatio,
                  color: AppColors.macroProtein,
                ),
                const SizedBox(height: 10),
                _MacroRatioRow(
                  label: '지방',
                  gram: summary.totalFat,
                  ratio: fatRatio,
                  color: AppColors.macroFat,
                ),
                if (!hasMacroData) ...[
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '식사 기록이 쌓이면 비율이 표시돼요.',
                      style: AppTextStyles.caption,
                    ),
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

class _MacroRatioRow extends StatelessWidget {
  const _MacroRatioRow({
    required this.label,
    required this.gram,
    required this.ratio,
    required this.color,
  });

  final String label;
  final double gram;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = (ratio * 100).round();

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: AppTextStyles.caption),
        ),
        Text(
          '${gram.toStringAsFixed(0)}g',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$percent%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroBalanceRingPainter extends CustomPainter {
  _MacroBalanceRingPainter({
    required this.carbsRatio,
    required this.proteinRatio,
    required this.fatRatio,
  });

  final double carbsRatio;
  final double proteinRatio;
  final double fatRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.12;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.border;

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -math.pi / 2,
      math.pi * 2,
      false,
      basePaint,
    );

    final sections = [
      (ratio: carbsRatio, color: AppColors.macroCarb),
      (ratio: proteinRatio, color: AppColors.macroProtein),
      (ratio: fatRatio, color: AppColors.macroFat),
    ].where((section) => section.ratio > 0).toList();

    if (sections.isEmpty) {
      return;
    }

    var start = -math.pi / 2;
    const gap = 0.035;
    for (final section in sections) {
      final sweep = math.pi * 2 * section.ratio;
      final adjustedSweep = math.max(0.0, sweep - gap);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = section.color;
      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        start,
        adjustedSweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroBalanceRingPainter oldDelegate) {
    return oldDelegate.carbsRatio != carbsRatio ||
        oldDelegate.proteinRatio != proteinRatio ||
        oldDelegate.fatRatio != fatRatio;
  }
}
