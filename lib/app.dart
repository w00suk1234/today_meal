import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
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
import 'presentation/screens/health/health_profile_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/records/records_screen.dart';
import 'presentation/screens/report/report_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'services/vision_food_service.dart';

class TodayMealApp extends StatelessWidget {
  const TodayMealApp({required this.controller, super.key});

  final TodayMealController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: MaterialApp(
        title: '오늘식단 AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            surface: AppColors.surface,
          ),
          scaffoldBackgroundColor: AppColors.background,
          cardTheme: CardThemeData(
            color: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
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
    return TodayMealController(
      foodRepository: foodRepository,
      mealRepository: mealRepository,
      userRepository: userRepository,
      healthRepository: healthRepository,
      visionFoodService: const MockVisionFoodService(),
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

  DailySummary get todaySummary => summaryFor(AppDateUtils.dateKey(DateTime.now()));

  Future<void> addRecord(MealRecord record) async {
    records = [...records, record];
    await mealRepository.saveRecords(records);
    await mealRepository.saveMealGroupToSupabase(records: [record], aiDetected: false);
    notifyListeners();
  }

  Future<void> addRecords(List<MealRecord> nextRecords, {required bool aiDetected, String? aiConfidence}) async {
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
    await healthRepository.saveProfile(healthProfile, previousWeightKg: previousWeight);
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

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      AddMealScreen(onSaved: () => setState(() => _index = 0)),
      const RecordsScreen(),
      const ReportScreen(),
      const HealthProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '홈'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: '추가'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: '기록'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: '리포트'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: '몸상태'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
