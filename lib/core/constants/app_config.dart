class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const aiApiBaseUrl = String.fromEnvironment('AI_API_BASE_URL');

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasAiApiBaseUrl => aiApiBaseUrl.trim().isNotEmpty;

  static bool get isAiApiBaseUrlPlaceholder {
    final value = aiApiBaseUrl.trim().toLowerCase();
    if (value.isEmpty) {
      return false;
    }
    return value == 'https://example.vercel.app' ||
        value == 'http://example.vercel.app' ||
        value.contains('your-ai-server.example.com') ||
        value.contains('your-vercel-app') ||
        value.contains('example.com') ||
        value.contains('example.vercel.app');
  }

  static bool get hasUsableAiApiBaseUrl =>
      hasAiApiBaseUrl && !isAiApiBaseUrlPlaceholder;
}
