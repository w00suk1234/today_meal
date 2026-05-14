import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/nutrition_calculator.dart';
import '../../../data/models/meal_record.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/section_header.dart';
import 'widgets/meal_record_card.dart';
import 'widgets/record_day_selector.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({
    required this.onAddMeal,
    this.scrollController,
    super.key,
  });

  final VoidCallback onAddMeal;
  final ScrollController? scrollController;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final dateKey = AppDateUtils.dateKey(_selectedDate);
    final summary = controller.summaryFor(dateKey);
    final filteredRecords = _filtered(summary.records);

    return AppScaffold(
      controller: widget.scrollController,
      children: [
        const AppPageHeader(
          title: '식단 기록',
          subtitle: '날짜별 섭취량과 식사 패턴을 확인해요',
          icon: Icons.manage_search_rounded,
        ),
        RecordDaySelector(
          selectedDate: _selectedDate,
          onPrevious: () => setState(() =>
              _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
          onNext: () => setState(
              () => _selectedDate = _selectedDate.add(const Duration(days: 1))),
          onPick: _pickDate,
        ),
        const SectionHeader(title: '오늘의 영양 요약'),
        _RecordSummaryCard(
          totalKcal: summary.totalKcal,
          targetKcal: controller.profile.targetKcal,
          carbs: summary.totalCarbs,
          protein: summary.totalProtein,
          fat: summary.totalFat,
        ),
        const SectionHeader(title: '식사 타입'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
                label: '전체',
                value: 'all',
                selected: _filter == 'all',
                onSelected: _setFilter),
            _FilterChip(
                label: '아침',
                value: 'breakfast',
                selected: _filter == 'breakfast',
                onSelected: _setFilter),
            _FilterChip(
                label: '점심',
                value: 'lunch',
                selected: _filter == 'lunch',
                onSelected: _setFilter),
            _FilterChip(
                label: '저녁',
                value: 'dinner',
                selected: _filter == 'dinner',
                onSelected: _setFilter),
            _FilterChip(
                label: '간식',
                value: 'snack',
                selected: _filter == 'snack',
                onSelected: _setFilter),
          ],
        ),
        const SectionHeader(title: '식사 카드'),
        if (filteredRecords.isEmpty)
          AppEmptyState(
            message: '선택한 조건에 기록된 식단이 없습니다. 첫 식사를 추가해보세요.',
            icon: Icons.event_busy,
            actionLabel: '식사 추가하기',
            onAction: widget.onAddMeal,
          )
        else
          ...filteredRecords.map(
            (record) => MealRecordCard(
              record: record,
              onDelete: () => _delete(record.id),
            ),
          ),
      ],
    );
  }

  List<MealRecord> _filtered(List<MealRecord> records) {
    final next = _filter == 'all'
        ? records
        : records.where((record) => record.mealType == _filter).toList();
    return [...next]
      ..sort((a, b) => b.effectiveEatenAt.compareTo(a.effectiveEatenAt));
  }

  void _setFilter(String value) {
    setState(() => _filter = value);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await AppScope.of(context).deleteRecord(id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('기록을 삭제했습니다.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다.')));
      }
    }
  }
}

class _RecordSummaryCard extends StatelessWidget {
  const _RecordSummaryCard({
    required this.totalKcal,
    required this.targetKcal,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  final double totalKcal;
  final double targetKcal;
  final double carbs;
  final double protein;
  final double fat;

  @override
  Widget build(BuildContext context) {
    final percent =
        NutritionCalculator.calculateTargetPercent(totalKcal, targetKcal);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(totalKcal.round().toString(), style: AppTextStyles.metric),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('kcal', style: AppTextStyles.caption),
              ),
              const Spacer(),
              Text('${percent.round()}%',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: (percent / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryMacro(
                  label: '탄수화물', value: carbs, color: AppColors.macroCarb),
              _SummaryMacro(
                  label: '단백질', value: protein, color: AppColors.macroProtein),
              _SummaryMacro(label: '지방', value: fat, color: AppColors.macroFat),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMacro extends StatelessWidget {
  const _SummaryMacro(
      {required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 24,
              height: 5,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 7),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text('${value.toStringAsFixed(0)}g',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
