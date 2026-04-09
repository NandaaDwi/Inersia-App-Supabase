import 'dart:convert';
import 'package:flutter/services.dart';

class WordFilterUtils {
  static Set<String> _blacklist = {};
  static Set<String> _whitelist = {};
  static bool _isInitialized = false;

  static const Map<String, String> _leetMap = {
    '4': 'a', '@': 'a', '3': 'e', '1': 'i', '!': 'i', '0': 'o',
    '5': 's', '\$': 's', '7': 't', '8': 'b', 'v': 'u', '9': 'g',
  };

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      final String response = await rootBundle.loadString('assets/data/bad_words.json');
      final data = json.decode(response);
      _blacklist = Set<String>.from(data['blacklist'].map((e) => e.toString().toLowerCase()));
      _whitelist = Set<String>.from(data['whitelist'].map((e) => e.toString().toLowerCase()));
      _isInitialized = true;
    } catch (e) {
      print("Error loading bad words: $e");
    }
  }

  static String _normalize(String text) {
    String normalized = text.toLowerCase();

    _leetMap.forEach((key, value) {
      normalized = normalized.replaceAll(key, value);
    });

    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), '');

    normalized = normalized.replaceAllMapped(RegExp(r'(.)\1+'), (match) {
      return match.group(1)!;
    });

    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    return normalized.trim();
  }

  static List<String> checkBadWords(String text) {
    if (text.isEmpty || !_isInitialized) return [];

    final cleanText = _normalize(text);
    List<String> found = [];

    for (var safe in _whitelist) {
      if (cleanText.contains(_normalize(safe))) {
        return []; 
      }
    }

    for (var bad in _blacklist) {
      String normalizedBad = _normalize(bad);
      
      final regex = RegExp('\\b$normalizedBad\\b');
      
      if (regex.hasMatch(cleanText)) {
        found.add(bad);
      }
    }

    return found.toSet().toList();
  }
}