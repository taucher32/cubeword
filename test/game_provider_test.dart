import 'package:cubeword/data/word_dictionary.dart';
import 'package:cubeword/models/cube.dart';
import 'package:cubeword/providers/game_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameProvider', () {
    test('starts with only two rows and waiting cubes on top row', () {
      final provider = GameProvider();

      expect(provider.grid.length, 2);
      expect(provider.activeCols, 6);
      expect(provider.targetLength, greaterThanOrEqualTo(3));
      expect(provider.grid[GameProvider.spawnRow].where((c) => c != null).length,
          provider.targetLength);
      expect(provider.currentWord, '_' * provider.targetLength);
      expect(provider.targetMask, '*' * provider.targetLength);
    });

    test('rotate and drop are separate actions', () {
      final provider = GameProvider();

      final rotated = provider.rotateCube(GameProvider.spawnRow, 0);
      expect(rotated, isTrue);
      expect(provider.grid[GameProvider.spawnRow][0], isNotNull);

      final dropped = provider.dropCube(0);
      expect(dropped, isTrue);
      expect(provider.grid[GameProvider.spawnRow][0], isNull);
      expect(provider.grid[GameProvider.wordRow][0], isNotNull);
    });

    test('reveals target word when correct word is submitted', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await WordDictionary.init();
      final provider = GameProvider();

      for (var col = 0; col < provider.targetLength; col++) {
        for (var turn = 0; turn < provider.targetRotationCountAt(col); turn++) {
          provider.rotateCube(GameProvider.spawnRow, col);
        }
        provider.dropCube(col);
      }

      final result = provider.submitWord();
      expect(result, isTrue);
      expect(provider.isTargetRevealed, isTrue);
      expect(provider.targetMask.trimRight(), provider.targetWord);
      expect(provider.score, provider.targetLength * 10);
      expect(provider.submittedWords, [provider.targetWord]);
    });

    test('nextRound picks a target from the current level', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await WordDictionary.init();
      final provider = GameProvider();
      final firstTarget = provider.targetWord;

      for (var col = 0; col < provider.targetLength; col++) {
        for (var turn = 0; turn < provider.targetRotationCountAt(col); turn++) {
          provider.rotateCube(GameProvider.spawnRow, col);
        }
        provider.dropCube(col);
      }
      expect(provider.submitWord(), isTrue);
      provider.nextRound();

      expect(provider.level, 2);
      expect(provider.targetWord, isNotEmpty);
      expect(provider.targetWord == firstTarget, isFalse);
    });

    test('target letters appear after different rotation counts', () {
      final provider = GameProvider();
      final counts = List.generate(
        provider.targetLength,
        provider.targetRotationCountAt,
      );

      expect(counts.toSet().length, greaterThan(1));

      for (var col = 0; col < provider.targetLength; col++) {
        final cube = provider.grid[GameProvider.spawnRow][col]!;
        expect(cube.currentLetter == provider.targetWord[col], isFalse);

        for (var turn = 1; turn <= provider.targetRotationCountAt(col); turn++) {
          provider.rotateCube(GameProvider.spawnRow, col);
          expect(
            cube.currentLetter == provider.targetWord[col],
            turn == provider.targetRotationCountAt(col),
          );
        }
      }
    });

    test('target is always reachable within each cube rotation limit', () async {
      // Zor turlarda donus hakki 4'e duserken hedef 5 donus uzakta
      // kalabiliyordu -> o sutun asla dogru harfe gelemiyor, tur kilitleniyordu.
      TestWidgetsFlutterBinding.ensureInitialized();
      await WordDictionary.init();

      for (var seed = 0; seed < 15; seed++) {
        final provider = GameProvider();
        for (var round = 1; round <= 12; round++) {
          for (var col = 0; col < provider.targetLength; col++) {
            final cube = provider.grid[GameProvider.spawnRow][col]!;
            expect(
              provider.targetRotationCountAt(col),
              lessThanOrEqualTo(cube.rotationLimit),
              reason: 'round $round, col $col unreachable',
            );
            // Joker zaten hedefte, ipucu kupu ilk dokunusta atlar -> sabit
            // sayida donus yerine hedefe gelene kadar cevir.
            var guard = 0;
            while (cube.currentLetter != provider.targetWord[col] &&
                guard < GameProvider.cols + 2) {
              provider.rotateCube(GameProvider.spawnRow, col);
              guard++;
            }
            expect(cube.currentLetter, provider.targetWord[col],
                reason: 'round $round, col $col unreachable');
            provider.dropCube(col);
          }
          expect(provider.submitWord(), isTrue, reason: 'round $round');
          provider.nextRound();
        }
      }
    });

    test('columns beyond the target length are not playable', () {
      final provider = GameProvider();

      expect(provider.currentWord.length, provider.targetLength);
      for (var col = provider.targetLength; col < GameProvider.cols; col++) {
        expect(provider.isPlayableCol(col), isFalse);
        expect(provider.grid[GameProvider.spawnRow][col], isNull);
        expect(provider.dropCube(col), isFalse);
        expect(provider.wordRowCellState(col), 'inactive');
      }
    });

    test('round can be skipped once it becomes unwinnable', () {
      final provider = GameProvider();
      final round = provider.level;

      expect(provider.isRoundStuck, isFalse);
      provider.nextRound();
      expect(provider.level, round, reason: 'kilitli degilken pas gecilemez');

      // Hedefi bir yuz gecmek o sutunu geri donulemez yapar
      for (var t = 0; t <= provider.targetRotationCountAt(0); t++) {
        provider.rotateCube(GameProvider.spawnRow, 0);
      }
      expect(provider.isRoundStuck, isTrue);

      provider.nextRound();
      expect(provider.level, round + 1);
      expect(provider.isRoundStuck, isFalse);
      expect(provider.score, 0, reason: 'pas gecmek puan vermez');
    });

    test('hint cube does not rotate away once it is on the target letter',
        () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await WordDictionary.init();

      final provider = GameProvider();
      // Ipucu kupu her 3. turda cikar
      while (provider.level < 3) {
        for (var col = 0; col < provider.targetLength; col++) {
          var guard = 0;
          final cube = provider.grid[GameProvider.spawnRow][col]!;
          while (cube.currentLetter != provider.targetWord[col] && guard < 8) {
            provider.rotateCube(GameProvider.spawnRow, col);
            guard++;
          }
          provider.dropCube(col);
        }
        expect(provider.submitWord(), isTrue);
        provider.nextRound();
      }

      final hintCol = List.generate(provider.targetLength, (i) => i).firstWhere(
        (col) =>
            provider.grid[GameProvider.spawnRow][col]!.type == CubeType.hint,
      );
      final hint = provider.grid[GameProvider.spawnRow][hintCol]!;

      expect(provider.rotateCube(GameProvider.spawnRow, hintCol), isTrue);
      expect(hint.currentLetter, provider.targetWord[hintCol]);
      final limitAfterHint = hint.rotationLimit;

      // Ikinci dokunus hedefi kacirmamali ve hak yakmamali
      expect(provider.rotateCube(GameProvider.spawnRow, hintCol), isFalse);
      expect(hint.currentLetter, provider.targetWord[hintCol]);
      expect(hint.rotationLimit, limitAfterHint);
    });

    test('a wrong but valid guess breaks the combo chain', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await WordDictionary.init();

      final provider = GameProvider();

      // Turu kazan -> combo 1
      for (var col = 0; col < provider.targetLength; col++) {
        final cube = provider.grid[GameProvider.spawnRow][col]!;
        var guard = 0;
        while (cube.currentLetter != provider.targetWord[col] && guard < 8) {
          provider.rotateCube(GameProvider.spawnRow, col);
          guard++;
        }
        provider.dropCube(col);
      }
      expect(provider.submitWord(), isTrue);
      expect(provider.comboCount, 1);
      final scoreAfterWin = provider.score;

      provider.nextRound();
      expect(provider.comboCount, 1, reason: 'tur gecisi comboyu bozmaz');

      // Hedef olmayan ama sozlukte gecerli bir kelime gonder
      const candidates = {
        3: ['KOD', 'SOL', 'YOL', 'KAR', 'TOP'],
        4: ['KALE', 'OYUN', 'MASA', 'GECE'],
      };
      final wrong = candidates[provider.targetLength]!
          .firstWhere((w) => w != provider.targetWord);
      expect(WordDictionary.isValid(wrong), isTrue);

      for (var col = 0; col < wrong.length; col++) {
        provider.grid[GameProvider.wordRow][col] = Cube(
          faces: [wrong[col]],
          topFaceIndex: 0,
          rotationLimit: 0,
        );
      }

      expect(provider.submitWord(), isFalse);
      expect(provider.comboCount, 0);
      expect(provider.score, scoreAfterWin, reason: 'yanlis tahmin puan vermez');
    });
  });
}
