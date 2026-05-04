import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/nutrition_calculator.dart';
import '../../../data/models/detected_food_candidate.dart';
import '../../../data/models/food_item.dart';
import '../../../data/models/meal_record.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_section_title.dart';
import 'widgets/ai_food_candidate_list.dart';
import 'widgets/food_result_list.dart';
import 'widgets/food_search_box.dart';
import 'widgets/image_picker_card.dart';
import 'widgets/meal_type_selector.dart';
import 'widgets/portion_selector.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({required this.onSaved, super.key});

  final VoidCallback onSaved;

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _picker = ImagePicker();
  final _gramController = TextEditingController();
  String _query = '';
  FoodItem? _selectedFood;
  double _portionMultiplier = 1;
  bool _customGram = false;
  String _mealType = 'lunch';
  DateTime _eatenAt = DateTime.now();
  DateTime _startedAt = DateTime.now();
  DateTime _finishedAt = DateTime.now().add(const Duration(minutes: 15));
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  String? _imageDataUrl;
  bool _saving = false;
  bool _analyzing = false;
  List<DetectedFoodCandidate> _aiCandidates = [];

  @override
  void dispose() {
    _gramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final results = controller.foodRepository.search(controller.foods, _query);
    final selected = _selectedFood;
    final grams = _currentGrams(selected);
    final matchedFoods = {
      for (final candidate in _aiCandidates)
        candidate.id: controller.foodRepository.matchAiCandidate(
          controller.foods,
          candidate.name,
          candidate.matchedFoodItemId,
        ),
    };

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const Text('식단 추가', style: AppTextStyles.title),
          const SizedBox(height: 4),
          const Text('사진 기반 AI 후보는 참고용이며 최종 영양 계산은 로컬 음식 DB로 처리합니다.', style: AppTextStyles.muted),
          const AppSectionTitle('사진'),
          ImagePickerCard(
            imageBytes: _imageBytes,
            onPickGallery: () => _pickImage(ImageSource.gallery),
            onPickCamera: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: _analyzing ? 'AI 분석 중' : 'AI로 사진 속 음식 찾기',
            icon: Icons.auto_awesome,
            onPressed: _analyzing ? null : _detectFoodsWithAi,
          ),
          if (_aiCandidates.isNotEmpty) ...[
            const AppSectionTitle('AI가 찾은 음식 후보'),
            AiFoodCandidateList(
              candidates: _aiCandidates,
              foodsByCandidateId: matchedFoods,
              onSelectionChanged: _updateCandidateSelection,
              onPortionSelected: _updateCandidateGram,
              onCustomGramChanged: _updateCandidateCustomGram,
            ),
            const AppSectionTitle('AI 후보 식사 유형'),
            MealTypeSelector(selectedType: _mealType, onSelected: (type) => setState(() => _mealType = type)),
            const SizedBox(height: 14),
            AppPrimaryButton(
              label: _saving ? '저장 중' : '선택한 음식 저장',
              icon: Icons.playlist_add_check,
              onPressed: _saving ? null : () => _saveAiCandidates(matchedFoods),
            ),
          ],
          const AppSectionTitle('식사 시간'),
          _MealTimeCard(
            eatenAt: _eatenAt,
            startedAt: _startedAt,
            finishedAt: _finishedAt,
            onPickEatenAt: () => _pickDateTime(
              initial: _eatenAt,
              onPicked: (value) => setState(() {
                _eatenAt = value;
                _startedAt = value;
                if (!_finishedAt.isAfter(_startedAt)) {
                  _finishedAt = _startedAt.add(const Duration(minutes: 15));
                }
              }),
            ),
            onPickStartedAt: () => _pickDateTime(
              initial: _startedAt,
              onPicked: (value) => setState(() {
                _startedAt = value;
                if (!_finishedAt.isAfter(_startedAt)) {
                  _finishedAt = _startedAt.add(const Duration(minutes: 15));
                }
              }),
            ),
            onPickFinishedAt: () => _pickDateTime(
              initial: _finishedAt,
              onPicked: (value) => setState(() => _finishedAt = value),
            ),
          ),
          const AppSectionTitle('음식 검색'),
          FoodSearchBox(onChanged: (value) => setState(() => _query = value)),
          const SizedBox(height: 10),
          FoodResultList(
            foods: results,
            selectedFood: selected,
            onSelected: (food) {
              setState(() {
                _selectedFood = food;
                _customGram = false;
                _portionMultiplier = 1;
                _gramController.text = food.servingGram.round().toString();
              });
            },
          ),
          if (selected != null) ...[
            const AppSectionTitle('선택한 음식'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selected.name, style: AppTextStyles.section),
                    const SizedBox(height: 8),
                    Text('기본 1인분 ${selected.servingGram.round()}g · 100g당 ${selected.kcalPer100g.round()}kcal'),
                    const SizedBox(height: 6),
                    Text(
                      '탄 ${selected.carbPer100g}g · 단 ${selected.proteinPer100g}g · 지 ${selected.fatPer100g}g / 100g',
                      style: AppTextStyles.muted,
                    ),
                  ],
                ),
              ),
            ),
            const AppSectionTitle('섭취량'),
            PortionSelector(
              selectedMultiplier: _portionMultiplier,
              customGram: _customGram,
              gramController: _gramController,
              onMultiplierSelected: (value) => setState(() {
                _customGram = false;
                _portionMultiplier = value;
              }),
              onCustomSelected: () => setState(() {
                _customGram = true;
                _gramController.text = grams.round().toString();
              }),
              onCustomGramChanged: () => setState(() {}),
            ),
            const AppSectionTitle('식사 유형'),
            MealTypeSelector(selectedType: _mealType, onSelected: (type) => setState(() => _mealType = type)),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('예상 섭취량 ${grams.round()}g · ${NutritionCalculator.kcal(NutritionCalculator.calculateKcal(selected, grams))}'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: _saving ? '저장 중' : '저장',
            icon: Icons.check,
            onPressed: _saving ? null : _saveManualMeal,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 72, maxWidth: 900);
      if (file == null) {
        _showSnack('이미지 선택이 취소되었습니다.');
        return;
      }
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImage = file;
        _imageBytes = bytes;
        _imageDataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        _aiCandidates = [];
      });
    } catch (_) {
      _showSnack(source == ImageSource.camera ? '카메라를 사용할 수 없습니다.' : '이미지를 불러오지 못했습니다.');
    }
  }

  Future<void> _detectFoodsWithAi() async {
    final image = _pickedImage;
    if (image == null) {
      _showSnack('먼저 음식 사진을 업로드하거나 촬영해 주세요.');
      return;
    }

    setState(() => _analyzing = true);
    try {
      final candidates = await AppScope.of(context).visionFoodService.detectFoodsFromImage(image);
      if (!mounted) {
        return;
      }
      setState(() => _aiCandidates = candidates);
      _showSnack('AI 음식 후보를 찾았습니다. 실제 음식명과 섭취량을 확인해 주세요.');
    } catch (_) {
      _showSnack('AI 후보 추정에 실패했습니다.');
    } finally {
      if (mounted) {
        setState(() => _analyzing = false);
      }
    }
  }

  double _currentGrams(FoodItem? food) {
    if (food == null) {
      return 0;
    }
    if (_customGram) {
      return double.tryParse(_gramController.text.trim()) ?? 0;
    }
    return food.servingGram * _portionMultiplier;
  }

  Future<void> _saveManualMeal() async {
    final controller = AppScope.of(context);
    final food = _selectedFood;
    if (food == null) {
      _showSnack('음식을 먼저 선택해 주세요.');
      return;
    }
    final grams = _currentGrams(food);
    if (grams <= 0) {
      _showSnack('섭취량은 0g보다 커야 합니다.');
      return;
    }
    if (!_validateMealTimes()) {
      return;
    }

    setState(() => _saving = true);
    try {
      await controller.addRecord(_createRecord(food: food, intakeGram: grams, sequence: 0));
      _reset();
      widget.onSaved();
      _showSnack('식단이 저장되었습니다.');
    } catch (_) {
      _showSnack('로컬 저장에 실패했습니다.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveAiCandidates(Map<String, FoodItem?> matchedFoods) async {
    final selectedCandidates = _aiCandidates.where((candidate) => candidate.selected).toList();
    if (selectedCandidates.isEmpty) {
      _showSnack('저장할 AI 음식 후보를 선택해 주세요.');
      return;
    }

    for (final candidate in selectedCandidates) {
      if (candidate.intakeGram <= 0) {
        _showSnack('${candidate.name}의 섭취량은 0g보다 커야 합니다.');
        return;
      }
      if (matchedFoods[candidate.id] == null) {
        _showSnack('${candidate.name}은 음식 DB 매칭이 필요합니다. 직접 검색해 주세요.');
        return;
      }
    }
    if (!_validateMealTimes()) {
      return;
    }

    setState(() => _saving = true);
    try {
      final controller = AppScope.of(context);
      final records = <MealRecord>[];
      for (var i = 0; i < selectedCandidates.length; i++) {
        final candidate = selectedCandidates[i];
        final food = matchedFoods[candidate.id]!;
        records.add(_createRecord(food: food, intakeGram: candidate.intakeGram, sequence: i));
      }
      await controller.addRecords(records, aiDetected: true, aiConfidence: _combinedConfidence(selectedCandidates));
      _reset();
      widget.onSaved();
      _showSnack('선택한 AI 후보 식단이 저장되었습니다.');
    } catch (_) {
      _showSnack('로컬 저장에 실패했습니다.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  MealRecord _createRecord({
    required FoodItem food,
    required double intakeGram,
    required int sequence,
  }) {
    final now = DateTime.now();
    return MealRecord(
      id: '${now.microsecondsSinceEpoch}_$sequence',
      foodId: food.id,
      foodName: food.name,
      imagePath: _imageDataUrl,
      mealType: _mealType,
      intakeGram: intakeGram,
      kcal: NutritionCalculator.calculateKcal(food, intakeGram),
      carbs: NutritionCalculator.calculateCarbs(food, intakeGram),
      protein: NutritionCalculator.calculateProtein(food, intakeGram),
      fat: NutritionCalculator.calculateFat(food, intakeGram),
      createdAt: now,
      dateKey: AppDateUtils.dateKey(_eatenAt),
      eatenAt: _eatenAt,
      startedAt: _startedAt,
      finishedAt: _finishedAt,
    );
  }

  void _updateCandidateSelection(String id, bool selected) {
    setState(() {
      _aiCandidates = _aiCandidates
          .map((candidate) => candidate.id == id ? candidate.copyWith(selected: selected) : candidate)
          .toList();
    });
  }

  bool _validateMealTimes() {
    if (!_finishedAt.isAfter(_startedAt)) {
      _showSnack('식사 종료 시간은 시작 시간보다 늦어야 합니다.');
      return false;
    }
    return true;
  }

  String _combinedConfidence(List<DetectedFoodCandidate> candidates) {
    if (candidates.any((candidate) => candidate.confidenceLabel == '낮음')) {
      return 'mixed';
    }
    if (candidates.any((candidate) => candidate.confidenceLabel == '보통')) {
      return 'medium';
    }
    return 'high';
  }

  void _updateCandidateGram(String id, double intakeGram) {
    setState(() {
      _aiCandidates = _aiCandidates
          .map((candidate) => candidate.id == id ? candidate.copyWith(intakeGram: intakeGram) : candidate)
          .toList();
    });
  }

  void _updateCandidateCustomGram(String id, String value) {
    final grams = double.tryParse(value.trim()) ?? 0;
    _updateCandidateGram(id, grams);
  }

  void _reset() {
    setState(() {
      _query = '';
      _selectedFood = null;
      _portionMultiplier = 1;
      _customGram = false;
      _mealType = 'lunch';
      _eatenAt = DateTime.now();
      _startedAt = _eatenAt;
      _finishedAt = _startedAt.add(const Duration(minutes: 15));
      _pickedImage = null;
      _imageBytes = null;
      _imageDataUrl = null;
      _aiCandidates = [];
      _gramController.clear();
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDateTime({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) {
      return;
    }
    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}

class _MealTimeCard extends StatelessWidget {
  const _MealTimeCard({
    required this.eatenAt,
    required this.startedAt,
    required this.finishedAt,
    required this.onPickEatenAt,
    required this.onPickStartedAt,
    required this.onPickFinishedAt,
  });

  final DateTime eatenAt;
  final DateTime startedAt;
  final DateTime finishedAt;
  final VoidCallback onPickEatenAt;
  final VoidCallback onPickStartedAt;
  final VoidCallback onPickFinishedAt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _TimeRow(label: '먹은 날짜/시간', value: _format(eatenAt), onTap: onPickEatenAt),
            const Divider(),
            _TimeRow(label: '식사 시작', value: _format(startedAt), onTap: onPickStartedAt),
            const Divider(),
            _TimeRow(label: '식사 종료', value: _format(finishedAt), onTap: onPickFinishedAt),
          ],
        ),
      ),
    );
  }

  String _format(DateTime value) {
    final mm = value.minute.toString().padLeft(2, '0');
    return '${value.month}/${value.day} ${value.hour}:$mm';
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(value),
          ),
        ],
      ),
    );
  }
}
