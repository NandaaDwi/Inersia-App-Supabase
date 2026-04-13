class WordFilter {
  static const _id = [
    'anjing',
    'anjir',
    'anjrit',
    'anjer',
    'bangsat',
    'bajingan',
    'brengsek',
    'keparat',
    'ngentot',
    'entot',
    'memek',
    'kontol',
    'tolol',
    'goblok',
    'kampret',
    'bedebah',
    'jancok',
    'jancuk',
    'sialan',
    'monyet',
    'bego',
    'dungu',
    'celeng',
    'asu',
    'tai',
    'kntl',
    'mmk',
    'ngnt',
    'bgs',
    'bajg',
  ];

  static const _en = [
    'fuck',
    'shit',
    'bitch',
    'cunt',
    'bastard',
    'asshole',
    'motherfucker',
    'nigger',
    'nigga',
    'whore',
    'slut',
    'retard',
    'pussy',
    'cock',
    'dick',
  ];

  static String _norm(String t) {
    return t
        .toLowerCase()
        .replaceAllMapped(
          RegExp(r'([a-z0-9])[.\-_*+|](?=[a-z0-9])'),
          (m) => m[1]!,
        )
        .replaceAll('4', 'a')
        .replaceAll('3', 'e')
        .replaceAll('1', 'i')
        .replaceAll('0', 'o')
        .replaceAll('5', 's')
        .replaceAll('@', 'a')
        .replaceAllMapped(RegExp(r'(.)\1{2,}'), (m) => m[1]! * 2)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? checkFirst(String text) {
    if (text.trim().isEmpty) return null;
    final lower = text.toLowerCase();
    final norm = _norm(text);

    for (final w in _id) {
      if (lower.contains(w) || norm.contains(w)) return w;
    }
    for (final w in _en) {
      final re = RegExp(
        '(?<![a-z])${RegExp.escape(w)}(?![a-z])',
        caseSensitive: false,
      );
      if (re.hasMatch(lower) || re.hasMatch(norm)) return w;
    }
    return null;
  }

  static bool isClean(String text) => checkFirst(text) == null;

  static String censor(String text) {
    var r = text;
    for (final w in _id) {
      r = r.replaceAll(
        RegExp(RegExp.escape(w), caseSensitive: false),
        '*' * w.length,
      );
    }
    for (final w in _en) {
      r = r.replaceAllMapped(
        RegExp(
          '(?<![a-zA-Z])${RegExp.escape(w)}(?![a-zA-Z])',
          caseSensitive: false,
        ),
        (m) => '*' * m[0]!.length,
      );
    }
    return r;
  }
}
