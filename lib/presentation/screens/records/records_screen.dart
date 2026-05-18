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
    final groupedRecords = _groupRecords(filteredRecords);

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
        const SectionHeader(title: '식사별 기록'),
        if (filteredRecords.isEmpty)
          AppEmptyState(
            message: '선택한 조건에 기록된 식단이 없습니다. 첫 식사를 추가해보세요.',
            icon: Icons.event_busy,
            actionLabel: '식사 추가하기',
            onAction: widget.onAddMeal,
          )
        else
          ...groupedRecords.map(
            (group) => MealRecordGroupCard(
              mealType: group.mealType,
              records: group.records,
              onEdit: _showEditSheet,
              onDelete: _confirmDelete,
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

  List<_MealGroup> _groupRecords(List<MealRecord> records) {
    final byType = <String, List<MealRecord>>{};
    for (final record in records) {
      byType.putIfAbsent(record.mealType, () => []).add(record);
    }

    final order = _filter == 'all'
        ? const ['breakfast', 'lunch', 'dinner', 'snack']
        : [_filter];
    return [
      for (final type in order)
        if (byType[type] != null && byType[type]!.isNotEmpty)
          _MealGroup(mealType: type, records: byType[type]!),
    ];
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

  Future<void> _showEditSheet(MealRecord record) async {
    final rootContext = context;
    var selectedType = record.mealType;
    var selectedTime = record.effectiveEatenAt;
    final gramController =
        TextEditingController(text: record.intakeGram.toStringAsFixed(0));
    final kcalController =
        TextEditingController(text: record.kcal.toStringAsFixed(0));
    final carbController =
        TextEditingController(text: record.carbs.toStringAsFixed(0));
    final proteinController =
        TextEditingController(text: record.protein.toStringAsFixed(0));
    final fatController =
        TextEditingController(text: record.fat.toStringAsFixed(0));

    await showModalBottomSheet<void>(
      context: rootContext,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        var saving = false;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Future<void> pickDateTime() async {
              final date = await showDatePicker(
                context: modalContext,
                initialDate: selectedTime,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date == null || !modalContext.mounted) {
                return;
              }
              final time = await showTimePicker(
                context: modalContext,
                initialTime: TimeOfDay.fromDateTime(selectedTime),
              );
              if (time == null) {
                return;
              }
              setModalState(() {
                selectedTime = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            Future<void> save() async {
              final intakeGram = _parseNumber(gramController.text);
              final kcal = _parseNumber(kcalController.text);
              final carbs = _parseNumber(carbController.text);
              final protein = _parseNumber(proteinController.text);
              final fat = _parseNumber(fatController.text);
              if (intakeGram == null || intakeGram <= 0) {
                _showSnack('섭취량은 0g보다 크게 입력해 주세요.');
                return;
              }
              if ([kcal, carbs, protein, fat].any(
                (value) => value == null || value < 0,
              )) {
                _showSnack('칼로리와 탄단지는 0 이상 숫자로 입력해 주세요.');
                return;
              }

              final duration = record.effectiveFinishedAt
                  .difference(record.effectiveStartedAt);
              final safeDuration = duration.inMinutes <= 0
                  ? const Duration(minutes: 15)
                  : duration;
              final nextRecord = record.copyWith(
                mealType: selectedType,
                intakeGram: intakeGram,
                kcal: kcal,
                carbs: carbs,
                protein: protein,
                fat: fat,
                dateKey: AppDateUtils.dateKey(selectedTime),
                eatenAt: selectedTime,
                startedAt: selectedTime,
                finishedAt: selectedTime.add(safeDuration),
              );

              setModalState(() => saving = true);
              try {
                await AppScope.of(rootContext).updateRecord(nextRecord);
                if (!sheetContext.mounted) {
                  return;
                }
                Navigator.of(sheetContext).pop();
                if (mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('기록을 수정했습니다.')),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('수정에 실패했습니다.')),
                  );
                }
              } finally {
                if (modalContext.mounted) {
                  setModalState(() => saving = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('기록 수정', style: AppTextStyles.section),
                  const SizedBox(height: 6),
                  Text(record.foodName, style: AppTextStyles.caption),
                  const SizedBox(height: 18),
                  const Text(
                    '식사 종류',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MealTypeChip(
                        label: '아침',
                        value: 'breakfast',
                        selected: selectedType == 'breakfast',
                        onSelected: (value) =>
                            setModalState(() => selectedType = value),
                      ),
                      _MealTypeChip(
                        label: '점심',
                        value: 'lunch',
                        selected: selectedType == 'lunch',
                        onSelected: (value) =>
                            setModalState(() => selectedType = value),
                      ),
                      _MealTypeChip(
                        label: '저녁',
                        value: 'dinner',
                        selected: selectedType == 'dinner',
                        onSelected: (value) =>
                            setModalState(() => selectedType = value),
                      ),
                      _MealTypeChip(
                        label: '간식',
                        value: 'snack',
                        selected: selectedType == 'snack',
                        onSelected: (value) =>
                            setModalState(() => selectedType = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: pickDateTime,
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                      label: Text('먹은 시간 ${_formatDateTime(selectedTime)}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '영양 정보',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(
                          controller: gramController,
                          label: '섭취량',
                          suffix: 'g',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _NumberField(
                          controller: kcalController,
                          label: '칼로리',
                          suffix: 'kcal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(
                          controller: carbController,
                          label: '탄수화물',
                          suffix: 'g',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NumberField(
                          controller: proteinController,
                          label: '단백질',
                          suffix: 'g',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _NumberField(
                          controller: fatController,
                          label: '지방',
                          suffix: 'g',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '사진 분석값이 맞지 않으면 직접 보정할 수 있어요.',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: saving ? null : save,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(saving ? '저장 중...' : '수정 저장'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      gramController.dispose();
      kcalController.dispose();
      carbController.dispose();
      proteinController.dispose();
      fatController.dispose();
    });
  }

  Future<void> _confirmDelete(MealRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('기록 삭제'),
          content: Text('${record.foodName} 기록을 삭제할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _delete(record.id);
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

  String _formatDateTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '${value.month}/${value.day} $hh:$mm';
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MealGroup {
  const _MealGroup({required this.mealType, required this.records});

  final String mealType;
  final List<MealRecord> records;
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

class _MealTypeChip extends StatelessWidget {
  const _MealTypeChip({
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
    );
  }
}
