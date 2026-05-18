import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/ai_meal_coach_result.dart';
import 'app_card.dart';

class AiTodayPlanCard extends StatelessWidget {
  const AiTodayPlanCard({
    required this.result,
    required this.loading,
    required this.onGenerate,
    required this.onRegenerate,
    this.errorMessage,
    super.key,
  });

  final AiTodayPlanResult? result;
  final bool loading;
  final VoidCallback onGenerate;
  final VoidCallback onRegenerate;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final plan = result;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      borderColor: AppColors.blue.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.blue,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 오늘의 플랜',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text('버튼을 누를 때만 생성돼요', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading)
            const _LoadingBlock(label: '오늘 기록을 바탕으로 플랜을 생성 중입니다.')
          else if (plan == null)
            _EmptyBlock(
              message: '오늘 기록과 건강 정보를 바탕으로 AI 플랜을 받아보세요.',
              buttonLabel: 'AI 플랜 받기',
              onPressed: onGenerate,
            )
          else ...[
            if (errorMessage != null) _NoticeText(errorMessage!),
            Text(plan.title, style: AppTextStyles.section),
            const SizedBox(height: 7),
            Text(plan.summary, style: AppTextStyles.body),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _Chip(label: plan.statusLabel, color: AppColors.blue),
                for (final item in plan.recommendedFocus.take(3))
                  _Chip(label: item, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 14),
            _SuggestionBlock(plan.nextMealSuggestion),
            const SizedBox(height: 12),
            for (final mission in plan.missions.take(2))
              _BulletText(text: mission, icon: Icons.check_circle_outline),
            const SizedBox(height: 8),
            Text(plan.caution, style: AppTextStyles.caption),
            const SizedBox(height: 12),
            _ActionRow(primaryLabel: '다시 생성', onPrimary: onRegenerate),
          ],
        ],
      ),
    );
  }
}

class _SuggestionBlock extends StatelessWidget {
  const _SuggestionBlock(this.suggestion);

  final AiNextMealSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
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
          Text(
            suggestion.title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 5),
          Text(suggestion.reason, style: AppTextStyles.caption),
          const SizedBox(height: 9),
          Text(
            '약 ${suggestion.estimatedKcal}kcal · 단백질 ${suggestion.proteinG}g',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.body)),
      ],
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: AppTextStyles.body),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(buttonLabel),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.primaryLabel, required this.onPrimary});

  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onPrimary,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(primaryLabel),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 17),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _NoticeText extends StatelessWidget {
  const _NoticeText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(color: AppColors.orange),
      ),
    );
  }
}
