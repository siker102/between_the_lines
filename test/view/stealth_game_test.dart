import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:between_the_lines/model/level_data.dart';
import 'package:between_the_lines/view/components/character_component.dart';
import 'package:between_the_lines/view/stealth_game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps Flame's component lifecycle until CharacterComponents are mounted,
/// or gives up after several rounds.
Future<void> _pumpUntilCharactersLoaded(StealthGame game) async {
  for (var i = 0; i < 50; i++) {
    await Future.delayed(Duration.zero);
    game.update(0);
    if (game.world.children.whereType<CharacterComponent>().isNotEmpty) return;
  }
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);
  group('StealthGame resetCurrentStage', () {
    final levelData = LevelData(
      name: 'Test Level',
      stages: [StageData(width: 3, height: 4)],
      characterStartX: [1, 2],
    );

    testWithGame<StealthGame>(
      'resetCurrentStage restores characters to stage start positions',
      () => StealthGame(levelData: levelData),
      (game) async {
        final lastRow = game.gameState.grid.height - 1; // 3
        expect(game.gameState.characters.first.position.r, lastRow);

        // Simulate player moving a character away
        game.gameState.characters.first.position = const GridCoordinate(0, 0);
        game.gameState.characters.first.hasMoved = true;

        game.resetCurrentStage();

        // Characters should be restored to their starting positions
        expect(
          game.gameState.characters.first.position.r,
          lastRow,
          reason: 'resetCurrentStage should restore characters to stage bottom',
        );
        expect(game.gameState.characters.first.hasMoved, false);
      },
    );
  });

  group('StealthGame teleport', () {
    const teleportCoordA = GridCoordinate(-1, 4);
    const teleportCoordB = GridCoordinate(0, 4);
    final stageData = StageData(
      width: 3,
      height: 5,
      specialTiles: {
        teleportCoordA: TileType.teleport,
        teleportCoordB: TileType.teleport,
      },
      teleportLinks: {
        teleportCoordA: teleportCoordB,
        teleportCoordB: teleportCoordA,
      },
    );
    final levelData = LevelData(name: 'Teleport Test', stages: [stageData], characterStartX: [1, 2]);

    testWithGame<StealthGame>(
      'Teleport does NOT fire when destination is occupied (wait case)',
      () => StealthGame(levelData: levelData),
      (game) async {
        await _pumpUntilCharactersLoaded(game);

        // c1 spawns at (-1,4) = teleportCoordA, c2 spawns at (0,4) = teleportCoordB
        final c1 = game.world.children.whereType<CharacterComponent>().firstWhere((cc) => cc.model.id == 'c1');
        c1.onDoubleTapCallback(c1);
        game.update(0.1);

        expect(
          game.gameState.getCharacter('c1')!.position,
          teleportCoordA,
          reason: 'c1 should stay at A because B is occupied by c2',
        );
      },
    );

    testWithGame<StealthGame>(
      'Teleport DOES fire when destination is free (wait case)',
      () => StealthGame(levelData: levelData),
      (game) async {
        await _pumpUntilCharactersLoaded(game);

        final c1 = game.world.children.whereType<CharacterComponent>().firstWhere((cc) => cc.model.id == 'c1');

        // Move c2 away from teleportCoordB so the destination is free
        game.gameState.getCharacter('c2')!.position = const GridCoordinate(0, 2);

        c1.onDoubleTapCallback(c1);
        game.update(0.1);

        expect(
          game.gameState.getCharacter('c1')!.position,
          teleportCoordB,
          reason: 'c1 should teleport to B because it is free',
        );
      },
    );
  });
}
