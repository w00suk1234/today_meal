import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/detected_food_candidate.dart';
import '../../../../data/models/food_item.dart';
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
    required this.hasCachedAnalysisForImage,
    required this.onForceAnalyze,
    required this.onSelectionChanged,
    required this.onPortionSelected,
    required this.onCustomGramChanged,
    required this.onMealTypeSelected,
    required this.onSaveCandidates,
    required this.onManualMatch,
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
  final bool hasCachedAnalysisForImage;
  final VoidCallback? onForceAnalyze;
  final void Function(String id, bool selected) onSelectionChanged;
  final void Function(String id, double intakeGram) onPortionSelected;
  final void Function(String id, String value) onCustomGramChanged;
  final ValueChanged<String> onMealTypeSelected;
  final VoidCallback onSaveCandidates;
  final VoidCallback onManualMatch;
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
                  : hasCachedAnalysisForImage
                      ? '이전 분석 결과 사용'
                      : 'AI 음식 분석 시작',
          icon: Icons.auto_awesome,
          onPressed: onAnalyze,
        ),
        if (hasCachedAnalysisForImage && !analyzing) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton.icon(
              onPressed: onForceAnalyze,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('다시 분석하기'),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "모델 변경 후 새 결과를 보려면 '다시 분석하기'를 눌러주세요.",
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
        const SizedBox(height: 8),
        const Text(AppConstants.estimateNotice,
            textAlign: TextAlign.center, style: AppTextStyles.caption),
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
          title: '분석 결과',
          subtitle: 'AI가 찾은 후보입니다. 실제 음식명과 섭취량을 확인해 주세요.',
        ),
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
