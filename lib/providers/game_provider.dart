import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/word_dictionary.dart';
import '../models/cube.dart';
import '../models/game_language.dart';
import '../services/sound_service.dart';

class GameProvider extends ChangeNotifier {
  static const int rows = 2;
  static const int cols = 6;
  static const int spawnRow = 0;
  static const int wordRow = 1;
  static const String _highScoreKey = 'high_score';

  // Tur bazlı kelime havuzları (tüm kelimeler words_tr.txt'de mevcut)
  static const List<String> _easyWordsTr = [
    'KOD',
    'GEL',
    'SOL',
    'YOL',
    'SAT',
    'KAR',
    'TAN',
    'TOP',
    'SEN',
    'YER',
    'KALE',
    'OYUN',
    'MASA',
    'GECE',
    'SIRA',
    'DOST',
    'TANE',
    'GENE',
    'SERA',
    'NOTA',
  ];

  static const List<String> _mediumWordsTr = [
    'KART',
    'SERT',
    'KIRA',
    'KORU',
    'DOLU',
    'SINE',
    'YARA',
    'NANE',
    'LEKE',
    'DERI',
    'KARAR',
    'SELAM',
    'SALON',
    'BULUT',
    'DUMAN',
    'KALEM',
    'ORMAN',
    'ROMAN',
    'MOTOR',
    'YEMEK',
  ];

  static const List<String> _hardWordsTr = [
    'TAKIM',
    'TAMAM',
    'DENIZ',
    'DEMIR',
    'PASTA',
    'KITAP',
    'YILAN',
    'YOLCU',
    'SOLUK',
    'MERAK',
    'KODLAR',
    'KARTAL',
    'ROKETI',
    'OYUNCU',
    'KARDES',
    'SULTAN',
    'TOPRAK',
    'SISTEM',
    'DENEME',
    'DEVLET',
  ];

  // Round-based English word pools (all words also present in words_en.txt)
  static const List<String> _easyWordsEn = [
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
  ];

  static const List<String> _mediumWordsEn = [
    'RIVER',
    'HOUSE',
    'TABLE',
    'CHAIR',
    'PLANT',
    'CLOUD',
    'STONE',
    'BREAD',
    'LIGHT',
    'NIGHT',
    'WATER',
    'MUSIC',
    'PAPER',
    'GLASS',
    'SMILE',
    'DANCE',
    'HEART',
    'OCEAN',
    'BEACH',
    'SUGAR',
  ];

  static const List<String> _hardWordsEn = [
    'FLOWER',
    'GARDEN',
    'WINTER',
    'SPRING',
    'SUMMER',
    'CASTLE',
    'DRAGON',
    'ISLAND',
    'JUNGLE',
    'MARKET',
    'PLANET',
    'SILVER',
    'ORANGE',
    'PURPLE',
    'YELLOW',
    'ANIMAL',
    'BASKET',
    'CIRCLE',
    'FOREST',
    'RABBIT',
  ];

  final GameLanguage language;
  bool get isEnglish => language == GameLanguage.en;

  late List<List<Cube?>> _grid;
  late List<List<int>> _rollTicks;
  late List<int> _targetRotationCounts;
  final Random _random = Random();

  int _score = 0;
  int _roundNumber = 1;
  int _comboCount = 0;
  int _totalValidWords = 0;
  int _targetWordsFound = 0;
  int _bestCombo = 0;
  int _totalRotationsUsed = 0;
  late String _targetWord;
  bool _isTargetRevealed = false;
  late String _statusMessage;
  final List<String> _submittedWords = [];
  int _highScore = 0;
  final SoundService _soundService = SoundService();

  // --- Küçük çeviri yardımcısı: dile göre TR/EN metin seçer ---
  String _t(String tr, String en) => isEnglish ? en : tr;

  // --- Getters ---
  List<List<Cube?>> get grid => _grid;
  int get score => _score;
  int get highScore => _highScore;
  bool get isSoundEnabled => _soundService.enabled;
  int get level => _roundNumber;
  int get comboCount => _comboCount;
  int get comboMultiplier => _comboCount >= 4 ? 3 : (_comboCount >= 2 ? 2 : 1);
  int get totalValidWords => _totalValidWords;
  int get targetWordsFound => _targetWordsFound;
  int get bestCombo => _bestCombo;
  int get totalRotationsUsed => _totalRotationsUsed;
  String get statusMessage => _statusMessage;
  List<String> get submittedWords => List.unmodifiable(_submittedWords);
  String get targetWord => _targetWord;
  int get activeCols => cols;
  int get targetLength => targetWord.length;
  bool get isTargetRevealed => _isTargetRevealed;
  String get targetMask =>
      _isTargetRevealed ? targetWord : List.filled(targetLength, '*').join();
  int targetRotationCountAt(int col) => _targetRotationCounts[col];
  String get currentWord => List.generate(
        cols,
        (col) => _grid[wordRow][col]?.currentLetter ?? '_',
      ).join();

  // --- Arayüz metinleri (dile göre) ---
  String get roundLabel => _t('Tur', 'Round');
  String get scoreLabel => _t('Skor', 'Score');
  String get targetWordLabel => _t('Hedef Kelime', 'Target Word');
  String get boardHintText => _t(
        'Üst: dokun → döndür   Alt: boş kutuya → indir',
        'Top: tap → rotate   Bottom: tap empty cell → drop',
      );
  String get wordRowLabel => _t('Kelime', 'Word');
  String get submitWordLabel => _t('Kelime Gönder', 'Submit Word');
  String get clearRowLabel => _t('Satırı Temizle', 'Clear Row');
  String get nextRoundLabel => _t('Yeni Tur', 'Next Round');
  String get statisticsTooltip => _t('İstatistikler', 'Statistics');
  String get resetGameTooltip => _t('Oyunu sıfırla', 'Reset game');
  String get statsDialogTitle => _t('Oyun İstatistikleri', 'Game Statistics');
  String get labelTotalScore => _t('Toplam Skor', 'Total Score');
  String get labelHighScore => _t('En Yüksek Skor', 'High Score');
  String get labelRoundsPlayed => _t('Oynanan Tur', 'Rounds Played');
  String get labelTargetWords => _t('Hedef Kelimeler', 'Target Words');
  String get labelValidWords => _t('Geçerli Kelimeler', 'Valid Words');
  String get labelBestCombo => _t('En Yüksek Combo', 'Best Combo');
  String get labelTotalRotations => _t('Toplam Döndürme', 'Total Rotations');
  String get newGameLabel => _t('Yeni Oyun', 'New Game');
  String get exitLabel => _t('Çıkış', 'Exit');
  String get resetConfirmTitle => _t('Oyunu sıfırla', 'Reset game');
  String get resetConfirmMessage => _t(
        'Skor, tur ve istatistikler sıfırlanacak. Emin misin?',
        'Score, round and stats will be reset. Are you sure?',
      );
  String get cancelLabel => _t('Vazgeç', 'Cancel');
  String get resetLabel => _t('Sıfırla', 'Reset');
  String get adLoadingLabel => _t('Reklam Yükleniyor...', 'Loading Ad...');
  String adWatchLabel(int bonus) => _t(
      '+$bonus Dönüş Hakkı  —  Video İzle', '+$bonus Rotations — Watch Video');
  String get muteSoundTooltip => _t('Sesi kapat', 'Mute sound');
  String get unmuteSoundTooltip => _t('Sesi aç', 'Unmute sound');

  // Tura göre dönüş hakkı: kolay=6, orta=5, zor=4
  int get _rotationsPerCube {
    if (_roundNumber <= 3) return 6;
    if (_roundNumber <= 7) return 5;
    return 4;
  }

  // Tura göre kelime havuzu
  List<String> get _wordPool {
    if (isEnglish) {
      if (_roundNumber <= 3) return _easyWordsEn;
      if (_roundNumber <= 7) return _mediumWordsEn;
      return _hardWordsEn;
    }
    if (_roundNumber <= 3) return _easyWordsTr;
    if (_roundNumber <= 7) return _mediumWordsTr;
    return _hardWordsTr;
  }

  String get difficultyLabel {
    if (_roundNumber <= 3) return _t('Kolay', 'Easy');
    if (_roundNumber <= 7) return _t('Orta', 'Medium');
    return _t('Zor', 'Hard');
  }

  // 0=kolay, 1=orta, 2=zor — arayüzün dil bağımsız renk seçmesi için
  int get difficultyTier {
    if (_roundNumber <= 3) return 0;
    if (_roundNumber <= 7) return 1;
    return 2;
  }

  GameProvider({this.language = GameLanguage.tr}) {
    _statusMessage = _t(
      'Hedef kelimeyi bulmak için küpleri döndür.',
      'Rotate the cubes to find the target word.',
    );
    _targetWord = _pickTargetWord();
    _initializeRound();
    _loadHighScore();
    _soundService.init();
  }

  @override
  void dispose() {
    _soundService.dispose();
    super.dispose();
  }

  void toggleSound() {
    _soundService.toggleEnabled();
    notifyListeners();
  }

  void _haptic(Future<void> Function() feedback) {
    // Titreşim donanımı/izni yoksa veya platform kanalı (örn. testlerde) yoksa sessizce yok say
    feedback().catchError((_) {});
  }

  Future<void> _loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _highScore = prefs.getInt(_highScoreKey) ?? 0;
      notifyListeners();
    } catch (_) {
      // Depolama kullanılamıyorsa (örn. Flutter binding'i olmayan testler) sessizce yok say
    }
  }

  Future<void> _saveHighScoreIfNeeded() async {
    if (_score <= _highScore) return;
    _highScore = _score;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_highScoreKey, _highScore);
      notifyListeners();
    } catch (_) {
      // Depolama kullanılamıyorsa (örn. Flutter binding'i olmayan testler) sessizce yok say
    }
  }

  String _pickTargetWord({String? previousWord}) {
    final pool = _wordPool;
    var selected = pool[_random.nextInt(pool.length)];
    if (pool.length > 1) {
      while (selected == previousWord) {
        selected = pool[_random.nextInt(pool.length)];
      }
    }
    return selected;
  }

  int rollTickAt(int row, int col) => _rollTicks[row][col];

  void _initializeRound() {
    _grid = List.generate(rows, (_) => List<Cube?>.filled(cols, null));
    _rollTicks = List.generate(rows, (_) => List<int>.filled(cols, 0));
    _targetRotationCounts = _buildTargetRotationCounts();
    _submittedWords.clear();

    final specialCols = _pickSpecialCubeCols();

    for (var col = 0; col < cols; col++) {
      final targetLetter = col < targetLength ? targetWord[col] : null;
      final type = specialCols[col] ?? CubeType.normal;
      _grid[spawnRow][col] = _buildCube(targetLetter, col, type);
    }
  }

  // Combo >= 3 → joker, her 3. tur → ipucu küpü
  Map<int, CubeType> _pickSpecialCubeCols() {
    final result = <int, CubeType>{};
    final available = List.generate(targetLength, (i) => i)..shuffle(_random);

    if (_comboCount >= 3 && available.isNotEmpty) {
      result[available.removeAt(0)] = CubeType.joker;
    }
    if (_roundNumber % 3 == 0 && available.isNotEmpty) {
      result[available.removeAt(0)] = CubeType.hint;
    }
    return result;
  }

  Cube _buildCube(String? targetLetter, int col, CubeType type) {
    final faces = _facesForTargetLetter(targetLetter, col);
    // Joker: zaten doğru harfi gösteriyor
    final startIndex = type == CubeType.joker ? _targetRotationCounts[col] : 0;
    return Cube(
      faces: faces,
      topFaceIndex: startIndex,
      rotationLimit: _rotationsPerCube,
      type: type,
    );
  }

  List<int> _buildTargetRotationCounts() {
    return List<int>.generate(cols, (_) => _random.nextInt(5) + 1);
  }

  List<String> _facesForTargetLetter(String? letter, int col) {
    const pool = ['A', 'E', 'I', 'O', 'U', 'R', 'L', 'N', 'T', 'S'];
    final faces = <String>[];
    for (final item in pool) {
      if (item != letter && !faces.contains(item)) faces.add(item);
    }
    final normalizedFaces = faces.take(6).toList();
    if (letter == null) return normalizedFaces;
    normalizedFaces[_targetRotationCounts[col]] = letter;
    return normalizedFaces;
  }

  void _spawnFreshCube(int col) {
    _targetRotationCounts[col] = _random.nextInt(5) + 1;
    final targetLetter = col < targetLength ? targetWord[col] : null;
    _grid[spawnRow][col] = Cube(
      faces: _facesForTargetLetter(targetLetter, col),
      topFaceIndex: 0,
      rotationLimit: _rotationsPerCube,
    );
  }

  void _markRolled(int row, int col) {
    _rollTicks[row][col]++;
  }

  bool rotateCube(int row, int col) {
    if (row != spawnRow || col < 0 || col >= cols) return false;
    final cube = _grid[row][col];
    if (cube == null) return false;

    if (!cube.canRotate) {
      _statusMessage = _t('Bu küpün döndürme hakkı kalmadı!',
          'This cube has no rotations left!');
      notifyListeners();
      return false;
    }

    // İpucu küpü: ilk dokunuşta hedef harfe atla (ücretsiz)
    if (cube.type == CubeType.hint &&
        cube.topFaceIndex != _targetRotationCounts[col]) {
      cube.topFaceIndex = _targetRotationCounts[col];
      _markRolled(row, col);
      _statusMessage = _t('İpucu küpü hedef harfi gösterdi!',
          'The hint cube revealed the target letter!');
      notifyListeners();
      _soundService.play(SfxKey.rotate);
      _haptic(HapticFeedback.selectionClick);
      return true;
    }

    cube.rotate();
    _totalRotationsUsed++;
    _markRolled(row, col);
    _statusMessage = _t('Küp döndürüldü.', 'Cube rotated.');
    notifyListeners();
    _soundService.play(SfxKey.rotate);
    _haptic(HapticFeedback.selectionClick);
    return true;
  }

  bool dropCube(int col) {
    if (col < 0 || col >= cols) return false;
    final cube = _grid[spawnRow][col];
    if (cube == null || _grid[wordRow][col] != null) return false;
    _grid[wordRow][col] = cube;
    _grid[spawnRow][col] = null;
    _markRolled(wordRow, col);
    _statusMessage =
        _t('Küp kelime satırına indirildi.', 'Cube dropped into the word row.');
    notifyListeners();
    _soundService.play(SfxKey.drop);
    _haptic(HapticFeedback.lightImpact);
    return true;
  }

  void clearWordRow() {
    for (var col = 0; col < cols; col++) {
      if (_grid[wordRow][col] != null) {
        _grid[spawnRow][col] = _grid[wordRow][col];
        _grid[wordRow][col] = null;
        _markRolled(spawnRow, col);
      }
    }
    _statusMessage = _t('Küpler geri döndü.', 'Cubes moved back.');
    notifyListeners();
  }

  /// 'correct' → yeşil | 'present' → sarı | 'absent' → kırmızı | 'empty' → boş
  String wordRowCellState(int col) {
    final cube = _grid[wordRow][col];
    if (cube == null || col >= targetLength) return 'empty';
    final letter = cube.currentLetter;
    if (letter == targetWord[col]) return 'correct';
    if (targetWord.contains(letter)) return 'present';
    return 'absent';
  }

  bool submitWord() {
    // Hedef zaten bulunduysa tur bitmiştir — nextRound() çağrılana kadar
    // tekrar puan verilmemeli (aksi halde submit'e basıp durarak sonsuz puan alınır).
    if (_isTargetRevealed) return false;

    if (List.generate(targetLength, (col) => _grid[wordRow][col])
        .any((cube) => cube == null)) {
      _statusMessage = _t(
        'Kelime için gerekli kutular dolu olmalı.',
        'All required boxes for the word must be filled.',
      );
      notifyListeners();
      return false;
    }

    final word = List.generate(
      targetLength,
      (col) => _grid[wordRow][col]!.currentLetter,
    ).join();

    if (!WordDictionary.isValid(word, language)) {
      final hadCombo = _comboCount > 0;
      _comboCount = 0;
      _statusMessage = hadCombo
          ? _t('$word sözlükte yok. Combo sıfırlandı!',
              '$word is not in the dictionary. Combo reset!')
          : _t('$word sözlükte yok.', '$word is not in the dictionary.');
      notifyListeners();
      _soundService.play(SfxKey.invalid);
      _haptic(HapticFeedback.heavyImpact);
      return false;
    }

    if (word != targetWord && _submittedWords.contains(word)) {
      _statusMessage = _t('$word için zaten puan aldın.',
          'You already scored points for $word.');
      notifyListeners();
      _soundService.play(SfxKey.invalid);
      _haptic(HapticFeedback.heavyImpact);
      return false;
    }

    if (word == targetWord) {
      _comboCount++;
      if (_comboCount > _bestCombo) _bestCombo = _comboCount;
      _targetWordsFound++;
      _totalValidWords++;
      final multiplier = comboMultiplier;
      final points = targetLength * 10 * multiplier;
      _score += points;
      _submittedWords.add(word);
      _isTargetRevealed = true;
      _statusMessage = multiplier > 1
          ? _t(
              'Doğru! $targetWord +$points puan (×$multiplier COMBO!)',
              'Correct! $targetWord +$points points (×$multiplier COMBO!)',
            )
          : _t('Doğru kelime: $targetWord! +$points puan',
              'Correct word: $targetWord! +$points points');
      notifyListeners();
      _soundService.play(multiplier > 1 ? SfxKey.combo : SfxKey.targetFound);
      _haptic(HapticFeedback.mediumImpact);
      if (multiplier > 1) {
        Future.delayed(const Duration(milliseconds: 120),
            () => _haptic(HapticFeedback.mediumImpact));
      }
      _saveHighScoreIfNeeded();
      return true;
    }

    _comboCount++;
    if (_comboCount > _bestCombo) _bestCombo = _comboCount;
    _totalValidWords++;
    final multiplier = comboMultiplier;
    final points = word.length * 10 * multiplier;
    _score += points;
    _submittedWords.add(word);
    for (var col = 0; col < targetLength; col++) {
      _grid[wordRow][col] = null;
      _spawnFreshCube(col);
    }
    _statusMessage = multiplier > 1
        ? _t(
            '$word! +$points puan (×$multiplier COMBO!) Yeni küpler geldi.',
            '$word! +$points points (×$multiplier COMBO!) New cubes arrived.',
          )
        : _t(
            '$word geçerli! +$points puan. Yeni küpler geldi.',
            '$word is valid! +$points points. New cubes arrived.',
          );
    notifyListeners();
    _soundService.play(multiplier > 1 ? SfxKey.combo : SfxKey.valid);
    _haptic(HapticFeedback.lightImpact);
    _saveHighScoreIfNeeded();
    return false;
  }

  void nextRound() {
    if (!_isTargetRevealed) return;
    _roundNumber++;
    _targetWord = _pickTargetWord(previousWord: _targetWord);
    _isTargetRevealed = false;
    _statusMessage = _t(
      'Tur $_roundNumber başladı! [$difficultyLabel] $_rotationsPerCube dönüş hakkı.',
      'Round $_roundNumber started! [$difficultyLabel] $_rotationsPerCube rotations.',
    );
    _initializeRound();
    notifyListeners();
  }

  void addBonusRotations(int count) {
    for (var col = 0; col < cols; col++) {
      _grid[spawnRow][col]?.rotationLimit += count;
    }
    _statusMessage = _t('+$count ekstra dönüş hakkı kazandın!',
        'You earned +$count extra rotations!');
    notifyListeners();
  }

  void resetGame() {
    _score = 0;
    _roundNumber = 1;
    _comboCount = 0;
    _totalValidWords = 0;
    _targetWordsFound = 0;
    _bestCombo = 0;
    _totalRotationsUsed = 0;
    _isTargetRevealed = false;
    _targetWord = _pickTargetWord();
    _statusMessage = _t(
      'Hedef kelimeyi bulmak için küpleri döndür.',
      'Rotate the cubes to find the target word.',
    );
    _initializeRound();
    notifyListeners();
  }
}
