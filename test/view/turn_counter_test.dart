import 'package:between_the_lines/model/game_state.dart';
import 'package:between_the_lines/model/level_data.dart';
import 'package:between_the_lines/view/components/character_component.dart';
import 'package:between_the_lines/view/stealth_game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps Flame's component lifecycle until CharacterComponents are mounted.
Future<void> _pumpUntilCharactersLoaded(StealthGame game) async {
  for (var i = 0; i < 50; i++) {
    await Future.delayed(Duration.zero);
    game.update(0);
    if (game.world.children.whereType<CharacterComponent>().isNotEmpty) return;
  }
}

/// Helper: complete one full turn by double-tapping (waiting) all characters.
void _waitAllCharacters(StealthGame game) {
  final components = game.world.children.whereType<CharacterComponent>().toList();
  for (final cc in components) {
    if (!cc.model.hasMoved) {
      cc.onDoubleTapCallback(cc);
    }
  }
  game.update(0.1);
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  // Simple level with no enemies — characters can freely wait without being spotted.
  final levelData = LevelData(
    name: 'Turn Counter Test',
    stages: [StageData(width: 3, height: 4)],
    characterStartX: [1, 2],
  );

  group('Turn counter', () {
    testWithGame<StealthGame>(
      'starts at zero',
      () => StealthGame(levelData: levelData, districtTier: 1),
      (game) async {
        await _pumpUntilCharactersLoaded(game);
        expect(game.totalTurnCount, 0);
      },
    );

    testWithGame<StealthGame>(
      'increments after all characters complete a turn',
      () => StealthGame(levelData: levelData, districtTier: 1),
      (game) async {
        await _pumpUntilCharactersLoaded(game);

        _waitAllCharacters(game);
        expect(game.totalTurnCount, 1);

        _waitAllCharacters(game);
        expect(game.totalTurnCount, 2);

        _waitAllCharacters(game);
        expect(game.totalTurnCount, 3);
      },
    );

    testWithGame<StealthGame>(
      'does not increment when only some characters have moved',
      () => StealthGame(levelData: levelData, districtTier: 1),
      (game) async {
        await _pumpUntilCharactersLoaded(game);

        // Only move one of the two characters
        final components =
            game.world.children.whereType<CharacterComponent>().toList();
        components.first.onDoubleTapCallback(components.first);
        game.update(0.1);

        expect(game.totalTurnCount, 0,
            reason: 'Turn should not complete until all characters act');
      },
    );
  });

  group('Turn counter reset on restart button', () {
    testWithGame<StealthGame>(
      'resetCurrentStage restores turn count to stage start value',
      () => StealthGame(levelData: levelData, districtTier: 1),
      (game) async {
        await _pumpUntilCharactersLoaded(game);

        // Complete 3 turns
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        expect(game.totalTurnCount, 3);

        // Hit restart
        game.resetCurrentStage();
        await _pumpUntilCharactersLoaded(game);

        expect(game.totalTurnCount, 0,
            reason: 'First stage starts at 0, so restart should go back to 0');
      },
    );

    testWithGame<StealthGame>(
      'can play turns again after restart and counter resumes from reset value',
      () => StealthGame(levelData: levelData, districtTier: 1),
      (game) async {
        await _pumpUntilCharactersLoaded(game);

        // Do 2 turns, restart, do 1 turn
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        expect(game.totalTurnCount, 2);

        game.resetCurrentStage();
        await _pumpUntilCharactersLoaded(game);
        expect(game.totalTurnCount, 0);

        _waitAllCharacters(game);
        expect(game.totalTurnCount, 1,
            reason: 'After restart from 0, one turn should give 1');
      },
    );
  });

  group('Turn counter reset on failure retry', () {
    // The retry button in the failure overlay calls resetCurrentStage(),
    // so we simulate that flow: play some turns, force a loss, then reset.
    testWithGame<StealthGame>(
      'retry after failure resets turn count to stage start',
      () => StealthGame(levelData: levelData, districtTier: 1),
      (game) async {
        await _pumpUntilCharactersLoaded(game);

        // Play 2 turns
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        expect(game.totalTurnCount, 2);

        // Simulate failure: set status to lost (what the game does when spotted)
        game.gameState.status = GameStatus.lost;

        // Player hits "Retry Stage" which calls resetCurrentStage
        game.resetCurrentStage();
        await _pumpUntilCharactersLoaded(game);

        expect(game.totalTurnCount, 0,
            reason: 'Retry after fail should reset turn count to stage start');
      },
    );

    testWithGame<StealthGame>(
      'can accumulate turns again after failure retry',
      () => StealthGame(levelData: levelData, districtTier: 1),
      (game) async {
        await _pumpUntilCharactersLoaded(game);

        // Play 4 turns, fail, retry, play 2 more
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        expect(game.totalTurnCount, 4);

        game.gameState.status = GameStatus.lost;
        game.resetCurrentStage();
        await _pumpUntilCharactersLoaded(game);
        expect(game.totalTurnCount, 0);

        _waitAllCharacters(game);
        _waitAllCharacters(game);
        expect(game.totalTurnCount, 2,
            reason: 'After retry, turns should accumulate from reset value');
      },
    );
  });

  group('Turn counter with failure overlay (resetCurrentStage)', () {
    testWithGame<StealthGame>(
      'multiple restart cycles maintain correct count',
      () => StealthGame(levelData: levelData, districtTier: 1),
      (game) async {
        await _pumpUntilCharactersLoaded(game);

        // Cycle 1: 3 turns then restart
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        expect(game.totalTurnCount, 3);

        game.resetCurrentStage();
        await _pumpUntilCharactersLoaded(game);
        expect(game.totalTurnCount, 0);

        // Cycle 2: 1 turn then restart
        _waitAllCharacters(game);
        expect(game.totalTurnCount, 1);

        game.resetCurrentStage();
        await _pumpUntilCharactersLoaded(game);
        expect(game.totalTurnCount, 0);

        // Cycle 3: 5 turns — should work fine
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        _waitAllCharacters(game);
        expect(game.totalTurnCount, 5);
      },
    );
  });
}
