import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/health_calculator.dart';
import '../../../core/utils/meal_timing_analyzer.dart';
import '../../../data/models/activity_record.dart';
import '../../../data/models/ai_meal_coach_result.dart';
import '../../../data/models/meal_record.dart';
import '../../widgets/ai_suggestion_card.dart';
import '../../widgets/ai_today_plan_card.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/meal_status_card.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/section_header.dart';
import 'widgets/daily_summary_card.dart';
import 'widgets/macro_summary_card.dart';
import 'widgets/today_meal_list.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onAnalyzeFood,
    this.scrollController,
    super.key,
  });

  final VoidCallback onAnalyzeFood;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final summary = controller.todaySummary;
    final profile = controller.profile;
    final health = controller.healthProfile;
    final latestWeight = controller.latestWeightKg;
    final latestBmi = controller.latestBmi;
    final todayActivities = controller.activitiesFor(summary.dateKey);
    final skippedMealTypes = controller.skippedMealTypesFor(summary.dateKey);
    final timingMessages = MealTimingAnalyzer.generateFeedback(
      records: summary.records,
      sleepTime: health.sleepTime,
      skippedMealTypes: skippedMealTypes,
    );
    final timingMessage = timingMessages.first;
    final nickname = health.nickname.trim().isEmpty
        ? profile.nickname.trim()
        : health.nickname.trim();

    return AppScaffold(
      controller: scrollController,
      children: [
        AppPageHeader(
          title: AppConstants.appName,
          subtitle:
              '${AppDateUtils.koreanDate(DateTime.now())}\n${_greeting(nickname)}',
          icon: Icons.auto_awesome,
          trailing: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
        ),
        DailySummaryCard(summary: summary, targetKcal: profile.targetKcal),
        const SectionHeader(
          title: '영양 밸런스',
          subtitle: '오늘 기록된 탄단지 비율을 한눈에 확인해요',
        ),
        MacroSummaryCard(summary: summary, targetKcal: profile.targetKcal),
        const SizedBox(height: 4),
        const SectionHeader(title: '건강 지표'),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'BMI',
                value: latestBmi <= 0 ? '미입력' : latestBmi.toStringAsFixed(1),
                subtitle: '${HealthCalculator.getBmiCategory(latestBmi)} · 참고용',
                icon: Icons.monitor_heart_outlined,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricCard(
                title: '최근 몸무게',
                value: _weightText(latestWeight),
                subtitle: '목표 ${_weightText(health.targetWeightKg)}',
                icon: Icons.monitor_weight_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_outlined,
                      color: AppColors.orange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '하루 목표 ${health.targetKcal.round()}kcal · 참고용',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: () => _showWeightRecordSheet(context),
                  icon: const Icon(Icons.add_chart_rounded, size: 18),
                  label: const Text('오늘 몸무게 기록'),
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(
          title: '오늘 운동',
          subtitle: '섭취 칼로리에서 빼지 않고 활동 컨텍스트로만 참고해요',
        ),
        _TodayActivityCard(
          activities: todayActivities,
          exerciseRecommendation:
              controller.cachedTodayAiPlan?.exerciseRecommendation,
          recommendationLoading: controller.isGeneratingTodayAiPlan,
          onAdd: () => _showActivityRecordSheet(context),
          onDelete: (activity) => _confirmDeleteActivity(context, activity),
          onGenerateRecommendation: () => controller.generateTodayAiPlan(
            forceRefresh: controller.cachedTodayAiPlan != null &&
                controller.cachedTodayAiPlan?.exerciseRecommendation == null,
          ),
          onRefreshRecommendation: () =>
              controller.generateTodayAiPlan(forceRefresh: true),
        ),
        const SectionHeader(title: 'AI 오늘의 플랜'),
        AiTodayPlanCard(
          result: controller.cachedTodayAiPlan,
          loading: controller.isGeneratingTodayAiPlan,
          errorMessage: controller.todayAiPlanError,
          onGenerate: () => controller.generateTodayAiPlan(),
          onRegenerate: () =>
              controller.generateTodayAiPlan(forceRefresh: true),
        ),
        const SectionHeader(title: '식사 기록 상태'),
        MealStatusCard(
          items: [
            MealStatusItem(
              label: '아침',
              state: _mealStatusState(
                records: summary.records,
                skippedMealTypes: skippedMealTypes,
                mealType: 'breakfast',
              ),
              icon: Icons.wb_sunny_outlined,
              onTap: () => _showMealStatusSheet(context, 'breakfast'),
            ),
            MealStatusItem(
              label: '점심',
              state: _mealStatusState(
                records: summary.records,
                skippedMealTypes: skippedMealTypes,
                mealType: 'lunch',
              ),
              icon: Icons.restaurant_menu_rounded,
              onTap: () => _showMealStatusSheet(context, 'lunch'),
            ),
            MealStatusItem(
              label: '저녁',
              state: _mealStatusState(
                records: summary.records,
                skippedMealTypes: skippedMealTypes,
                mealType: 'dinner',
              ),
              icon: Icons.nightlight_round,
              onTap: () => _showMealStatusSheet(context, 'dinner'),
            ),
            MealStatusItem(
              label: '간식',
              state: _mealStatusState(
                records: summary.records,
                skippedMealTypes: skippedMealTypes,
                mealType: 'snack',
              ),
              icon: Icons.icecream_outlined,
              onTap: () => _showMealStatusSheet(context, 'snack'),
            ),
          ],
        ),
        const SectionHeader(title: '식사 시간 피드백'),
        AppCard(
          color: AppColors.creamBackground,
          borderColor: AppColors.orange.withValues(alpha: 0.18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tips_and_updates_outlined,
                  color: AppColors.orange,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(timingMessage, style: AppTextStyles.body)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AiSuggestionCard(onPressed: onAnalyzeFood),
        const SectionHeader(title: '오늘 식단'),
        TodayMealList(records: summary.records, onAddMeal: onAnalyzeFood),
        const SizedBox(height: 8),
        const Text(AppConstants.estimateNotice, style: AppTextStyles.caption),
      ],
    );
  }

  static bool _hasMeal(List<MealRecord> records, String type) {
    return records.any((record) => record.mealType == type);
  }

  static MealStatusState _mealStatusState({
    required List<MealRecord> records,
    required Set<String> skippedMealTypes,
    required String mealType,
  }) {
    if (_hasMeal(records, mealType)) {
      return MealStatusState.recorded;
    }
    if (skippedMealTypes.contains(mealType)) {
      return MealStatusState.skipped;
    }
    return MealStatusState.pending;
  }

  void _showMealStatusSheet(BuildContext context, String mealType) {
    final rootContext = context;
    final controller = AppScope.of(context);
    final summary = controller.todaySummary;
    final label = _mealTypeLabel(mealType);
    final hasMeal = _hasMeal(summary.records, mealType);
    final isSkipped = controller.isMealSkipped(summary.dateKey, mealType);

    showModalBottomSheet<void>(
      context: rootContext,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        Future<void> markSkipped() async {
          await controller.markMealSkipped(
            mealType,
            memo: '$label 건너뜀',
          );
          if (!sheetContext.mounted) {
            return;
          }
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(content: Text('$label을 굶음으로 기록했습니다.')),
          );
        }

        Future<void> clearSkipped() async {
          await controller.clearMealStatus(mealType);
          if (!sheetContext.mounted) {
            return;
          }
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(content: Text('$label 굶음 표시를 해제했습니다.')),
          );
        }

        void addMeal() {
          Navigator.of(sheetContext).pop();
          onAnalyzeFood();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$label 상태 기록', style: AppTextStyles.section),
              const SizedBox(height: 6),
              Text(
                hasMeal
                    ? '$label 음식 기록이 이미 있어요. 추가 음식이 있으면 식사 추가로 남겨주세요.'
                    : isSkipped
                        ? '$label은 굶음으로 기록되어 있어요. 칼로리에는 더하지 않고 AI가 식사 패턴으로 참고합니다.'
                        : '$label을 먹지 않았다면 굶음으로 남겨두고, 먹었다면 음식 기록을 추가해 주세요.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: addMeal,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('음식 기록하기'),
                ),
              ),
              if (!hasMeal) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: isSkipped
                      ? OutlinedButton.icon(
                          onPressed: clearSkipped,
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: const Text('굶음 표시 해제'),
                        )
                      : OutlinedButton.icon(
                          onPressed: markSkipped,
                          icon: const Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 18,
                          ),
                          label: const Text('굶었어요'),
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showWeightRecordSheet(BuildContext context) {
    final rootContext = context;
    final controller = AppScope.of(context);
    final weightController = TextEditingController(
      text: controller.latestWeightKg?.toStringAsFixed(1) ?? '',
    );
    final memoController = TextEditingController();

    showModalBottomSheet<void>(
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
              final weight = double.tryParse(
                weightController.text.trim().replaceAll(',', '.'),
              );
              if (weight == null || weight < 20 || weight > 300) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(content: Text('몸무게는 20~300kg 범위로 입력해 주세요.')),
                );
                return;
              }

              final delta = controller.weightChangeDeltaFromLatest(weight);
              if (delta != null && delta.abs() >= 5) {
                final confirmed = await _confirmLargeWeightChange(
                  modalContext,
                  delta,
                );
                if (!confirmed) {
                  return;
                }
              }

              setModalState(() => saving = true);
              try {
                await controller.saveTodayWeightRecord(
                  weight,
                  memo: memoController.text,
                );
                if (!sheetContext.mounted) {
                  return;
                }
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(content: Text('오늘 몸무게를 기록했습니다.')),
                );
              } catch (_) {
                if (rootContext.mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text('몸무게 기록 저장에 실패했습니다.')),
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('오늘 몸무게 기록', style: AppTextStyles.section),
                    const SizedBox(height: 6),
                    const Text(
                      'BMI와 변화 추이를 위한 참고용 기록입니다. 같은 날짜는 기존 기록을 수정해요.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '오늘 몸무게',
                        suffixText: 'kg',
                      ),
                      autofocus: true,
                      onSubmitted: (_) {
                        if (!saving) {
                          save();
                        }
                      },
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
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: saving ? null : save,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(saving ? '저장 중...' : '저장'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      weightController.dispose();
      memoController.dispose();
    });
  }

  void _showActivityRecordSheet(BuildContext context) {
    final rootContext = context;
    final controller = AppScope.of(context);
    var selectedType = 'walk';
    var selectedDuration = 30;
    var selectedIntensity = 'moderate';
    final customTypeNameController = TextEditingController();
    final customDurationController = TextEditingController();
    final memoController = TextEditingController();

    showModalBottomSheet<void>(
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
                dateKey: AppDateUtils.dateKey(now),
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
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(content: Text('오늘 운동을 기록했습니다.')),
                );
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
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('운동 기록하기', style: AppTextStyles.section),
                    const SizedBox(height: 6),
                    const Text(
                      '운동은 섭취 칼로리에서 빼지 않고 오늘 활동량 참고용으로만 저장해요.',
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
                                () => selectedType = option.value),
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
    ).whenComplete(() {
      customTypeNameController.dispose();
      customDurationController.dispose();
      memoController.dispose();
    });
  }

  Future<void> _confirmDeleteActivity(
    BuildContext context,
    ActivityRecord activity,
  ) async {
    final controller = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('운동 기록 삭제'),
          content: Text(
            '${_activityDisplayName(activity)} ${activity.durationMinutes}분 기록을 삭제할까요?',
          ),
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
    if (confirmed != true) {
      return;
    }
    try {
      await controller.removeActivity(activity.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('운동 기록을 삭제했습니다.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('운동 기록 삭제에 실패했습니다.')),
        );
      }
    }
  }

  static String _weightText(double? value) {
    if (value == null || value <= 0) {
      return '미입력';
    }
    return '${value.toStringAsFixed(1)}kg';
  }

  static String _mealTypeLabel(String type) {
    return switch (type) {
      'breakfast' => '아침',
      'lunch' => '점심',
      'dinner' => '저녁',
      _ => '간식',
    };
  }

  static String _activityTypeLabel(String type) {
    return switch (type) {
      'walk' => '걷기',
      'running' => '러닝',
      'strength' => '근력',
      'cycling' => '자전거',
      _ => '기타',
    };
  }

  static String _activityDisplayName(ActivityRecord activity) {
    if (activity.type == 'etc') {
      final customName = activity.customTypeName?.trim();
      return customName == null || customName.isEmpty ? '기타 운동' : customName;
    }
    return _activityTypeLabel(activity.type);
  }

  static String _activityIntensityLabel(String intensity) {
    return switch (intensity) {
      'light' => '가볍게',
      'hard' => '힘들게',
      _ => '보통',
    };
  }

  Future<bool> _confirmLargeWeightChange(
    BuildContext context,
    double delta,
  ) async {
    final direction = delta > 0 ? '높게' : '낮게';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('몸무게 변화가 커요'),
          content: Text(
            '최근 기록보다 ${delta.abs().toStringAsFixed(1)}kg $direction 입력했어요. 오타가 아니라면 그대로 저장할 수 있어요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('다시 입력'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('그대로 저장'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  String _greeting(String nickname) {
    if (nickname.isEmpty) {
      return '안녕하세요, 오늘 하루도 건강하게 시작해볼까요?';
    }
    return '$nickname님, 오늘 하루도 건강하게 시작해볼까요?';
  }
}

class _TodayActivityCard extends StatelessWidget {
  const _TodayActivityCard({
    required this.activities,
    required this.exerciseRecommendation,
    required this.recommendationLoading,
    required this.onAdd,
    required this.onDelete,
    required this.onGenerateRecommendation,
    required this.onRefreshRecommendation,
  });

  final List<ActivityRecord> activities;
  final AiExerciseRecommendation? exerciseRecommendation;
  final bool recommendationLoading;
  final VoidCallback onAdd;
  final ValueChanged<ActivityRecord> onDelete;
  final VoidCallback onGenerateRecommendation;
  final VoidCallback onRefreshRecommendation;

  @override
  Widget build(BuildContext context) {
    final totalMinutes = activities.fold<int>(
      0,
      (sum, activity) => sum + activity.durationMinutes,
    );
    final hasActivities = activities.isNotEmpty;
    final representative = hasActivities ? activities.first : null;
    final title = !hasActivities
        ? '오늘 운동 기록 없음'
        : activities.length == 1
            ? '${HomeScreen._activityDisplayName(representative!)} ${representative.durationMinutes}분 · ${HomeScreen._activityIntensityLabel(representative.intensity)}'
            : '오늘 운동 ${activities.length}개 · 총 $totalMinutes분';
    final subtitle = !hasActivities
        ? '가벼운 산책도 오늘 활동 컨텍스트로 남길 수 있어요.'
        : activities.length == 1
            ? 'AI가 오늘 활동량과 컨디션 참고용으로만 사용해요.'
            : '대표 운동 ${HomeScreen._activityDisplayName(representative!)} · 칼로리 차감은 하지 않아요.';

    return AppCard(
      padding: const EdgeInsets.all(16),
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
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (activities.length == 1)
                IconButton(
                  tooltip: '운동 기록 삭제',
                  onPressed: () => onDelete(representative!),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.textSecondary,
                ),
            ],
          ),
          if (activities.length > 1) ...[
            const SizedBox(height: 12),
            for (final activity in activities.take(3)) ...[
              _ActivityListTile(
                activity: activity,
                onDelete: () => onDelete(activity),
              ),
              if (activity != activities.take(3).last)
                const Divider(height: 14, color: AppColors.divider),
            ],
          ],
          const SizedBox(height: 14),
          _ExerciseRecommendationBlock(
            recommendation: exerciseRecommendation,
            loading: recommendationLoading,
            onGenerate: onGenerateRecommendation,
            onRefresh: onRefreshRecommendation,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('운동 기록하기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRecommendationBlock extends StatelessWidget {
  const _ExerciseRecommendationBlock({
    required this.recommendation,
    required this.loading,
    required this.onGenerate,
    required this.onRefresh,
  });

  final AiExerciseRecommendation? recommendation;
  final bool loading;
  final VoidCallback onGenerate;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final item = recommendation;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.lightGreenBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI 운동 추천',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (item == null) ...[
            const Text(
              '오늘 기록을 바탕으로 가벼운 운동을 추천받을 수 있어요.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                onPressed: loading ? null : onGenerate,
                icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                label: const Text('AI 추천 받기'),
              ),
            ),
          ] else ...[
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(item.reason, style: AppTextStyles.caption),
            const SizedBox(height: 5),
            Text(
              item.caution,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                onPressed: loading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('추천 새로고침'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityListTile extends StatelessWidget {
  const _ActivityListTile({
    required this.activity,
    required this.onDelete,
  });

  final ActivityRecord activity;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final memo = activity.memo?.trim();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${HomeScreen._activityDisplayName(activity)} ${activity.durationMinutes}분 · ${HomeScreen._activityIntensityLabel(activity.intensity)}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              if (memo != null && memo.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  memo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: '운동 기록 삭제',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}
