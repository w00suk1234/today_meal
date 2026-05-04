import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_config.dart';

class AppSupabase {
  const AppSupabase._();

  static bool _initialized = false;

  static Future<void> initializeIfConfigured() async {
    if (!AppConfig.hasSupabaseConfig || _initialized) {
      return;
    }
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _initialized = true;
  }

  static SupabaseClient? get clientOrNull {
    if (!_initialized) {
      return null;
    }
    return Supabase.instance.client;
  }

  static String? get currentUserId => clientOrNull?.auth.currentUser?.id;
}
