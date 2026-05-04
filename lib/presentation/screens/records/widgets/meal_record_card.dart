import 'package:flutter/material.dart';

import '../../../../core/utils/nutrition_calculator.dart';
import '../../../../data/models/meal_record.dart';
import '../../../widgets/food_image_view.dart';

class MealRecordCard extends StatelessWidget {
  const MealRecordCard({required this.record, required this.onDelete, super.key});

  final MealRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              FoodImageView(imageRef: record.imagePath, size: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.foodName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${record.intakeGram.round()}g · ${NutritionCalculator.kcal(record.kcal)} · ${_time(record.effectiveEatenAt)}'),
                    const SizedBox(height: 4),
                    Text(
                      '탄 ${record.carbs.toStringAsFixed(1)}g · 단 ${record.protein.toStringAsFixed(1)}g · 지 ${record.fat.toStringAsFixed(1)}g',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7780)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '삭제',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _time(DateTime value) {
    return '${value.hour}:${value.minute.toString().padLeft(2, '0')}';
  }
}
