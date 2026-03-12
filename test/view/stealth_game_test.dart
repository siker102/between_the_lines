import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:between_the_lines/model/level_data.dart';
import 'package:between_the_lines/view/components/character_component.dart';
import 'package:between_the_lines/view/stealth_game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StealthGame resetCurrentStage', () {
    final levelData = LevelData(
      name: 'Test Level',
      stages: [
        StageData(width: 3, height: 4),
        StageData(width: 3, height: 4),
      ],
    );

    testWithGame<StealthGame>(
      'resetCurrentStage on multi-stage level retains proper start coord',
      () => StealthGame(levelData: levelData),
      (game) async {
        // We are initially on Stage 1.
        final stage1LastRow = game.gameState.grid.height - 1; // 3
        expect(game.gameState.characters.first.position.r, stage1LastRow);

        // Find and press Debug Win
        final debugButton = game.camera.viewport.children.whereType<ButtonComponent>().firstWhere(
              (b) => (b.button! as TextComponent).text == 'DEBUG WIN',
            );
        debugButton.onPressed?.call();

        // Pump animation ticks to finish _transitionToNextStage's 1.5s sliding animation.
        for (var i = 0; i < 20; i++) {
          game.update(0.1);
        }

        // We are now on Stage 2. Characters should have been moved to stage 2 bottom.
        final stage2LastRow = game.gameState.grid.height - 1; // 3
        expect(
          game.gameState.characters.first.position.r,
          stage2LastRow,
          reason: 'Characters should be at the bottom after transition',
        );

        // They should also have their hasMoved reset.
        expect(game.gameState.characters.first.hasMoved, false);

        // Now, if we mess up the position (simulating player move)
        game.gameState.characters.first.position = const GridCoordinate(0, 0);

        // Call resetCurrentStage
        game.resetCurrentStage();

        // Wait a tick for the reset to clear UI components if any
        game.update(0.1);

        // They should spawn back at the starting position of stage 2 (the bottom row), NOT row 0
        expect(
          game.gameState.characters.first.position.r,
          stage2LastRow,
          reason: 'Reset should restore characters to stage 2 bottom',
        );
        expect(game.gameState.characters.first.hasMoved, false);
      },
    );
  });

  group('StealthGame teleport', () {
    const teleportCoordA = GridCoordinate(0, 4);
    const teleportCoordB = GridCoordinate(1, 4);
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
    final levelData = LevelData(name: 'Teleport Test', stages: [stageData]);

    testWithGame<StealthGame>(
      'Teleport does NOT fire when destination is occupied (wait case)',
      () => StealthGame(levelData: levelData),
      (game) async {
        final c1 = game.descendants().whereType<CharacterComponent>().firstWhere((cc) => cc.model.id == 'c1');

        // Wait/Double-tap on teleport tile A
        c1.onDoubleTapCallback(c1);
        game.update(0.1);

        expect(
          game.gameState.getCharacter('c1')!.position,
          teleportCoordA,
          reason: 'c1 should stay at A because B is occupied',
        );
        expect(game.gameState.getCharacter('c2')!.position, teleportCoordB, reason: 'c2 should stay at B');
      },
    );

    testWithGame<StealthGame>(
      'Teleport DOES fire when destination is free (wait case)',
      () => StealthGame(levelData: levelData),
      (game) async {
        final c1 = game.descendants().whereType<CharacterComponent>().firstWhere((cc) => cc.model.id == 'c1');

        // Move c2 out of the way
        game.gameState.getCharacter('c2')!.position = const GridCoordinate(0, 2);

        // Wait/Double-tap on teleport tile A
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
