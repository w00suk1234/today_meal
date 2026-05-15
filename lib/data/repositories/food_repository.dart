import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/utils/ai_candidate_review.dart';
import '../local/food_database.dart';
import '../models/food_item.dart';

class FoodRepository {
  Future<List<FoodItem>> loadFoods() async {
    try {
      final raw =
          await rootBundle.loadString('assets/data/food_db_kr_sample.json');
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return fallbackFoods;
    }
  }

  List<FoodItem> search(List<FoodItem> foods, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return foods.take(8).toList();
    }
    return foods
        .where((food) =>
            food.name.toLowerCase().contains(normalized) ||
            food.category.toLowerCase().contains(normalized))
        .take(20)
        .toList();
  }

  FoodItem? findById(List<FoodItem> foods, String? id) {
    if (id == null) {
      return null;
    }
    for (final food in foods) {
      if (food.id == id) {
        return food;
      }
    }
    return null;
  }

  FoodItem? matchAiCandidate(
      List<FoodItem> foods, String candidateName, String? preferredFoodId) {
    if (AiCandidateReview.isTooBroadOrShort(candidateName)) {
      return null;
    }

    final preferred = findById(foods, preferredFoodId);
    if (preferred != null) {
      return preferred;
    }

    final normalized = candidateName.trim().toLowerCase();
    for (final food in foods) {
      if (food.name.toLowerCase() == normalized) {
        return food;
      }
    }

    final aliases = <String, List<String>>{
      '공기밥': ['공깃밥'],
      '공깃밥': ['공깃밥'],
      '쌀밥': ['공깃밥'],
      '흰 쌀밥': ['공깃밥'],
      '잡곡밥': ['현미밥', '공깃밥'],
      '된장국': ['된장찌개'],
      '된장찌개': ['된장찌개'],
      '고등어': ['고등어구이'],
      '오이': ['오이무침'],
      '김치': ['김치'],
      '밥': ['현미밥', '공깃밥'],
    };

    for (final entry in aliases.entries) {
      if (!normalized.contains(entry.key)) {
        continue;
      }
      for (final alias in entry.value) {
        for (final food in foods) {
          if (food.name.contains(alias)) {
            return food;
          }
        }
      }
    }

    final searchResults = search(foods, candidateName);
    if (searchResults.length == 1) {
      return searchResults.first;
    }

    final strongMatches = foods.where((food) {
      final foodName = food.name.toLowerCase();
      return normalized == foodName ||
          (normalized.length >= 3 && foodName.contains(normalized)) ||
          (foodName.length >= 3 && normalized.contains(foodName));
    }).toList();
    return strongMatches.length == 1 ? strongMatches.first : null;
  }
}
