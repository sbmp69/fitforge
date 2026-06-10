/// Returns true when Supabase env still uses scaffold placeholders.
bool isPlaceholderSupabaseConfig(String? url, String? anonKey) {
  if (url == null || anonKey == null) return true;
  return url.contains('placeholder') || anonKey.contains('placeholder');
}
