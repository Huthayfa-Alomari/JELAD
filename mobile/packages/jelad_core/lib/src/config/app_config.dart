class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'));
  static const supabaseAnonKey = supabasePublishableKey;
  static const appName = 'JELAD';
}
