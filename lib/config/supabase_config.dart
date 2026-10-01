/// Configuration settings for Supabase integration.
///
/// Configured with live project credentials for SafeRoute AI.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://atvsoklmuynqjpbfmzoe.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_16-GB9uRtuyddwEv1t1paw_yQ2PU0ao',
  );

  /// Check if valid credentials have been provided.
  static bool get isConfigured {
    return url.isNotEmpty &&
        !url.contains('xyzcompany') &&
        anonKey.isNotEmpty &&
        !anonKey.contains('YOUR_SUPABASE_ANON_KEY');
  }
}
