import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/app_section_title.dart';
import 'widgets/meal_record_card.dart';
import 'widgets/record_day_selector.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final dateKey = AppDateUtils.dateKey(_selectedDate);
    final summary = controller.summaryFor(dateKey);
    final groups = {
      'breakfast': summary.records.where((record) => record.mealType == 'breakfast').toList(),
      'lunch': summary.records.where((record) => record.mealType == 'lunch').toList(),
      'dinner': summary.records.where((record) => record.mealType == 'dinner').toList(),
      'snack': summary.records.where((record) => record.mealType == 'snack').toList(),
    };

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const Text('식단 기록', style: AppTextStyles.title),
          const SizedBox(height: 14),
          RecordDaySelector(
            selectedDate: _selectedDate,
            onPrevious: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
            onNext: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
            onPick: _pickDate,
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text('선택 날짜 총 ${summary.totalKcal.round()}kcal', style: AppTextStyles.section),
            ),
          ),
          if (summary.records.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: AppEmptyState(message: '선택한 날짜에 기록된 식단이 없습니다.', icon: Icons.event_busy),
            )
          else
            for (final entry in groups.entries) ...[
              AppSectionTitle(_label(entry.key)),
              if (entry.value.isEmpty)
                const Text('기록 없음', style: AppTextStyles.muted)
              else
                ...entry.value.map(
                  (record) => MealRecordCard(
                    record: record,
                    onDelete: () => _delete(record.id),
                  ),
                ),
            ],
        ],
      ),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('기록을 삭제했습니다.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제에 실패했습니다.')));
      }
    }
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
