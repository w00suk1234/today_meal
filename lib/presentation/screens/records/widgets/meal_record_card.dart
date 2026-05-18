import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/meal_record.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/food_image_view.dart';

enum MealRecordMenuAction { edit, delete }

class MealRecordGroupCard extends StatelessWidget {
  const MealRecordGroupCard({
    required this.mealType,
    required this.records,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final String mealType;
  final List<MealRecord> records;
  final ValueChanged<MealRecord> onEdit;
  final ValueChanged<MealRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    final orderedRecords = [...records]
      ..sort((a, b) => a.effectiveEatenAt.compareTo(b.effectiveEatenAt));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _icon(mealType),
                    color: AppColors.primary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_label(mealType)} 식사',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _summaryText(orderedRecords),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  NutritionCalculator.kcal(_totalKcal(orderedRecords)),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < orderedRecords.length; i++)
              _MealRecordRow(
                record: orderedRecords[i],
                showDivider: i < orderedRecords.length - 1,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MacroDot(
                  color: AppColors.macroCarb,
                  label: '탄 ${_totalCarbs(orderedRecords).toStringAsFixed(0)}g',
                ),
                _MacroDot(
                  color: AppColors.macroProtein,
                  label:
                      '단 ${_totalProtein(orderedRecords).toStringAsFixed(0)}g',
                ),
                _MacroDot(
                  color: AppColors.macroFat,
                  label: '지 ${_totalFat(orderedRecords).toStringAsFixed(0)}g',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _summaryText(List<MealRecord> items) {
    final names = items.map((record) => record.foodName).toList();
    final joined = names.take(3).join(', ');
    final suffix = names.length > 3 ? ' 외 ${names.length - 3}개' : '';
    return '${items.length}개 메뉴 · $joined$suffix';
  }

  double _totalKcal(List<MealRecord> items) =>
      items.fold(0, (sum, item) => sum + item.kcal);

  double _totalCarbs(List<MealRecord> items) =>
      items.fold(0, (sum, item) => sum + item.carbs);

  double _totalProtein(List<MealRecord> items) =>
      items.fold(0, (sum, item) => sum + item.protein);

  double _totalFat(List<MealRecord> items) =>
      items.fold(0, (sum, item) => sum + item.fat);

  IconData _icon(String type) {
    return switch (type) {
      'breakfast' => Icons.wb_sunny_outlined,
      'lunch' => Icons.restaurant_menu_rounded,
      'dinner' => Icons.nightlight_round,
      _ => Icons.icecream_outlined,
    };
  }

  String _label(String type) {
    return switch (type) {
      'breakfast' => '아침',
      'lunch' => '점심',
      'dinner' => '저녁',
      _ => '간식',
    };
  }
}

class _MealRecordRow extends StatelessWidget {
  const _MealRecordRow({
    required this.record,
    required this.showDivider,
    required this.onEdit,
    required this.onDelete,
  });

  final MealRecord record;
  final bool showDivider;
  final ValueChanged<MealRecord> onEdit;
  final ValueChanged<MealRecord> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            FoodImageView(
              imageRef: record.imagePath,
              size: 58,
              borderRadius: 18,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.foodName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        NutritionCalculator.kcal(record.kcal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_time(record.effectiveEatenAt)} · ${record.intakeGram.round()}g',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      _MacroPill(
                        label: '탄 ${record.carbs.toStringAsFixed(0)}g',
                        color: AppColors.macroCarb,
                      ),
                      _MacroPill(
                        label: '단 ${record.protein.toStringAsFixed(0)}g',
                        color: AppColors.macroProtein,
                      ),
                      _MacroPill(
                        label: '지 ${record.fat.toStringAsFixed(0)}g',
                        color: AppColors.macroFat,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            PopupMenuButton<MealRecordMenuAction>(
              tooltip: '기록 메뉴',
              position: PopupMenuPosition.under,
              onSelected: (action) {
                switch (action) {
                  case MealRecordMenuAction.edit:
                    onEdit(record);
                  case MealRecordMenuAction.delete:
                    onDelete(record);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: MealRecordMenuAction.edit,
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('수정'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: MealRecordMenuAction.delete,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: AppColors.coral),
                      SizedBox(width: 8),
                      Text(
                        '삭제',
                        style: TextStyle(color: AppColors.coral),
                      ),
                    ],
                  ),
                ),
              ],
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        if (showDivider) const Divider(height: 18, color: AppColors.divider),
      ],
    );
  }

  String _time(DateTime value) {
    return '${value.hour}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _MacroDot extends StatelessWidget {
  const _MacroDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
