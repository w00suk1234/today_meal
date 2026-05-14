import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/section_header.dart';

class MealTimeSection extends StatelessWidget {
  const MealTimeSection({
    required this.eatenAt,
    required this.startedAt,
    required this.finishedAt,
    required this.onPickEatenAt,
    required this.onPickStartedAt,
    required this.onPickFinishedAt,
    super.key,
  });

  final DateTime eatenAt;
  final DateTime startedAt;
  final DateTime finishedAt;
  final VoidCallback onPickEatenAt;
  final VoidCallback onPickStartedAt;
  final VoidCallback onPickFinishedAt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '식사 시간'),
        AppCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _TimeRow(
                  label: '먹은 날짜/시간',
                  value: _format(eatenAt),
                  icon: Icons.event_available_outlined,
                  onTap: onPickEatenAt),
              const Divider(height: 18, color: AppColors.divider),
              _TimeRow(
                  label: '식사 시작',
                  value: _format(startedAt),
                  icon: Icons.play_circle_outline,
                  onTap: onPickStartedAt),
              const Divider(height: 18, color: AppColors.divider),
              _TimeRow(
                  label: '식사 종료',
                  value: _format(finishedAt),
                  icon: Icons.stop_circle_outlined,
                  onTap: onPickFinishedAt),
            ],
          ),
        ),
      ],
    );
  }

  String _format(DateTime value) {
    final mm = value.minute.toString().padLeft(2, '0');
    return '${value.month}/${value.day} ${value.hour}:$mm';
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        IconButton(
          tooltip: label,
          onPressed: onTap,
          icon: const Icon(Icons.edit_calendar_outlined,
              color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
