import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';

import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/nutrition_calculator.dart';
import '../../../data/models/detected_food_candidate.dart';
import '../../../data/models/food_item.dart';
import '../../../data/models/meal_record.dart';
import '../../../services/vision_food_service.dart';
import '../../widgets/app_scaffold.dart';
import 'widgets/ai_photo_analysis_section.dart';
import 'widgets/input_action_card.dart';
import 'widgets/manual_food_search_section.dart';
import 'widgets/meal_time_section.dart';
import 'widgets/nutrition_summary_card.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({
    required this.onSaved,
    this.scrollController,
    super.key,
  });

  final VoidCallback onSaved;
  final ScrollController? scrollController;

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  static const _previewImageMaxWidth = 1600.0;
  static const _previewImageQuality = 90;
  static const _analysisImageMaxWidth = 1024;
  static const _analysisImageQuality = 80;

  final _picker = ImagePicker();
  final _gramController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _manualSearchKey = GlobalKey();
  final _aiResultsKey = GlobalKey();
  String _query = '';
  FoodItem? _selectedFood;
  double _portionMultiplier = 1;
  bool _customGram = false;
  String _mealType = 'lunch';
  DateTime _eatenAt = DateTime.now();
  DateTime _startedAt = DateTime.now();
  DateTime _finishedAt = DateTime.now().add(const Duration(minutes: 15));
  XFile? _pickedImage;
  Uint8List? _previewImageBytes;
  Uint8List? _analysisImageBytes;
  String? _analysisImageDataUrl;
  String _analysisImageMimeType = 'image/jpeg';
  String? _selectedImageHash;
  String? _lastAnalyzedImageHash;
  bool _hasCachedAiResult = false;
  List<DetectedFoodCandidate> _lastAiCandidates = [];
  bool _saving = false;
  bool _analyzing = false;
  bool _analysisAttempted = false;
  List<DetectedFoodCandidate> _aiCandidates = [];

  @override
  void dispose() {
    _gramController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final results = controller.foodRepository.search(controller.foods, _query);
    final selected = _selectedFood;
    final grams = _currentGrams(selected);
    final manualNutrition =
        selected == null ? null : _manualNutrition(selected, grams);
    final matchedFoods = {
      for (final candidate in _aiCandidates)
        candidate.id: controller.foodRepository.matchAiCandidate(
          controller.foods,
          candidate.name,
          candidate.matchedFoodItemId,
        ),
    };
    final aiNutrition = _aiNutrition(matchedFoods);
    final canAnalyze = _analysisImageBytes != null && !_analyzing;
    final hasCachedAnalysisForImage = _hasCachedAnalysisForSelectedImage;

    return AppScaffold(
      controller: widget.scrollController,
      children: [
        const AppPageHeader(
          title: '식단 추가',
          subtitle: '사진 분석 또는 직접 검색으로 오늘의 식사를 기록해요',
          icon: Icons.add_a_photo_outlined,
        ),
        Row(
          children: [
            Expanded(
              child: InputActionCard(
                label: '카메라',
                icon: Icons.photo_camera_outlined,
                color: AppColors.primary,
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InputActionCard(
                label: '갤러리',
                icon: Icons.photo_library_outlined,
                color: AppColors.teal,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InputActionCard(
                label: '직접 검색',
                icon: Icons.search_rounded,
                color: AppColors.blue,
                onTap: () {
                  _scrollToManualSearch();
                },
              ),
            ),
          ],
        ),
        AiPhotoAnalysisSection(
          previewImageBytes: _previewImageBytes,
          hasPickedImage: _previewImageBytes != null,
          analyzing: _analyzing,
          saving: _saving,
          analysisAttempted: _analysisAttempted,
          candidates: _aiCandidates,
          foodsByCandidateId: matchedFoods,
          nutrition: aiNutrition,
          selectedMealType: _mealType,
          onPickGallery: () => _pickImage(ImageSource.gallery),
          onPickCamera: () => _pickImage(ImageSource.camera),
          onAnalyze: canAnalyze ? _detectFoodsWithAi : null,
          hasCachedAnalysisForImage: hasCachedAnalysisForImage,
          onForceAnalyze: canAnalyze && hasCachedAnalysisForImage
              ? () => _detectFoodsWithAi(forceRemote: true)
              : null,
          onSelectionChanged: _updateCandidateSelection,
          onPortionSelected: _updateCandidateGram,
          onCustomGramChanged: _updateCandidateCustomGram,
          onMealTypeSelected: (type) => setState(() => _mealType = type),
          onSaveCandidates: () => _saveAiCandidates(matchedFoods),
          onManualMatch: () {
            _scrollToManualSearch();
          },
          resultsKey: _aiResultsKey,
        ),
        MealTimeSection(
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
        KeyedSubtree(
          key: _manualSearchKey,
          child: ManualFoodSearchSection(
            focusNode: _searchFocusNode,
            foods: results,
            selectedFood: selected,
            grams: grams,
            selectedMultiplier: _portionMultiplier,
            customGram: _customGram,
            gramController: _gramController,
            selectedMealType: _mealType,
            saving: _saving,
            onQueryChanged: (value) => setState(() => _query = value),
            onFoodSelected: _selectFood,
            onMultiplierSelected: (value) => setState(() {
              _customGram = false;
              _portionMultiplier = value;
            }),
            onCustomSelected: () => setState(() {
              _customGram = true;
              _gramController.text = grams.round().toString();
            }),
            onCustomGramChanged: () => setState(() {}),
            onMealTypeSelected: (type) => setState(() => _mealType = type),
            onSave: _saveManualMeal,
            nutrition: manualNutrition,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Keep the visible preview sharper than the payload sent to the AI API.
      // Production storage should replace this MVP data URL with a thumbnail
      // path or remote Storage URL.
      final file = await _picker.pickImage(
          source: source,
          imageQuality: _previewImageQuality,
          maxWidth: _previewImageMaxWidth);
      if (file == null) {
        _showSnack('이미지 선택을 취소했습니다.');
        return;
      }
      final previewBytes = await file.readAsBytes();
      final analysisPayload = await _createAnalysisImagePayload(
        previewBytes,
        fallbackMimeType: _mimeTypeForPickedImage(file),
      );
      final analysisBytes = analysisPayload.bytes;
      final imageHash = _imageHash(analysisBytes);
      setState(() {
        _pickedImage = file;
        _previewImageBytes = previewBytes;
        _analysisImageBytes = analysisBytes;
        _analysisImageMimeType = analysisPayload.mimeType;
        _analysisImageDataUrl =
            'data:${analysisPayload.mimeType};base64,${base64Encode(analysisBytes)}';
        _selectedImageHash = imageHash;
        _aiCandidates = [];
        _analysisAttempted = false;
      });
    } catch (_) {
      _showSnack(source == ImageSource.camera
          ? '카메라를 사용할 수 없습니다.'
          : '이미지를 불러오지 못했습니다.');
    }
  }

  Future<void> _detectFoodsWithAi({bool forceRemote = false}) async {
    final controller = AppScope.of(context);
    final imageBytes = _analysisImageBytes;
    final imageHash = _selectedImageHash;
    if (_pickedImage == null || imageBytes == null) {
      _showSnack('먼저 음식 사진을 업로드하거나 촬영해 주세요.');
      return;
    }

    debugPrint(
      '[AI_ANALYZE_START] imageHash=${_shortHash(imageHash)} '
      'bytes=${imageBytes.length} foods=${controller.foods.length}',
    );

    if (!forceRemote &&
        imageHash != null &&
        _hasCachedAiResult &&
        _lastAnalyzedImageHash == imageHash) {
      debugPrint('[AI_CACHE_HIT] imageHash=${_shortHash(imageHash)}');
      setState(() {
        _aiCandidates = _cloneCandidates(_lastAiCandidates);
        _analysisAttempted = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToAiResults());
      _showSnack('같은 사진의 이전 분석 결과를 다시 표시합니다.');
      return;
    }

    setState(() {
      _analyzing = true;
      _analysisAttempted = false;
    });
    try {
      final visionFoodService = controller.visionFoodService;
      final analysisImage = XFile.fromData(
        imageBytes,
        mimeType: _analysisImageMimeType,
        name: 'today_meal_analysis.jpg',
      );
      final candidates = await visionFoodService.detectFoodsFromImage(
        analysisImage,
        imageHash: imageHash,
        forceRefresh: forceRemote,
        availableFoods: controller.foods,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _aiCandidates = candidates;
        _lastAiCandidates = _cloneCandidates(candidates);
        _lastAnalyzedImageHash = imageHash;
        _hasCachedAiResult = true;
        _analysisAttempted = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToAiResults());
      if (candidates.isEmpty) {
        _showSnack('음식 후보를 찾지 못했습니다. 직접 검색으로 추가해 주세요.');
      } else if (visionFoodService.lastUserMessage != null) {
        _showSnack(visionFoodService.lastUserMessage!);
      } else {
        _showSnack('AI가 음식 후보를 찾았습니다. 실제 음식명과 섭취량을 확인해 주세요.');
      }
    } on VisionFoodException catch (error) {
      debugPrint('[AI_FALLBACK] reason=${error.message}');
      if (mounted) {
        setState(() {
          _aiCandidates = [];
          _analysisAttempted = true;
        });
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToAiResults());
      }
      _showSnack(error.message);
    } catch (_) {
      debugPrint('[AI_FALLBACK] reason=unknown');
      if (mounted) {
        setState(() {
          _aiCandidates = [];
          _analysisAttempted = true;
        });
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToAiResults());
      }
      _showSnack('AI 후보 추정에 실패했습니다.');
    } finally {
      if (mounted) {
        setState(() => _analyzing = false);
      }
    }
  }

  bool get _hasCachedAnalysisForSelectedImage {
    final imageHash = _selectedImageHash;
    return imageHash != null &&
        _hasCachedAiResult &&
        _lastAnalyzedImageHash == imageHash;
  }

  String _imageHash(Uint8List bytes) => sha256.convert(bytes).toString();

  Future<_AnalysisImagePayload> _createAnalysisImagePayload(
    Uint8List previewBytes, {
    required String fallbackMimeType,
  }) async {
    try {
      final decoded = image_lib.decodeImage(previewBytes);
      if (decoded == null) {
        return _AnalysisImagePayload(
          bytes: previewBytes,
          mimeType: fallbackMimeType,
        );
      }
      final oriented = image_lib.bakeOrientation(decoded);
      final shouldResize = oriented.width > _analysisImageMaxWidth;
      final resized = shouldResize
          ? image_lib.copyResize(
              oriented,
              width: _analysisImageMaxWidth,
              interpolation: image_lib.Interpolation.average,
            )
          : oriented;
      return _AnalysisImagePayload(
        bytes: Uint8List.fromList(
          image_lib.encodeJpg(resized, quality: _analysisImageQuality),
        ),
        mimeType: 'image/jpeg',
      );
    } catch (error) {
      debugPrint('AddMealScreen: analysis image compression failed: $error');
      return _AnalysisImagePayload(
        bytes: previewBytes,
        mimeType: fallbackMimeType,
      );
    }
  }

  String _mimeTypeForPickedImage(XFile image) {
    final explicit = image.mimeType;
    if (explicit != null && explicit.startsWith('image/')) {
      return explicit;
    }
    final name = image.name.toLowerCase();
    final path = image.path.toLowerCase();
    if (name.endsWith('.png') || path.endsWith('.png')) {
      return 'image/png';
    }
    if (name.endsWith('.webp') || path.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _shortHash(String? hash) {
    if (hash == null || hash.length <= 12) {
      return hash ?? 'none';
    }
    return hash.substring(0, 12);
  }

  List<DetectedFoodCandidate> _cloneCandidates(
    List<DetectedFoodCandidate> candidates,
  ) {
    return candidates.map((candidate) => candidate.copyWith()).toList();
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
      await controller
          .addRecord(_createRecord(food: food, intakeGram: grams, sequence: 0));
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
    final selectedCandidates =
        _aiCandidates.where((candidate) => candidate.selected).toList();
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
        _showSnack('정확한 기록을 위해 ${candidate.name}의 음식명을 직접 검색으로 확인해 주세요.');
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
        records.add(_createRecord(
            food: food, intakeGram: candidate.intakeGram, sequence: i));
      }
      await controller.addRecords(records,
          aiDetected: true,
          aiConfidence: _combinedConfidence(selectedCandidates));
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
      imagePath: _localImageReference(),
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
          .map((candidate) => candidate.id == id
              ? candidate.copyWith(selected: selected)
              : candidate)
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
          .map((candidate) => candidate.id == id
              ? candidate.copyWith(intakeGram: intakeGram)
              : candidate)
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
      _previewImageBytes = null;
      _analysisImageBytes = null;
      _analysisImageDataUrl = null;
      _analysisImageMimeType = 'image/jpeg';
      _selectedImageHash = null;
      _aiCandidates = [];
      _analysisAttempted = false;
      _gramController.clear();
    });
  }

  NutritionDraft _manualNutrition(FoodItem food, double grams) {
    return NutritionDraft(
      kcal: NutritionCalculator.calculateKcal(food, grams),
      carbs: NutritionCalculator.calculateCarbs(food, grams),
      protein: NutritionCalculator.calculateProtein(food, grams),
      fat: NutritionCalculator.calculateFat(food, grams),
    );
  }

  NutritionDraft _aiNutrition(Map<String, FoodItem?> matchedFoods) {
    var kcal = 0.0;
    var carbs = 0.0;
    var protein = 0.0;
    var fat = 0.0;
    for (final candidate
        in _aiCandidates.where((candidate) => candidate.selected)) {
      final food = matchedFoods[candidate.id];
      if (food == null) {
        continue;
      }
      kcal += NutritionCalculator.calculateKcal(food, candidate.intakeGram);
      carbs += NutritionCalculator.calculateCarbs(food, candidate.intakeGram);
      protein +=
          NutritionCalculator.calculateProtein(food, candidate.intakeGram);
      fat += NutritionCalculator.calculateFat(food, candidate.intakeGram);
    }
    return NutritionDraft(kcal: kcal, carbs: carbs, protein: protein, fat: fat);
  }

  void _selectFood(FoodItem food) {
    setState(() {
      _selectedFood = food;
      _customGram = false;
      _portionMultiplier = 1;
      _gramController.text = food.servingGram.round().toString();
    });
  }

  String? _localImageReference() {
    final dataUrl = _analysisImageDataUrl;
    if (dataUrl == null || dataUrl.isEmpty) {
      return null;
    }
    // TODO: Before production, store a small thumbnail path or remote Storage
    // URL here instead of a data URL. The preview bytes are never persisted,
    // and Supabase sync explicitly refuses data:image payloads for image_url.
    return dataUrl;
  }

  Future<void> _scrollToManualSearch() async {
    final targetContext = _manualSearchKey.currentContext;
    if (targetContext != null) {
      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    } else {
      final controller = widget.scrollController;
      if (controller != null && controller.hasClients) {
        await controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        );
      }
    }
    if (mounted) {
      _searchFocusNode.requestFocus();
    }
  }

  Future<void> _scrollToAiResults() async {
    final targetContext = _aiResultsKey.currentContext;
    if (targetContext == null) {
      return;
    }
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) {
      return;
    }
    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }
}

class _AnalysisImagePayload {
  const _AnalysisImagePayload({
    required this.bytes,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String mimeType;
}
