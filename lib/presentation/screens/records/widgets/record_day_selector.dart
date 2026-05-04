import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';

class RecordDaySelector extends StatelessWidget {
  const RecordDaySelector({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
    super.key,
  });

  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: TextButton(
                onPressed: onPick,
                child: Text(AppDateUtils.koreanDate(selectedDate), textAlign: TextAlign.center),
              ),
            ),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
          ],
        ),
      ),
    );
  }
}
