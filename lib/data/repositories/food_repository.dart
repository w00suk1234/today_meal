import 'dart:convert';

import 'package:flutter/services.dart';

import '../local/food_database.dart';
import '../models/food_item.dart';

class FoodRepository {
  Future<List<FoodItem>> loadFoods() async {
    try {
      final raw = await rootBundle.loadString('assets/data/food_db_kr_sample.json');
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) => FoodItem.fromJson(item as Map<String, dynamic>)).toList();
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
        .where((food) => food.name.toLowerCase().contains(normalized) || food.category.toLowerCase().contains(normalized))
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

  FoodItem? matchAiCandidate(List<FoodItem> foods, String candidateName, String? preferredFoodId) {
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
      '잡곡밥': ['현미밥', '공깃밥'],
      '된장국': ['된장찌개'],
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
    return searchResults.isEmpty ? null : searchResults.first;
  }
}
