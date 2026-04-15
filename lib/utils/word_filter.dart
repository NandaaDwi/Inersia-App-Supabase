import 'dart:convert';
import 'package:flutter/services.dart';

class WordFilter {
  static List<String> _blacklist = [];
  static List<String> _whitelist = [];
  static bool _isLoaded = false;

  static Future<void> init() async {
    if (_isLoaded) return;
    try {
      final String response = await rootBundle.loadString(
        'assets/data/bad_words.json',
      );
      final data = json.decode(response);
      _blacklist = List<String>.from(
        data['blacklist'],
      ).map((e) => e.toLowerCase()).toList();
      _whitelist = List<String>.from(
        data['whitelist'],
      ).map((e) => e.toLowerCase()).toList();
      _isLoaded = true;
    } catch (e) {
      print("Gagal memuat bad_words.json: $e");
    }
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('4', 'a')
        .replaceAll('3', 'e')
        .replaceAll('1', 'i')
        .replaceAll('0', 'o')
        .replaceAll('5', 's')
        .replaceAll('7', 't');
  }

  static String? check(String text) {
    if (text.isEmpty || !_isLoaded) return null;

    String target = _normalize(text);

    for (final safe in _whitelist) {
      target = target.replaceAll(safe, '');
    }

    final words = target.split(RegExp(r'\s+'));
    for (var word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
      if (cleanWord.isEmpty) continue;

      if (_blacklist.contains(cleanWord)) {
        return cleanWord;
      }
    }
    return null;
  }

  static String censor(String text) {
    if (text.isEmpty || !_isLoaded) return text;

    String result = text;
    String normalized = _normalize(text);

    Map<String, String> protectedParts = {};
    int i = 0;
    for (final safe in _whitelist) {
      if (normalized.contains(safe)) {
        String key = "##SAFE${i}##";
        protectedParts[key] = safe;
        result = result.replaceAll(RegExp(safe, caseSensitive: false), key);
        i++;
      }
    }

    for (final bad in _blacklist) {
      final pattern = RegExp('\\b$bad\\b', caseSensitive: false);
      result = result.replaceAllMapped(
        pattern,
        (match) => '*' * match.group(0)!.length,
      );
    }

    protectedParts.forEach((key, original) {
      result = result.replaceAll(key, original);
    });

    return result;
  }
}
