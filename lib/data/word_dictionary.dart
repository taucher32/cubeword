import 'package:flutter/services.dart';
import '../models/game_language.dart';

class WordDictionary {
  static Set<String> _wordsTr = {
    'AL',
    'AN',
    'AR',
    'AS',
    'AT',
    'AY',
    'AZ',
    'EL',
    'EN',
    'ER',
    'ET',
    'EV',
    'EY',
    'IL',
    'IN',
    'IP',
    'IS',
    'IT',
    'IZ',
    'KI',
    'NE',
    'OL',
    'ON',
    'OR',
    'OT',
    'OY',
    'SU',
    'UC',
    'YA',
    'YE',
    'KOD',
    'KODLAR',
    'KARTAL',
    'OYUN',
    'KALE',
    'KART',
    'ROKET',
    'ROKETI',
    'SOL',
    'YOL',
    'ROL',
    'SON',
    'KAR',
  };

  static Set<String> _wordsEn = {
    'AN',
    'AS',
    'AT',
    'BE',
    'BY',
    'DO',
    'GO',
    'HE',
    'IF',
    'IN',
    'IS',
    'IT',
    'ME',
    'MY',
    'NO',
    'OF',
    'ON',
    'OR',
    'SO',
    'TO',
    'UP',
    'US',
    'WE',
    'CAT',
    'DOG',
    'SUN',
    'RUN',
    'BOX',
    'PEN',
    'KEY',
    'ICE',
    'OWL',
    'BEE',
    'GAME',
    'WORD',
    'TREE',
    'STAR',
    'MOON',
    'FISH',
    'BIRD',
    'LAKE',
    'ROAD',
    'GOLD',
  };

  static Future<void> init() async {
    try {
      final data = await rootBundle.loadString('assets/words_tr.txt');
      final loaded = data
          .split('\n')
          .map((w) => w.trim().toUpperCase())
          .where((w) => w.isNotEmpty)
          .toSet();
      if (loaded.isNotEmpty) {
        _wordsTr = loaded;
      }
    } catch (_) {
      // Yükleme başarısız olursa yerleşik liste kullanılır
    }

    try {
      final data = await rootBundle.loadString('assets/words_en.txt');
      final loaded = data
          .split('\n')
          .map((w) => w.trim().toUpperCase())
          .where((w) => w.isNotEmpty)
          .toSet();
      if (loaded.isNotEmpty) {
        _wordsEn = loaded;
      }
    } catch (_) {
      // Yükleme başarısız olursa yerleşik liste kullanılır
    }
  }

  static bool isValid(String word, [GameLanguage language = GameLanguage.tr]) {
    final words = language == GameLanguage.en ? _wordsEn : _wordsTr;
    return words.contains(_normalize(word));
  }

  static String _normalize(String input) {
    return input
        .trim()
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll('Ş', 'S')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
  }
}
