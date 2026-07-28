import 'package:cubeword/main.dart';
import 'package:cubeword/providers/game_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('target is hidden and appears after correct guess', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.bySemanticsLabel('Cubeword'), findsOneWidget);
    expect(find.byKey(const Key('start-game')), findsOneWidget);

    await tester.tap(find.byKey(const Key('start-game')));
    await tester.pumpAndSettle();

    expect(find.text('Hedef Kelime'), findsOneWidget);
    expect(find.text('*'), findsNWidgets(6));
    expect(find.textContaining('Seviye: 1'), findsOneWidget);

    final provider = tester.element(find.byKey(const Key('score-text'))).read<GameProvider>();

    for (var col = 0; col < provider.targetLength; col++) {
      for (var turn = 0; turn < provider.targetRotationCountAt(col); turn++) {
        await tester.tap(find.byKey(Key('cell-0-$col')));
        await tester.pump();
      }
      await tester.tap(find.byKey(Key('cell-1-$col')));
      await tester.pump();
    }

    await tester.tap(find.byKey(const Key('submit-word')));
    await tester.pump();

    expect(find.textContaining(provider.targetWord), findsWidgets);
    expect(find.textContaining('Doğru kelime'), findsOneWidget);
  });
}
