import 'package:supabase_flutter/supabase_flutter.dart';

class supabaseConfig {
  static const _url = 'https://jknsfwbkgabrmythsnhw.supabase.co';
  static const _anonKey = 'sb_publishable_Ses2TdOJri8r4EyNo4BzBg_bo5kk_1y';

  static Future<void> init() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
