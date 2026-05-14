import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/nutrition_calculator.dart';
import 'data/local/local_storage_service.dart';
import 'data/models/daily_summary.dart';
import 'data/models/food_item.dart';
import 'data/models/health_profile.dart';
import 'data/models/meal_record.dart';
import 'data/models/user_profile.dart';
import 'data/models/weight_log.dart';
import 'data/repositories/food_repository.dart';
import 'data/repositories/health_repository.dart';
import 'data/repositories/meal_repository.dart';
import 'data/repositories/user_repository.dart';
import 'presentation/screens/add_meal/add_meal_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/records/records_screen.dart';
import 'presentation/screens/report/report_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/widgets/app_bottom_navigation.dart';
import 'services/vision_food_service.dart';

class TodayMealApp extends StatelessWidget {
  const TodayMealApp({required this.controller, super.key});

  final TodayMealController controller;

  @override
  Widget build(BuildContext context) {
    Color navOverlayColor(Set<WidgetState> states) {
      if (states.contains(WidgetState.hovered)) {
        return AppColors.primary.withValues(alpha: 0.05);
      }
      return Colors.transparent;
    }

    return AppScope(
      controller: controller,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: AppColors.primary.withValues(alpha: 0.04),
          focusColor: Colors.transparent,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.teal,
            surface: AppColors.cardWhite,
            error: AppColors.coral,
          ),
          scaffoldBackgroundColor: AppColors.background,
          cardTheme: CardThemeData(
            color: AppColors.cardWhite,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.4),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.lightGreenBackground,
            selectedColor: AppColors.primarySoft,
            checkmarkColor: AppColors.primary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999)),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.resolveWith(navOverlayColor),
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            indicatorColor: AppColors.primarySoft,
            overlayColor: WidgetStateProperty.resolveWith(navOverlayColor),
          ),
        ),
        home: const AppShell(),
      ),
    );
  }
}

class AppScope extends InheritedNotifier<TodayMealController> {
  const AppScope({
    required TodayMealController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static TodayMealController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}

class TodayMealController extends ChangeNotifier {
  TodayMealController({
    required this.foodRepository,
    required this.mealRepository,
    required this.userRepository,
    required this.healthRepository,
    required this.visionFoodService,
    required this.foods,
    required this.records,
    required this.profile,
    required this.healthProfile,
    required this.weightLogs,
  });

  final FoodRepository foodRepository;
  final MealRepository mealRepository;
  final UserRepository userRepository;
  final HealthRepository healthRepository;
  final VisionFoodService visionFoodService;
  final List<FoodItem> foods;
  List<MealRecord> records;
  UserProfile profile;
  HealthProfile healthProfile;
  List<WeightLog> weightLogs;

  static Future<TodayMealController> create() async {
    final storage = await LocalStorageService.create();
    final foodRepository = FoodRepository();
    final mealRepository = MealRepository(storage);
    final userRepository = UserRepository(storage);
    final healthRepository = HealthRepository(storage);
    final healthProfile = await healthRepository.loadProfile();
    final visionFoodService = AppConfig.hasAiApiBaseUrl
        ? const FallbackVisionFoodService(
            primary: RemoteVisionFoodService(),
          )
        : const MockVisionFoodService();
    return TodayMealController(
      foodRepository: foodRepository,
      mealRepository: mealRepository,
      userRepository: userRepository,
      healthRepository: healthRepository,
      visionFoodService: visionFoodService,
      foods: await foodRepository.loadFoods(),
      records: await mealRepository.loadRecords(),
      profile: await userRepository.loadProfile(),
      healthProfile: healthProfile,
      weightLogs: await healthRepository.loadWeightLogs(),
    );
  }

  DailySummary summaryFor(String dateKey) {
    return NutritionCalculator.calculateDailySummary(
      records.where((record) => record.dateKey == dateKey).toList(),
      dateKey,
    );
  }

  DailySummary get todaySummary =>
      summaryFor(AppDateUtils.dateKey(DateTime.now()));

  Future<void> addRecord(MealRecord record) async {
    records = [...records, record];
    await mealRepository.saveRecords(records);
    await mealRepository
        .saveMealGroupToSupabase(records: [record], aiDetected: false);
    notifyListeners();
  }

  Future<void> addRecords(List<MealRecord> nextRecords,
      {required bool aiDetected, String? aiConfidence}) async {
    if (nextRecords.isEmpty) {
      return;
    }
    records = [...records, ...nextRecords];
    await mealRepository.saveRecords(records);
    await mealRepository.saveMealGroupToSupabase(
      records: nextRecords,
      aiDetected: aiDetected,
      aiConfidence: aiConfidence,
    );
    notifyListeners();
  }

  Future<void> deleteRecord(String id) async {
    records = records.where((record) => record.id != id).toList();
    await mealRepository.saveRecords(records);
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile nextProfile) async {
    profile = nextProfile;
    await userRepository.saveProfile(profile);
    notifyListeners();
  }

  Future<void> saveHealthProfile(HealthProfile nextHealthProfile) async {
    final previousWeight = healthProfile.weightKg;
    healthProfile = nextHealthProfile.recalculated();
    profile = UserProfile(
      nickname: healthProfile.nickname,
      targetKcal: healthProfile.targetKcal,
      heightCm: healthProfile.heightCm,
      weightKg: healthProfile.weightKg,
      goalType: healthProfile.goalType,
    );
    await healthRepository.saveProfile(healthProfile,
        previousWeightKg: previousWeight);
    await userRepository.saveProfile(profile);
    weightLogs = await healthRepository.loadWeightLogs();
    notifyListeners();
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final _homeScrollController = ScrollController();
  final _recordsScrollController = ScrollController();
  final _addScrollController = ScrollController();
  final _reportScrollController = ScrollController();
  final _settingsScrollController = ScrollController();

  @override
  void dispose() {
    _homeScrollController.dispose();
    _recordsScrollController.dispose();
    _addScrollController.dispose();
    _reportScrollController.dispose();
    _settingsScrollController.dispose();
    super.dispose();
  }

  void _openAddTab() {
    if (_index == 2) {
      _resetScroll(_addScrollController);
      return;
    }
    setState(() => _index = 2);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resetScroll(_addScrollController),
    );
  }

  void _handleTabSelected(int value) {
    if (value == _index) {
      _resetScroll(_scrollControllerFor(value));
      return;
    }
    setState(() => _index = value);
    if (value == 2) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _resetScroll(_addScrollController),
      );
    }
  }

  ScrollController _scrollControllerFor(int index) {
    return switch (index) {
      0 => _homeScrollController,
      1 => _recordsScrollController,
      2 => _addScrollController,
      3 => _reportScrollController,
      _ => _settingsScrollController,
    };
  }

  void _resetScroll(ScrollController controller) {
    if (!controller.hasClients) {
      return;
    }
    controller.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onAnalyzeFood: _openAddTab,
        scrollController: _homeScrollController,
      ),
      RecordsScreen(
        onAddMeal: _openAddTab,
        scrollController: _recordsScrollController,
      ),
      AddMealScreen(
        onSaved: () => setState(() => _index = 0),
        scrollController: _addScrollController,
      ),
      ReportScreen(
        onAddMeal: _openAddTab,
        scrollController: _reportScrollController,
      ),
      SettingsScreen(scrollController: _settingsScrollController),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.lightGreenBackground, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final frameWidth =
                  isWide ? 430.0 : constraints.maxWidth.clamp(0.0, 480.0);
              return Center(
                child: Container(
                  width: frameWidth,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: isWide
                        ? Border.all(color: AppColors.border)
                        : Border.all(color: Colors.transparent),
                    boxShadow: isWide
                        ? const [
                            BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 30,
                                offset: Offset(0, 14)),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                          child:
                              IndexedStack(index: _index, children: screens)),
                      AppBottomNavigation(
                        selectedIndex: _index,
                        onSelected: _handleTabSelected,
                        items: const [
                          AppBottomNavigationItem(
                              icon: Icons.home_outlined,
                              activeIcon: Icons.home_rounded,
                              label: '홈'),
                          AppBottomNavigationItem(
                              icon: Icons.history_rounded,
                              activeIcon: Icons.manage_search_rounded,
                              label: '기록'),
                          AppBottomNavigationItem(
                              icon: Icons.add_circle_outline,
                              activeIcon: Icons.add_circle,
                              label: '추가'),
                          AppBottomNavigationItem(
                              icon: Icons.bar_chart_rounded,
                              activeIcon: Icons.insights_rounded,
                              label: '리포트'),
                          AppBottomNavigationItem(
                              icon: Icons.settings_outlined,
                              activeIcon: Icons.settings,
                              label: '설정'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
