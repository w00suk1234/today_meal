import 'package:flutter/material.dart';

class PortionSelector extends StatelessWidget {
  const PortionSelector({
    required this.selectedMultiplier,
    required this.customGram,
    required this.gramController,
    required this.onMultiplierSelected,
    required this.onCustomSelected,
    required this.onCustomGramChanged,
    super.key,
  });

  final double selectedMultiplier;
  final bool customGram;
  final TextEditingController gramController;
  final ValueChanged<double> onMultiplierSelected;
  final VoidCallback onCustomSelected;
  final VoidCallback onCustomGramChanged;

  @override
  Widget build(BuildContext context) {
    const options = [0.5, 1.0, 1.5, 2.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                label: Text('${option.toStringAsFixed(option == option.roundToDouble() ? 0 : 1)}인분'),
                selected: !customGram && selectedMultiplier == option,
                onSelected: (_) => onMultiplierSelected(option),
              ),
            ChoiceChip(
              label: const Text('직접 입력'),
              selected: customGram,
              onSelected: (_) => onCustomSelected(),
            ),
          ],
        ),
        if (customGram) ...[
          const SizedBox(height: 12),
          TextField(
            controller: gramController,
            onChanged: (_) => onCustomGramChanged(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(suffixText: 'g', labelText: '섭취량'),
          ),
        ],
      ],
    );
  }
}
