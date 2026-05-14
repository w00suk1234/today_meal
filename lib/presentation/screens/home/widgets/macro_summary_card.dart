import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/daily_summary.dart';
import '../../../widgets/macro_progress_card.dart';

class MacroSummaryCard extends StatelessWidget {
  const MacroSummaryCard(
      {required this.summary, required this.targetKcal, super.key});

  final DailySummary summary;
  final double targetKcal;

  @override
  Widget build(BuildContext context) {
    final carbTarget = targetKcal <= 0 ? 250.0 : targetKcal * 0.5 / 4;
    final proteinTarget = targetKcal <= 0 ? 90.0 : targetKcal * 0.2 / 4;
    final fatTarget = targetKcal <= 0 ? 60.0 : targetKcal * 0.3 / 9;

    return Row(
      children: [
        Expanded(
          child: MacroProgressCard(
            label: '탄수화물',
            value: summary.totalCarbs,
            target: carbTarget,
            color: AppColors.macroCarb,
            icon: Icons.grain_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MacroProgressCard(
            label: '단백질',
            value: summary.totalProtein,
            target: proteinTarget,
            color: AppColors.macroProtein,
            icon: Icons.egg_alt_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: MacroProgressCard(
            label: '지방',
            value: summary.totalFat,
            target: fatTarget,
            color: AppColors.macroFat,
            icon: Icons.water_drop_outlined,
          ),
        ),
      ],
    );
  }
}
