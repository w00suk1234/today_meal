import 'package:flutter/material.dart';

import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/daily_summary.dart';

class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard(
      {required this.summary, required this.targetKcal, super.key});

  final DailySummary summary;
  final double targetKcal;

  @override
  Widget build(BuildContext context) {
    final percent = NutritionCalculator.calculateTargetPercent(
        summary.totalKcal, targetKcal);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${summary.totalKcal.round()}kcal',
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('목표 대비 ${percent.round()}% · 기록 ${summary.records.length}개'),
            const SizedBox(height: 12),
            Text(
              '탄 ${summary.totalCarbs.toStringAsFixed(1)}g · 단 ${summary.totalProtein.toStringAsFixed(1)}g · 지 ${summary.totalFat.toStringAsFixed(1)}g',
            ),
          ],
        ),
      ),
    );
  }
}
