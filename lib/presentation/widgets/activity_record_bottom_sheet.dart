import 'package:flutter/material.dart';

import '../../app.dart';
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
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.viewInsetsOf(modalContext).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('운동 기록하기', style: AppTextStyles.section),
                    const SizedBox(height: 6),
                    const Text(
                      '섭취 칼로리에서 빼지 않고 오늘 활동 참고용으로만 저장해요.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '운동 종류',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in _activityTypeOptions)
                          ChoiceChip(
                            label: Text(option.label),
                            selected: selectedType == option.value,
                            onSelected: (_) => setModalState(
                              () => selectedType = option.value,
                            ),
                          ),
                      ],
                    ),
                    if (selectedType == 'etc') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customTypeNameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: '운동 이름',
                          hintText: '스트레칭, 등산, 계단 오르기, 축구 등',
                        ),
                        maxLength: 24,
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      '운동 시간',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
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
                          ChoiceChip(
                            label: Text(option.label),
                            selected: selectedDuration == option.value,
                            onSelected: (_) => setModalState(
                              () => selectedDuration = option.value,
                            ),
                          ),
                      ],
                    ),
                    if (selectedDuration == 0) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customDurationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '운동 시간',
                          suffixText: '분',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      '강도',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final option in _activityIntensityOptions)
                          ChoiceChip(
                            label: Text(option.label),
                            selected: selectedIntensity == option.value,
                            onSelected: (_) => setModalState(
                              () => selectedIntensity = option.value,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: memoController,
                      decoration: const InputDecoration(
                        labelText: '메모',
                        hintText: '선택 입력',
                      ),
                      maxLength: 60,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
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
                      ],
                    ),
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
