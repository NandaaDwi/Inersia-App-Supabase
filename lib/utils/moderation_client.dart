import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/utils/word_filter.dart';

class ModerationResult {
  final bool allowed;
  final String? reason;
  final String? censoredText;

  const ModerationResult({
    required this.allowed,
    this.reason,
    this.censoredText,
  });
}

/// Client moderasi dengan dua strategi:
///
/// Untuk ARTIKEL (mode publish):
///   1. Filter lokal (WordFilter) — instan, pasti bekerja, tanpa network
///   2. Edge Function → OpenAI (opsional, jika lolos layer 1)
///
/// Untuk KOMENTAR:
///   1. Filter lokal saja — sensor langsung di Dart tanpa network
///   Komentar tidak perlu Edge Function karena hanya disensor, tidak diblock.
///
/// Dengan pendekatan ini, filter SELALU bekerja bahkan jika:
/// - Edge Function belum di-deploy
/// - Network bermasalah
/// - Supabase down
class ModerationClient {
  // URL Edge Function — sesuaikan dengan project Supabase kamu
  // Format: https://<project-ref>.supabase.co/functions/v1/moderate-content
  static String get _functionUrl {
    // Gunakan supabaseUrl dari client (properti yang benar)
    final url = supabaseConfig.supabaseUrl;
    return '$url/functions/v1/moderate-content';
  }

  /// Moderasi artikel — blocking jika konten melanggar
  /// Layer 1 (lokal) selalu dijalankan terlebih dahulu
  /// Layer 2 (Edge Function) dijalankan jika lolos layer 1
  static Future<ModerationResult> moderateArticle(String text) async {
    if (text.trim().isEmpty) return const ModerationResult(allowed: true);

    // ── Layer 1: Filter lokal (pasti bekerja, instan) ──────────
    final badWords = WordFilter.check(text);
    if (badWords.isNotEmpty) {
      return ModerationResult(
        allowed: false,
        reason:
            'Konten mengandung kata tidak pantas: ${badWords.take(3).join(", ")}.\nHapus sebelum dipublikasi.',
      );
    }

    // ── Layer 2: Edge Function → OpenAI (opsional) ─────────────
    // Hanya dipanggil jika lolos layer 1
    // Jika gagal (network error, belum deploy, dll), tetap allow
    try {
      final session = supabaseConfig.client.auth.currentSession;
      final authHeader = session != null ? 'Bearer ${session.accessToken}' : '';
      final anonKey = supabaseConfig.supabaseKey;

      final response = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Content-Type': 'application/json',
              if (authHeader.isNotEmpty) 'Authorization': authHeader,
              'apikey': anonKey,
            },
            body: jsonEncode({'text': text, 'mode': 'article'}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final allowed = data['allowed'] as bool? ?? true;
        if (!allowed) {
          return ModerationResult(
            allowed: false,
            reason:
                data['reason'] as String? ?? 'Konten tidak dapat dipublikasi.',
          );
        }
      }
      // Jika status != 200 atau response tidak valid, tetap allow
      // (Layer 1 sudah cukup untuk kata-kata yang jelas)
    } catch (_) {
      // Network error, timeout, Edge Function belum di-deploy → allow
      // Layer 1 sudah menjaga konten yang jelas kasar
    }

    return const ModerationResult(allowed: true);
  }

  /// Sensor komentar — menggunakan filter lokal SAJA
  /// Cepat, tidak perlu network, selalu bekerja
  /// Teks asli tersimpan di DB, yang dikembalikan hanya versi tersensor
  static String censorCommentSync(String text) {
    return WordFilter.censor(text);
  }

  /// Versi async — untuk kompatibilitas dengan kode yang sudah ada
  /// Sebenarnya langsung delegasi ke versi sync
  static Future<String> censorComment(String text) async {
    return censorCommentSync(text);
  }
}
