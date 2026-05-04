class DetectedFoodCandidate {
  const DetectedFoodCandidate({
    required this.id,
    required this.name,
    required this.confidenceLabel,
    required this.description,
    required this.estimatedPortionText,
    required this.selected,
    required this.intakeGram,
    this.matchedFoodItemId,
  });

  final String id;
  final String name;
  final String confidenceLabel;
  final String description;
  final String estimatedPortionText;
  final String? matchedFoodItemId;
  final bool selected;
  final double intakeGram;

  DetectedFoodCandidate copyWith({
    String? id,
    String? name,
    String? confidenceLabel,
    String? description,
    String? estimatedPortionText,
    String? matchedFoodItemId,
    bool? selected,
    double? intakeGram,
  }) {
    return DetectedFoodCandidate(
      id: id ?? this.id,
      name: name ?? this.name,
      confidenceLabel: confidenceLabel ?? this.confidenceLabel,
      description: description ?? this.description,
      estimatedPortionText: estimatedPortionText ?? this.estimatedPortionText,
      matchedFoodItemId: matchedFoodItemId ?? this.matchedFoodItemId,
      selected: selected ?? this.selected,
      intakeGram: intakeGram ?? this.intakeGram,
    );
  }
}
