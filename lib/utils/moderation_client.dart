import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/utils/word_filter.dart';

class ModerationResult {
  final bool allowed;
  final String? reason;

  const ModerationResult({required this.allowed, this.reason});
}

class ModerationClient {
  static String get _url =>
      '${supabaseConfig.supabaseUrl}/functions/v1/moderate-content';

  static Future<ModerationResult> moderateArticle(String text) async {
    if (text.trim().isEmpty) return const ModerationResult(allowed: true);

    final bad = WordFilter.checkFirst(text);
    if (bad != null) {
      return const ModerationResult(
        allowed: false,
        reason:
            'Artikel mengandung kata tidak pantas. Hapus sebelum dipublikasi.',
      );
    }

    try {
      final session = supabaseConfig.client.auth.currentSession;
      final resp = await http
          .post(
            Uri.parse(_url),
            headers: {
              'Content-Type': 'application/json',
              if (session != null)
                'Authorization': 'Bearer ${session.accessToken}',
              'apikey': supabaseConfig.supabaseKey,
            },
            body: jsonEncode({'text': text, 'mode': 'article'}),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        if (data['allowed'] == false) {
          return ModerationResult(
            allowed: false,
            reason:
                data['reason'] as String? ?? 'Konten tidak dapat dipublikasi.',
          );
        }
      }
    } catch (_) {}

    return const ModerationResult(allowed: true);
  }

  static String censorCommentSync(String text) => WordFilter.censor(text);

  static Future<String> censorComment(String text) async =>
      censorCommentSync(text);
}
