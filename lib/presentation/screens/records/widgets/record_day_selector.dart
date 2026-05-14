import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../widgets/app_card.dart';

class RecordDaySelector extends StatelessWidget {
  const RecordDaySelector({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          _RoundIconButton(icon: Icons.chevron_left, onPressed: onPrevious),
          Expanded(
            child: TextButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label: Text(
                AppDateUtils.koreanDate(selectedDate),
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          _RoundIconButton(icon: Icons.chevron_right, onPressed: onNext),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.lightGreenBackground,
        foregroundColor: AppColors.primary,
      ),
      icon: Icon(icon),
    );
  }
}
