import '../models/game_language.dart';

/// Hedef kelimelerin diğer dildeki karşılıkları; çok anlamlıysa en fazla iki anlam.
/// Havuzlara (game_provider.dart) yeni hedef kelime eklenince buraya da eklenmeli.
class WordTranslations {
  WordTranslations._();

  static const Map<String, String> _trToEn = {
    // Kolay
    'KOD': 'Code', 'GEL': 'Come', 'SOL': 'Left', 'YOL': 'Road, Way',
    'SAT': 'Sell', 'KAR': 'Snow, Profit', 'TAN': 'Dawn', 'TOP': 'Ball',
    'SEN': 'You', 'YER': 'Place, Ground', 'KALE': 'Castle, Goal',
    'OYUN': 'Game', 'MASA': 'Table', 'GECE': 'Night', 'SIRA': 'Row, Turn',
    'DOST': 'Friend', 'TANE': 'Piece, Grain', 'GENE': 'Again',
    'SERA': 'Greenhouse', 'NOTA': 'Musical note',
    // Orta
    'KART': 'Card', 'SERT': 'Hard', 'KIRA': 'Rent', 'KORU': 'Grove, Protect',
    'DOLU': 'Full, Hail', 'SINE': 'Bosom', 'YARA': 'Wound', 'NANE': 'Mint',
    'LEKE': 'Stain', 'DERI': 'Skin, Leather', 'KARAR': 'Decision',
    'SELAM': 'Greeting', 'SALON': 'Hall, Living room', 'BULUT': 'Cloud',
    'DUMAN': 'Smoke', 'KALEM': 'Pen, Pencil', 'ORMAN': 'Forest',
    'ROMAN': 'Novel', 'MOTOR': 'Engine', 'YEMEK': 'Food, Meal',
    // Zor
    'TAKIM': 'Team, Set', 'TAMAM': 'Okay', 'DENIZ': 'Sea', 'DEMIR': 'Iron',
    'PASTA': 'Cake', 'KITAP': 'Book', 'YILAN': 'Snake', 'YOLCU': 'Passenger',
    'SOLUK': 'Pale, Breath', 'MERAK': 'Curiosity', 'KODLAR': 'Codes',
    'KARTAL': 'Eagle', 'ROKETI': 'Rocket', 'OYUNCU': 'Player, Actor',
    'KARDES': 'Sibling', 'SULTAN': 'Sultan', 'TOPRAK': 'Soil, Land',
    'SISTEM': 'System', 'DENEME': 'Trial, Essay', 'DEVLET': 'State',
  };

  static const Map<String, String> _enToTr = {
    // Kolay
    'CAT': 'Kedi', 'DOG': 'Köpek', 'SUN': 'Güneş', 'RUN': 'Koşmak',
    'BOX': 'Kutu', 'PEN': 'Kalem', 'KEY': 'Anahtar', 'ICE': 'Buz',
    'OWL': 'Baykuş', 'BEE': 'Arı', 'GAME': 'Oyun', 'WORD': 'Kelime',
    'TREE': 'Ağaç', 'STAR': 'Yıldız', 'MOON': 'Ay', 'FISH': 'Balık',
    'BIRD': 'Kuş', 'LAKE': 'Göl', 'ROAD': 'Yol', 'GOLD': 'Altın',
    // Orta
    'RIVER': 'Nehir', 'HOUSE': 'Ev', 'TABLE': 'Masa', 'CHAIR': 'Sandalye',
    'PLANT': 'Bitki', 'CLOUD': 'Bulut', 'STONE': 'Taş', 'BREAD': 'Ekmek',
    'LIGHT': 'Işık', 'NIGHT': 'Gece', 'WATER': 'Su', 'MUSIC': 'Müzik',
    'PAPER': 'Kağıt', 'GLASS': 'Cam, Bardak', 'SMILE': 'Gülümseme',
    'DANCE': 'Dans', 'HEART': 'Kalp', 'OCEAN': 'Okyanus', 'BEACH': 'Plaj',
    'SUGAR': 'Şeker',
    // Zor
    'FLOWER': 'Çiçek', 'GARDEN': 'Bahçe', 'WINTER': 'Kış',
    'SPRING': 'İlkbahar, Yay', 'SUMMER': 'Yaz', 'CASTLE': 'Kale',
    'DRAGON': 'Ejderha', 'ISLAND': 'Ada', 'JUNGLE': 'Cengel',
    'MARKET': 'Pazar, Market', 'PLANET': 'Gezegen', 'SILVER': 'Gümüş',
    'ORANGE': 'Portakal, Turuncu', 'PURPLE': 'Mor', 'YELLOW': 'Sarı',
    'ANIMAL': 'Hayvan', 'BASKET': 'Sepet', 'CIRCLE': 'Daire, Çember',
    'FOREST': 'Orman', 'RABBIT': 'Tavşan',
  };

  /// [language] oyunun dili; dönen metin diğer dildedir. Çeviri yoksa null.
  static String? of(String word, GameLanguage language) =>
      (language == GameLanguage.en ? _enToTr : _trToEn)[word];
}
