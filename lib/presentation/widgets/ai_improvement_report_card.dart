import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/ai_meal_coach_result.dart';
import 'app_card.dart';

class AiImprovementReportCard extends StatelessWidget {
  const AiImprovementReportCard({
    required this.result,
    required this.loading,
    required this.onGenerate,
    required this.onRegenerate,
    this.errorMessage,
    super.key,
  });

  final AiImprovementReportResult? result;
  final bool loading;
  final VoidCallback onGenerate;
  final VoidCallback onRegenerate;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final report = result;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      borderColor: AppColors.teal.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.psychology_alt_outlined,
                  color: AppColors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 개선 리포트',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 3),
                    Text('최근 기록을 요약해 제안해요', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading)
            const _LoadingBlock(label: '최근 기록을 바탕으로 리포트를 생성 중입니다.')
          else if (report == null)
            _EmptyBlock(
              message: '최근 기록을 바탕으로 AI 개선 리포트를 생성해 보세요.',
              buttonLabel: 'AI 리포트 생성',
              onPressed: onGenerate,
            )
          else ...[
            if (errorMessage != null) _NoticeText(errorMessage!),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScoreBadge(score: report.score),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.title, style: AppTextStyles.section),
                      const SizedBox(height: 6),
                      Text(report.summary, style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionList(
              title: '잘한 점',
              items: report.goodPoints,
              icon: Icons.thumb_up_alt_outlined,
              color: AppColors.primary,
            ),
            _SectionList(
              title: '개선할 점',
              items: report.improvementPoints,
              icon: Icons.tune_rounded,
              color: AppColors.orange,
            ),
            _SectionList(
              title: '반복 패턴',
              items: report.patterns,
              icon: Icons.timeline_rounded,
              color: AppColors.blue,
            ),
            _SectionList(
              title: '다음 실천',
              items: report.nextActions,
              icon: Icons.checklist_rounded,
              color: AppColors.teal,
            ),
            const SizedBox(height: 6),
            Text(report.caution, style: AppTextStyles.caption),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: onRegenerate,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('다시 생성'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final showScore = score > 0;
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            showScore ? '$score' : '-',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const Text('점', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          for (final item in items.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(child: Text(item, style: AppTextStyles.body)),
                ],
              ),
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
