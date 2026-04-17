import 'package:supabase/supabase.dart';
import '../config/supabase_config.dart';

class SupabaseClientManager {
  static Future<void> init() async {
    // Backend에서는 Supabase 초기화가 필요 없을 수 있음
  }

  static SupabaseClient get client => SupabaseClient(
    SupabaseConfig.url,
    SupabaseConfig.anonKey,
  );
}