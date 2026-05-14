import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../data/models/detected_food_candidate.dart';
import '../../../../data/models/food_item.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/section_header.dart';

class AiFoodCandidateList extends StatelessWidget {
  const AiFoodCandidateList({
    required this.candidates,
    required this.foodsByCandidateId,
    required this.onSelectionChanged,
    required this.onPortionSelected,
    required this.onCustomGramChanged,
    this.onMatchManually,
    super.key,
  });

  final List<DetectedFoodCandidate> candidates;
  final Map<String, FoodItem?> foodsByCandidateId;
  final void Function(String id, bool selected) onSelectionChanged;
  final void Function(String id, double intakeGram) onPortionSelected;
  final void Function(String id, String value) onCustomGramChanged;
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
    this.onMatchManually,
  });

  final DetectedFoodCandidate candidate;
  final FoodItem? matchedFood;
  final ValueChanged<bool> onSelectionChanged;
  final ValueChanged<double> onPortionSelected;
  final ValueChanged<String> onCustomGramChanged;
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: widget.candidate.selected,
                  onChanged: (value) =>
                      widget.onSelectionChanged(value ?? false),
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.candidate.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(widget.candidate.description,
                          style: AppTextStyles.muted),
                    ],
                  ),
                ),
                _ConfidenceBadge(label: widget.candidate.confidenceLabel),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppTag(
                    label: widget.candidate.estimatedPortionText,
                    color: AppColors.blue,
                    icon: Icons.scale_outlined),
                AppTag(
                  label: food == null ? 'DB 매칭 필요' : 'DB 매칭 완료',
                  color: food == null ? AppColors.orange : AppColors.primary,
                  icon: food == null
                      ? Icons.search_off_outlined
                      : Icons.verified_outlined,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (food == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('음식 DB에서 정확한 항목을 찾지 못했습니다. 직접 검색으로 매칭해 주세요.',
                      style: AppTextStyles.muted),
                  if (widget.onMatchManually != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: widget.onMatchManually,
                      icon: const Icon(Icons.search_rounded, size: 17),
                      label: const Text('직접 검색으로 매칭하기'),
                    ),
                  ],
                ],
              )
            else
              Text(
                  'DB 매칭: ${food.name} · 1인분 ${food.servingGram.round()}g · ${food.kcalPer100g.round()}kcal/100g',
                  style: AppTextStyles.caption),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('0.5인분'),
                  selected: !_customGram &&
                      _sameGram(widget.candidate.intakeGram, baseGram * 0.5),
                  onSelected: (_) => _selectPortion(baseGram * 0.5),
                ),
                ChoiceChip(
                  label: const Text('1인분'),
                  selected: !_customGram &&
                      _sameGram(widget.candidate.intakeGram, baseGram),
                  onSelected: (_) => _selectPortion(baseGram),
                ),
                ChoiceChip(
                  label: const Text('1.5인분'),
                  selected: !_customGram &&
                      _sameGram(widget.candidate.intakeGram, baseGram * 1.5),
                  onSelected: (_) => _selectPortion(baseGram * 1.5),
                ),
                ChoiceChip(
                  label: const Text('직접 g 입력'),
                  selected: _customGram,
                  onSelected: (_) => setState(() => _customGram = true),
                ),
              ],
            ),
            if (_customGram) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: '섭취량', suffixText: 'g'),
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

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      '높음' => const Color(0xFF1F9D7A),
      '보통' => const Color(0xFFE98A15),
      _ => const Color(0xFF6B7780),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('신뢰도 $label',
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
