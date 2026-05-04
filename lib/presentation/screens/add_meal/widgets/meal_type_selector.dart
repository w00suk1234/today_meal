import 'package:flutter/material.dart';

class MealTypeSelector extends StatelessWidget {
  const MealTypeSelector({required this.selectedType, required this.onSelected, super.key});

  final String selectedType;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const options = {
      'breakfast': '아침',
      'lunch': '점심',
      'dinner': '저녁',
      'snack': '간식',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        return ChoiceChip(
          label: Text(entry.value),
          selected: selectedType == entry.key,
          onSelected: (_) => onSelected(entry.key),
        );
      }).toList(),
    );
  }
}
