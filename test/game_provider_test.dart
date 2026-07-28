import 'package:cubeword/providers/game_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameProvider', () {
    test('starts with only two rows and waiting cubes on top row', () {
      final provider = GameProvider();

      expect(provider.grid.length, 2);
      expect(provider.activeCols, 6);
      expect(provider.targetLength, greaterThanOrEqualTo(3));
      expect(provider.grid[GameProvider.spawnRow].where((c) => c != null).length, 6);
      expect(provider.currentWord, '______');
      expect(provider.targetMask, '******');
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

    test('reveals target word when correct word is submitted', () {
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

    test('nextRound picks a target from the current level', () {
      final provider = GameProvider();
      final firstTarget = provider.targetWord;

      for (var col = 0; col < provider.targetLength; col++) {
        for (var turn = 0; turn < provider.targetRotationCountAt(col); turn++) {
          provider.rotateCube(GameProvider.spawnRow, col);
        }
        provider.dropCube(col);
      }
      provider.submitWord();
      provider.nextRound();

      expect(provider.level, 1);
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
  });
}
