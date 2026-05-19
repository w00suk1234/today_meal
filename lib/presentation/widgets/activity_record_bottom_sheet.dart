import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/activity_record.dart';

const _activityTypeOptions = [
  _ActivityOption(label: '걷기', value: 'walk'),
  _ActivityOption(label: '러닝', value: 'running'),
  _ActivityOption(label: '근력', value: 'strength'),
  _ActivityOption(label: '자전거', value: 'cycling'),
  _ActivityOption(label: '기타', value: 'etc'),
];

const _activityIntensityOptions = [
  _ActivityOption(label: '가볍게', value: 'light'),
  _ActivityOption(label: '보통', value: 'moderate'),
  _ActivityOption(label: '힘들게', value: 'hard'),
];

class _ActivityOption {
  const _ActivityOption({required this.label, required this.value});

  final String label;
  final String value;
}

Future<void> showActivityRecordBottomSheet({
  required BuildContext context,
  required DateTime date,
}) async {
  final rootContext = context;
  final controller = AppScope.of(rootContext);
  final dateKey = AppDateUtils.dateKey(date);
  var selectedType = 'walk';
  var selectedDuration = 30;
  var selectedIntensity = 'moderate';
  final customTypeNameController = TextEditingController();
  final customDurationController = TextEditingController();
  final memoController = TextEditingController();

  try {
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
            Future<void> save() async {
              final duration = selectedDuration == 0
                  ? int.tryParse(customDurationController.text.trim())
                  : selectedDuration;
              if (duration == null || duration <= 0 || duration > 600) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(content: Text('운동 시간은 1~600분 범위로 입력해 주세요.')),
                );
                return;
              }

              final now = DateTime.now();
              final customTypeName = customTypeNameController.text.trim();
              final record = ActivityRecord(
                id: 'activity_${now.microsecondsSinceEpoch}',
                dateKey: dateKey,
                type: selectedType,
                durationMinutes: duration,
                intensity: selectedIntensity,
                customTypeName:
                    selectedType == 'etc' && customTypeName.isNotEmpty
                        ? customTypeName
                        : null,
                memo: memoController.text.trim().isEmpty
                    ? null
                    : memoController.text.trim(),
                createdAt: now,
              );

              setModalState(() => saving = true);
              try {
                await controller.addActivity(record);
                if (!sheetContext.mounted) {
                  return;
                }
                Navigator.of(sheetContext).pop();
                if (rootContext.mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('운동을 기록했습니다.')),
                  );
                }
              } catch (_) {
                if (rootContext.mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('운동 기록 저장에 실패했습니다.')),
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
                left: 18,
                right: 18,
                top: 10,
                bottom: MediaQuery.viewInsetsOf(modalContext).bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            color: AppColors.primary,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '운동 기록하기',
                                style: AppTextStyles.section,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '오늘 활동량과 컨디션 참고용으로만 저장해요.',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SheetSectionTitle('운동 종류'),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in _activityTypeOptions)
                          _ActivityChoiceChip(
                            label: Text(option.label),
                            selected: selectedType == option.value,
                            onSelected: () => setModalState(
                              () => selectedType = option.value,
                            ),
                          ),
                      ],
                    ),
                    if (selectedType == 'etc') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: customTypeNameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: '운동 이름',
                            hintText: '스트레칭, 등산, 계단 오르기, 축구 등',
                            border: InputBorder.none,
                          ),
                          maxLength: 24,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const _SheetSectionTitle('운동 시간'),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in const [
                          (label: '10분', value: 10),
                          (label: '20분', value: 20),
                          (label: '30분', value: 30),
                          (label: '60분', value: 60),
                          (label: '직접 입력', value: 0),
                        ])
                          _ActivityChoiceChip(
                            label: Text(option.label),
                            selected: selectedDuration == option.value,
                            onSelected: () => setModalState(
                              () => selectedDuration = option.value,
                            ),
                          ),
                      ],
                    ),
                    if (selectedDuration == 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: customDurationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '운동 시간',
                            suffixText: '분',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const _SheetSectionTitle('강도'),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in _activityIntensityOptions)
                          _ActivityChoiceChip(
                            label: Text(option.label),
                            selected: selectedIntensity == option.value,
                            onSelected: () => setModalState(
                              () => selectedIntensity = option.value,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: memoController,
                        decoration: const InputDecoration(
                          labelText: '메모',
                          hintText: '선택 입력',
                          border: InputBorder.none,
                        ),
                        maxLength: 60,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              child: const Text('취소'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 46,
                            child: FilledButton.icon(
                              onPressed: saving ? null : save,
                              icon: Icon(
                                saving
                                    ? Icons.hourglass_empty_rounded
                                    : Icons.check_rounded,
                                size: 18,
                              ),
                              label: Text(saving ? '저장 중...' : '저장'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    customTypeNameController.dispose();
    customDurationController.dispose();
    memoController.dispose();
  }
}

class _SheetSectionTitle extends StatelessWidget {
  const _SheetSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ActivityChoiceChip extends StatelessWidget {
  const _ActivityChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Widget label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: label,
      selected: selected,
      showCheckmark: true,
      selectedColor: AppColors.primarySoft,
      backgroundColor: AppColors.cardWhite,
      checkmarkColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      side: BorderSide(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.35)
            : AppColors.border,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.primaryDark : AppColors.textSecondary,
        fontWeight: FontWeight.w800,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}
