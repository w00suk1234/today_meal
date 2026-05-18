import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/meal_record.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/food_image_view.dart';

class TodayMealList extends StatelessWidget {
  const TodayMealList({required this.records, this.onAddMeal, super.key});

  final List<MealRecord> records;
  final VoidCallback? onAddMeal;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return AppEmptyState(
        message: '아직 기록된 식단이 없습니다. 첫 식사를 추가해보세요.',
        actionLabel: '식사 추가하기',
        onAction: onAddMeal,
      );
    }

    final groups = _groupRecords(records);
    return Column(
      children: [
        for (final group in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          _icon(group.mealType),
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_label(group.mealType)} 식사',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _summaryText(group),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        NutritionCalculator.kcal(group.totalKcal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final record in group.records)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          FoodImageView(
                            imageRef: record.imagePath,
                            size: 42,
                            borderRadius: 14,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.foodName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${record.intakeGram.round()}g · 탄 ${record.carbs.toStringAsFixed(0)}g · 단 ${record.protein.toStringAsFixed(0)}g',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption,
                                ),
                              ],
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
                    ),
                  Row(
                    children: [
                      _Dot(
                        color: AppColors.macroCarb,
                        label: '탄 ${group.totalCarbs.toStringAsFixed(0)}g',
                      ),
                      const SizedBox(width: 8),
                      _Dot(
                        color: AppColors.macroProtein,
                        label: '단 ${group.totalProtein.toStringAsFixed(0)}g',
                      ),
                      const SizedBox(width: 8),
                      _Dot(
                        color: AppColors.macroFat,
                        label: '지 ${group.totalFat.toStringAsFixed(0)}g',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<_MealGroup> _groupRecords(List<MealRecord> records) {
    final byType = <String, List<MealRecord>>{};
    for (final record in records) {
      byType.putIfAbsent(record.mealType, () => []).add(record);
    }

    final groups = <_MealGroup>[];
    for (final type in const ['breakfast', 'lunch', 'dinner', 'snack']) {
      final items = byType[type];
      if (items == null || items.isEmpty) {
        continue;
      }
      items.sort((a, b) => a.effectiveEatenAt.compareTo(b.effectiveEatenAt));
      groups.add(_MealGroup(mealType: type, records: items));
    }
    return groups;
  }

  String _summaryText(_MealGroup group) {
    final names = group.records.map((record) => record.foodName).toList();
    final joined = names.take(3).join(', ');
    final suffix = names.length > 3 ? ' 외 ${names.length - 3}개' : '';
    return '${group.records.length}개 메뉴 · $joined$suffix';
  }

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

class _MealGroup {
  const _MealGroup({required this.mealType, required this.records});

  final String mealType;
  final List<MealRecord> records;

  double get totalKcal => records.fold(0, (sum, item) => sum + item.kcal);
  double get totalCarbs => records.fold(0, (sum, item) => sum + item.carbs);
  double get totalProtein => records.fold(0, (sum, item) => sum + item.protein);
  double get totalFat => records.fold(0, (sum, item) => sum + item.fat);
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

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
