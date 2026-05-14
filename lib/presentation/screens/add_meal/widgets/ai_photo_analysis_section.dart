import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/detected_food_candidate.dart';
import '../../../../data/models/food_item.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/primary_action_button.dart';
import '../../../widgets/section_header.dart';
import 'ai_food_candidate_list.dart';
import 'image_picker_card.dart';
import 'meal_type_selector.dart';
import 'nutrition_summary_card.dart';

class AiPhotoAnalysisSection extends StatelessWidget {
  const AiPhotoAnalysisSection({
    required this.imageBytes,
    required this.hasPickedImage,
    required this.analyzing,
    required this.saving,
    required this.analysisAttempted,
    required this.candidates,
    required this.foodsByCandidateId,
    required this.nutrition,
    required this.selectedMealType,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onAnalyze,
    required this.onSelectionChanged,
    required this.onPortionSelected,
    required this.onCustomGramChanged,
    required this.onMealTypeSelected,
    required this.onSaveCandidates,
    required this.onManualMatch,
    this.debugTitle,
    this.debugMessage,
    this.debugDetails,
    this.resultsKey,
    super.key,
  });

  final Uint8List? imageBytes;
  final bool hasPickedImage;
  final bool analyzing;
  final bool saving;
  final bool analysisAttempted;
  final List<DetectedFoodCandidate> candidates;
  final Map<String, FoodItem?> foodsByCandidateId;
  final NutritionDraft nutrition;
  final String selectedMealType;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback? onAnalyze;
  final void Function(String id, bool selected) onSelectionChanged;
  final void Function(String id, double intakeGram) onPortionSelected;
  final void Function(String id, String value) onCustomGramChanged;
  final ValueChanged<String> onMealTypeSelected;
  final VoidCallback onSaveCandidates;
  final VoidCallback onManualMatch;
  final String? debugTitle;
  final String? debugMessage;
  final String? debugDetails;
  final Key? resultsKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            title: 'AI 사진 분석', subtitle: '음식 후보를 먼저 찾고, 최종 기록은 직접 확인해요'),
        ImagePickerCard(
          imageBytes: imageBytes,
          onPickGallery: onPickGallery,
          onPickCamera: onPickCamera,
        ),
        const SizedBox(height: 12),
        PrimaryActionButton(
          label: !hasPickedImage
              ? '사진을 먼저 선택해 주세요'
              : analyzing
                  ? 'AI 분석 중...'
                  : 'AI 음식 분석 시작',
          icon: Icons.auto_awesome,
          onPressed: onAnalyze,
        ),
        const SizedBox(height: 8),
        const Text(AppConstants.estimateNotice,
            textAlign: TextAlign.center, style: AppTextStyles.caption),
        if (debugMessage != null) ...[
          const SizedBox(height: 12),
          _AiAnalysisDebugCard(
            title: debugTitle ?? 'AI 분석 연결 확인',
            message: debugMessage!,
            details: debugDetails,
            onManualMatch: onManualMatch,
          ),
        ],
        if (candidates.isNotEmpty)
          KeyedSubtree(
            key: resultsKey,
            child: _AiResults(
              candidates: candidates,
              foodsByCandidateId: foodsByCandidateId,
              nutrition: nutrition,
              selectedMealType: selectedMealType,
              saving: saving,
              onSelectionChanged: onSelectionChanged,
              onPortionSelected: onPortionSelected,
              onCustomGramChanged: onCustomGramChanged,
              onMealTypeSelected: onMealTypeSelected,
              onSaveCandidates: onSaveCandidates,
              onManualMatch: onManualMatch,
            ),
          )
        else if (analysisAttempted)
          KeyedSubtree(
            key: resultsKey,
            child: AppEmptyState(
              message: '음식 후보를 찾지 못했습니다. 직접 검색으로 추가해 주세요.',
              icon: Icons.search_off_outlined,
              actionLabel: '직접 검색으로 추가하기',
              onAction: onManualMatch,
            ),
          ),
      ],
    );
  }
}

class _AiAnalysisDebugCard extends StatelessWidget {
  const _AiAnalysisDebugCard({
    required this.title,
    required this.message,
    required this.onManualMatch,
    this.details,
  });

  final String title;
  final String message;
  final String? details;
  final VoidCallback onManualMatch;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.creamBackground,
      borderColor: AppColors.orange.withValues(alpha: 0.24),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  Icons.info_outline_rounded,
                  color: AppColors.orange,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(message, style: AppTextStyles.muted),
                  ],
                ),
              ),
            ],
          ),
          if (details != null && details!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                details!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onManualMatch,
            icon: const Icon(Icons.search_rounded, size: 17),
            label: const Text('직접 검색으로 추가하기'),
          ),
        ],
      ),
    );
  }
}

class _AiResults extends StatelessWidget {
  const _AiResults({
    required this.candidates,
    required this.foodsByCandidateId,
    required this.nutrition,
    required this.selectedMealType,
    required this.saving,
    required this.onSelectionChanged,
    required this.onPortionSelected,
    required this.onCustomGramChanged,
    required this.onMealTypeSelected,
    required this.onSaveCandidates,
    required this.onManualMatch,
  });

  final List<DetectedFoodCandidate> candidates;
  final Map<String, FoodItem?> foodsByCandidateId;
  final NutritionDraft nutrition;
  final String selectedMealType;
  final bool saving;
  final void Function(String id, bool selected) onSelectionChanged;
  final void Function(String id, double intakeGram) onPortionSelected;
  final void Function(String id, String value) onCustomGramChanged;
  final ValueChanged<String> onMealTypeSelected;
  final VoidCallback onSaveCandidates;
  final VoidCallback onManualMatch;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
            title: '분석 결과', subtitle: '음식명, 신뢰도, 섭취량, DB 매칭을 확인하세요'),
        AiFoodCandidateList(
          candidates: candidates,
          foodsByCandidateId: foodsByCandidateId,
          onSelectionChanged: onSelectionChanged,
          onPortionSelected: onPortionSelected,
          onCustomGramChanged: onCustomGramChanged,
          onMatchManually: onManualMatch,
        ),
        const SectionHeader(title: '영양소 요약'),
        NutritionSummaryCard(nutrition: nutrition),
        const SectionHeader(title: 'AI 기록 식사 유형'),
        MealTypeSelector(
            selectedType: selectedMealType, onSelected: onMealTypeSelected),
        const SizedBox(height: 14),
        PrimaryActionButton(
          label: saving ? '저장 중...' : '선택한 AI 후보 저장',
          icon: Icons.playlist_add_check,
          onPressed: saving ? null : onSaveCandidates,
        ),
      ],
    );
  }
}
