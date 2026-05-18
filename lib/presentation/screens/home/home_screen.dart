import 'package:flutter/material.dart';

import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/health_calculator.dart';
import '../../../core/utils/meal_timing_analyzer.dart';
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
    final timingMessages = MealTimingAnalyzer.generateFeedback(
      records: summary.records,
      sleepTime: health.sleepTime,
    );
    final timingMessage = summary.records.isEmpty
        ? '오늘은 아직 식사 기록이 없습니다. 규칙적인 식사 패턴을 기록해보세요.'
        : timingMessages.first;
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
              done: _hasMeal(summary.records, 'breakfast'),
              icon: Icons.wb_sunny_outlined,
            ),
            MealStatusItem(
              label: '점심',
              done: _hasMeal(summary.records, 'lunch'),
              icon: Icons.restaurant_menu_rounded,
            ),
            MealStatusItem(
              label: '저녁',
              done: _hasMeal(summary.records, 'dinner'),
              icon: Icons.nightlight_round,
            ),
            MealStatusItem(
              label: '간식',
              done: _hasMeal(summary.records, 'snack'),
              icon: Icons.icecream_outlined,
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
            );
          },
        );
      },
    ).whenComplete(() {
      weightController.dispose();
      memoController.dispose();
    });
  }

  static String _weightText(double? value) {
    if (value == null || value <= 0) {
      return '미입력';
    }
    return '${value.toStringAsFixed(1)}kg';
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
