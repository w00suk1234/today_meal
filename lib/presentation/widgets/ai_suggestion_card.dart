import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'app_card.dart';
import 'primary_action_button.dart';

class AiSuggestionCard extends StatelessWidget {
  const AiSuggestionCard({
    required this.onPressed,
    this.title = 'AI로 음식 분석하기',
    this.subtitle = '사진을 기반으로 음식 후보를 추정해요',
    super.key,
  });

  final VoidCallback onPressed;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      color: AppColors.primaryDark,
      borderColor: AppColors.primaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.78))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: 'AI 분석 시작',
            icon: Icons.camera_alt_outlined,
            backgroundColor: AppColors.primary,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}
