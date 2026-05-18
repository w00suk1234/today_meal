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
    final normalized = _normalize(query);
    if (normalized.isEmpty) {
      return foods.take(8).toList();
    }
    return foods
        .where((food) {
          final foodName = _normalize(food.name);
          final category = _normalize(food.category);
          return foodName.contains(normalized) ||
              normalized.contains(foodName) ||
              category.contains(normalized);
        })
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

    final normalized = _normalize(candidateName);
    for (final food in foods) {
      if (_normalize(food.name) == normalized) {
        return food;
      }
    }

    final aliases = <String, List<String>>{
      '공기밥': ['공깃밥'],
      '공깃밥': ['공깃밥'],
      '쌀밥': ['공깃밥'],
      '흰 쌀밥': ['공깃밥'],
      '잡곡밥': ['현미밥', '공깃밥'],
      '미역국': ['미역국'],
      '된장국': ['된장찌개'],
      '된장찌개': ['된장찌개'],
      '비빔밥': ['비빔밥'],
      '오징어비빔밥': ['오징어 비빔밥'],
      '오징어 비빔밥': ['오징어 비빔밥'],
      '쭈꾸미비빔밥': ['쭈꾸미 비빔밥'],
      '쭈꾸미 비빔밥': ['쭈꾸미 비빔밥'],
      '주꾸미비빔밥': ['쭈꾸미 비빔밥'],
      '주꾸미 비빔밥': ['쭈꾸미 비빔밥'],
      '쭈꾸미': ['쭈꾸미 비빔밥'],
      '주꾸미': ['쭈꾸미 비빔밥'],
      '고등어': ['고등어구이'],
      '오이': ['오이무침'],
      '김치': ['김치'],
      '버거': ['햄버거'],
      '햄버거': ['햄버거'],
      '치즈버거': ['치즈버거'],
      '피자': ['피자'],
      '감자튀김': ['감자튀김'],
      '파전': ['파전'],
      '해물파전': ['해물파전', '파전'],
      '김치전': ['김치전'],
      '전': ['파전', '김치전'],
      '밥': ['현미밥', '공깃밥'],
    };

    for (final entry in aliases.entries) {
      if (!normalized.contains(entry.key)) {
        continue;
      }
      for (final alias in entry.value) {
        for (final food in foods) {
          if (_normalize(food.name).contains(_normalize(alias))) {
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
      final foodName = _normalize(food.name);
      return normalized == foodName ||
          (normalized.length >= 3 && foodName.contains(normalized)) ||
          (foodName.length >= 3 && normalized.contains(foodName));
    }).toList();
    return strongMatches.length == 1 ? strongMatches.first : null;
  }

  String _normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }
}
