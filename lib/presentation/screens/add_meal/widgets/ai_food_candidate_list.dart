import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/ai_candidate_review.dart';
import '../../../../data/models/detected_food_candidate.dart';
import '../../../../data/models/food_item.dart';
import '../../../widgets/app_card.dart';

class AiFoodCandidateList extends StatelessWidget {
  const AiFoodCandidateList({
    required this.candidates,
    required this.foodsByCandidateId,
    required this.onSelectionChanged,
    required this.onPortionSelected,
    required this.onCustomGramChanged,
    required this.onSuggestionSelected,
    this.onMatchManually,
    super.key,
  });

  final List<DetectedFoodCandidate> candidates;
  final Map<String, FoodItem?> foodsByCandidateId;
  final void Function(String id, bool selected) onSelectionChanged;
  final void Function(String id, double intakeGram) onPortionSelected;
  final void Function(String id, String value) onCustomGramChanged;
  final ValueChanged<String> onSuggestionSelected;
  final VoidCallback? onMatchManually;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final candidate in candidates)
          _AiFoodCandidateCard(
            candidate: candidate,
            matchedFood: foodsByCandidateId[candidate.id],
            onSelectionChanged: (selected) =>
                onSelectionChanged(candidate.id, selected),
            onPortionSelected: (grams) =>
                onPortionSelected(candidate.id, grams),
            onCustomGramChanged: (value) =>
                onCustomGramChanged(candidate.id, value),
            onSuggestionSelected: onSuggestionSelected,
            onMatchManually: onMatchManually,
          ),
        const SizedBox(height: 6),
        const Text(
          'AI 분석 결과는 참고용입니다. 실제 음식명과 섭취량을 확인한 뒤 저장해 주세요.',
          style: AppTextStyles.muted,
        ),
      ],
    );
  }
}

class _AiFoodCandidateCard extends StatefulWidget {
  const _AiFoodCandidateCard({
    required this.candidate,
    required this.matchedFood,
    required this.onSelectionChanged,
    required this.onPortionSelected,
    required this.onCustomGramChanged,
    required this.onSuggestionSelected,
    this.onMatchManually,
  });

  final DetectedFoodCandidate candidate;
  final FoodItem? matchedFood;
  final ValueChanged<bool> onSelectionChanged;
  final ValueChanged<double> onPortionSelected;
  final ValueChanged<String> onCustomGramChanged;
  final ValueChanged<String> onSuggestionSelected;
  final VoidCallback? onMatchManually;

  @override
  State<_AiFoodCandidateCard> createState() => _AiFoodCandidateCardState();
}

class _AiFoodCandidateCardState extends State<_AiFoodCandidateCard> {
  late final TextEditingController _controller;
  bool _customGram = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.candidate.intakeGram.round().toString());
  }

  @override
  void didUpdateWidget(covariant _AiFoodCandidateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candidate.intakeGram != widget.candidate.intakeGram &&
        !_customGram) {
      _controller.text = widget.candidate.intakeGram.round().toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.matchedFood;
    final baseGram = food?.servingGram ?? widget.candidate.intakeGram;
    final selected = widget.candidate.selected;
    final needsReview = AiCandidateReview.needsReview(
      name: widget.candidate.name,
      confidenceLabel: widget.candidate.confidenceLabel,
      hasMatchedFood: food != null,
    );
    final suggestions =
        AiCandidateReview.suggestionsFor(widget.candidate.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        color: selected && !needsReview
            ? const Color(0xFFFBFFFC)
            : AppColors.cardWhite,
        borderColor: selected && !needsReview
            ? AppColors.primary.withValues(alpha: 0.24)
            : needsReview
                ? AppColors.orange.withValues(alpha: 0.22)
                : AppColors.border,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectionToggle(
                  selected: selected,
                  needsReview: needsReview,
                  lowConfidence: AiCandidateReview.isLowConfidence(
                    widget.candidate.confidenceLabel,
                  ),
                  onTap: () => widget.onSelectionChanged(!selected),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.candidate.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.candidate.description,
                        style: AppTextStyles.muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ConfidenceBadge(label: widget.candidate.confidenceLabel),
              ],
            ),
            const SizedBox(height: 14),
            _InfoTile(
              label: '예상 섭취량',
              value: widget.candidate.estimatedPortionText,
              icon: Icons.scale_outlined,
              color: AppColors.blue,
            ),
            const SizedBox(height: 10),
            if (needsReview)
              _NeedsReviewPanel(
                title: AiCandidateReview.reviewTitle(widget.candidate.name),
                description:
                    AiCandidateReview.reviewDescription(widget.candidate.name),
                suggestions: suggestions,
                onSuggestionSelected: widget.onSuggestionSelected,
                onMatchManually: widget.onMatchManually,
              )
            else if (widget.onMatchManually != null)
              _ManualEditButton(onTap: widget.onMatchManually!),
            const SizedBox(height: 14),
            const Text(
              '섭취량 선택',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PortionChoice(
                  label: const Text('0.5인분'),
                  selected: !_customGram &&
                      _sameGram(widget.candidate.intakeGram, baseGram * 0.5),
                  onTap: () => _selectPortion(baseGram * 0.5),
                ),
                _PortionChoice(
                  label: const Text('1인분'),
                  selected: !_customGram &&
                      _sameGram(widget.candidate.intakeGram, baseGram),
                  onTap: () => _selectPortion(baseGram),
                ),
                _PortionChoice(
                  label: const Text('1.5인분'),
                  selected: !_customGram &&
                      _sameGram(widget.candidate.intakeGram, baseGram * 1.5),
                  onTap: () => _selectPortion(baseGram * 1.5),
                ),
                _PortionChoice(
                  label: const Text('직접 g 입력'),
                  selected: _customGram,
                  onTap: () => setState(() => _customGram = true),
                ),
              ],
            ),
            if (_customGram) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '직접 입력',
                  suffixText: 'g',
                ),
                onChanged: widget.onCustomGramChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectPortion(double grams) {
    setState(() {
      _customGram = false;
      _controller.text = grams.round().toString();
    });
    widget.onPortionSelected(grams);
  }

  bool _sameGram(double a, double b) => (a - b).abs() < 0.1;
}

class _SelectionToggle extends StatelessWidget {
  const _SelectionToggle({
    required this.selected,
    required this.needsReview,
    required this.lowConfidence,
    required this.onTap,
  });

  final bool selected;
  final bool needsReview;
  final bool lowConfidence;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: needsReview
                ? AppColors.orange.withValues(alpha: selected ? 0.16 : 0.1)
                : selected
                    ? AppColors.primary
                    : AppColors.lightGreenBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: needsReview
                  ? AppColors.orange.withValues(alpha: 0.4)
                  : selected
                      ? AppColors.primary
                      : AppColors.border,
            ),
          ),
          child: Icon(
            needsReview
                ? (lowConfidence
                    ? Icons.help_outline_rounded
                    : Icons.manage_search_rounded)
                : selected
                    ? Icons.check_rounded
                    : Icons.add_rounded,
            color: needsReview
                ? AppColors.orange
                : selected
                    ? Colors.white
                    : AppColors.primary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsReviewPanel extends StatelessWidget {
  const _NeedsReviewPanel({
    required this.title,
    required this.description,
    required this.suggestions,
    required this.onSuggestionSelected,
    this.onMatchManually,
  });

  final String title;
  final String description;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestionSelected;
  final VoidCallback? onMatchManually;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.orange;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.manage_search_rounded, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '영양 계산 전 확인 필요',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(description, style: AppTextStyles.caption),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final suggestion in suggestions)
                        _SuggestionChip(
                          label: suggestion,
                          onTap: () => onSuggestionSelected(suggestion),
                        ),
                    ],
                  ),
                ],
                if (onMatchManually != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: TextButton.icon(
                      onPressed: onMatchManually,
                      icon: const Icon(Icons.search_rounded, size: 16),
                      label: const Text('직접 검색으로 수정'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_rounded, size: 14, color: AppColors.orange),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualEditButton extends StatelessWidget {
  const _ManualEditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 40,
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.search_rounded, size: 16),
          label: const Text('직접 검색으로 수정'),
        ),
      ),
    );
  }
}

class _PortionChoice extends StatelessWidget {
  const _PortionChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primarySoft : AppColors.lightGreenBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.22)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 5),
            ],
            DefaultTextStyle(
              style: TextStyle(
                color:
                    selected ? AppColors.primaryDark : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
              child: label,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      '높음' => const Color(0xFF1F9D7A),
      '보통' => const Color(0xFFE98A15),
      _ => const Color(0xFF8A6D63),
    };
    final text = switch (label) {
      '높음' => '비교적 확실',
      '보통' => '확인이 필요해요',
      _ => '직접 확인 필요',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
