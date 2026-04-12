/// Filter kata kasar lokal — bekerja 100% offline, instan, tanpa API
/// Digunakan sebagai Layer 1 yang pasti bekerja sebelum memanggil Edge Function
///
/// Strategi:
/// - Normalisasi teks sebelum cek (hapus obfuskasi, leet speak, dll)
/// - Word boundary untuk menghindari false positive (mis: "class" ≠ "ass")
/// - Censor: ganti setiap karakter dengan '*'
class WordFilter {
  // ─── Blacklist ──────────────────────────────────────────────
  // Diurutkan dari kata yang lebih panjang ke pendek
  // untuk menghindari partial match yang salah
  static const List<String> _blacklist = [
    // === Bahasa Indonesia - kata utama ===
    'anjing', 'bangsat', 'bajingan', 'brengsek', 'keparat',
    'ngentot', 'memek', 'kontol', 'tolol', 'goblok',
    'kampret', 'bedebah', 'jancok', 'jancuk', 'sialan',
    'brengsek', 'celeng', 'monyet', 'dungu',

    // === Bahasa Indonesia - slang / singkatan ===
    'anjir', 'anjrit', 'anjer', 'njir',
    'bgs', // bangsat
    'bajg', // bajingan
    'ngnt', // ngentot
    'mmk', // memek
    'kntl', // kontol
    'tlol', // tolol
    'gblk', // goblok
    'asw', 'asu',
    'jancik', 'cok', 'cuk',
    'tai', 'tae',
    'bego', 'bodoamat',
    'sial',
    'bajingan',
    'babi', // konteks umpatan
    'jangkrik', // umpatan halus yang umum
    // === English ===
    'fuck', 'fuuck', 'fck',
    'shit', 'bullshit',
    'bitch', 'bitches',
    'cunt', 'cunts',
    'bastard',
    'asshole', 'arsehole',
    'motherfucker', 'mf',
    'dick', 'dicks',
    'cock', 'cocks',
    'pussy', 'pussies',
    'nigger', 'nigga', 'nigg',
    'whore', 'whores',
    'slut', 'sluts',
    'idiot', 'idiots',
    'stupid', 'stupidity',
    'retard', 'retarded',
    'damn', 'dammit',
    'hell', // hati-hati, cek konteks
  ];

  /// Normalisasi teks untuk menangkap obfuskasi umum
  /// Contoh: "a.n.j.i.n.g" → "anjing", "4nj1ng" → "anjing"
  static String _normalize(String text) {
    return text
        .toLowerCase()
        // Hapus titik/strip/underscore/asterisk antara huruf
        .replaceAllMapped(
          RegExp(r'([a-z0-9])[.\-_*+](?=[a-z0-9])'),
          (m) => m[1]!,
        )
        // Leet speak numbers → huruf
        .replaceAll('4', 'a')
        .replaceAll('3', 'e')
        .replaceAll('1', 'i')
        .replaceAll('0', 'o')
        .replaceAll('5', 's')
        .replaceAll('@', 'a')
        .replaceAll('+', 't')
        // Huruf berulang lebih dari 2x → 2x (misal "anjiiiing" → "anjiing")
        .replaceAllMapped(RegExp(r'(.)\1{2,}'), (m) => m[1]! * 2)
        // Hapus spasi ganda
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Cek apakah teks mengandung kata kasar
  /// Return list kata yang ditemukan (kosong = bersih)
  static List<String> check(String text) {
    if (text.trim().isEmpty) return [];

    final original = text.toLowerCase();
    final normalized = _normalize(text);
    final found = <String>[];

    for (final word in _blacklist) {
      // Cek di teks asli (lowercase) dan teks yang dinormalisasi
      if (_containsWord(original, word) || _containsWord(normalized, word)) {
        found.add(word);
        break; // Cukup temukan 1 untuk block artikel, tidak perlu cek semua
      }
    }

    return found;
  }

  /// Cek apakah ada bad word dengan word boundary
  static bool _containsWord(String text, String word) {
    // Gunakan regex dengan word boundary sederhana
    // (?<![a-z]) = tidak ada huruf sebelumnya
    // (?![a-z])  = tidak ada huruf sesudahnya
    try {
      final pattern = RegExp(
        '(?<![a-z])${RegExp.escape(word)}(?![a-z])',
        caseSensitive: false,
      );
      return pattern.hasMatch(text);
    } catch (_) {
      return text.contains(word);
    }
  }

  /// Sensor kata kasar di teks — ganti dengan '*'
  /// Teks asli tersimpan di DB, yang disensor hanya tampilan
  static String censor(String text) {
    if (text.trim().isEmpty) return text;

    var result = text;
    final lower = text.toLowerCase();
    final normalized = _normalize(text);

    for (final word in _blacklist) {
      if (!_containsWord(lower, word) && !_containsWord(normalized, word)) {
        continue;
      }

      // Ganti di teks asli dengan mempertahankan case
      try {
        final pattern = RegExp(
          '(?<![a-zA-Z])${RegExp.escape(word)}(?![a-zA-Z])',
          caseSensitive: false,
        );
        result = result.replaceAllMapped(pattern, (m) => '*' * m[0]!.length);
      } catch (_) {
        result = result.replaceAll(
          RegExp(word, caseSensitive: false),
          '*' * word.length,
        );
      }
    }

    return result;
  }

  /// Apakah teks bersih (tidak ada bad word)
  static bool isClean(String text) => check(text).isEmpty;
}
