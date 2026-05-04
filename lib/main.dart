import 'package:flutter/material.dart';

import 'app.dart';
import 'data/remote/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabase.initializeIfConfigured();
  final controller = await TodayMealController.create();
  runApp(TodayMealApp(controller: controller));
}
