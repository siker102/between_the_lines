import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/level_data.dart';
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
        expect(game.gameState.characters.first.position.r, stage2LastRow,
            reason: 'Characters should be at the bottom after transition');

        // They should also have their hasMoved reset.
        expect(game.gameState.characters.first.hasMoved, false);

        // Now, if we mess up the position (simulating player move)
        game.gameState.characters.first.position = const GridCoordinate(0, 0);

        // Call resetCurrentStage
        game.resetCurrentStage();

        // Wait a tick for the reset to clear UI components if any
        game.update(0.1);

        // They should spawn back at the starting position of stage 2 (the bottom row), NOT row 0
        expect(game.gameState.characters.first.position.r, stage2LastRow,
            reason: 'Reset should restore characters to stage 2 bottom');
        expect(game.gameState.characters.first.hasMoved, false);
      },
    );
  });
}
