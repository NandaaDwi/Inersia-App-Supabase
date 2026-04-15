import 'package:inersia_supabase/utils/word_filter.dart';

class ModerationResult {
  final bool allowed;
  final String? reason;
  const ModerationResult({required this.allowed, this.reason});
}

class ModerationClient {
  static Future<ModerationResult> moderateArticle(String text) async {
    final found = WordFilter.check(text);
    if (found != null) {
      return ModerationResult(
        allowed: false,
        reason:
            'Konten mengandung kata yang dilarang ($found). Harap perbaiki.',
      );
    }
    return const ModerationResult(allowed: true);
  }

  static String censorCommentSync(String text) {
    return WordFilter.censor(text);
  }
}
