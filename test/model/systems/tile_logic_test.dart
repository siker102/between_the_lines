import 'package:between_the_lines/model/entities/character.dart';
import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/game_state.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Vision Calculator Special Tiles', () {
    test('Characters on a HidingTile do not trigger loss', () {
      final grid = HexGrid.rectangle(5, 5);

      // Enemy at (0, 0) looking right
      final enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 0),
        patrolPath: [],
        visionRange: 3,
        enemyType: EnemyType.directional,
      );

      // Character exactly in vision at (1, 0)
      final charPos = const GridCoordinate(1, 0);
      final character = Character(
        id: 'c1',
        position: charPos,
      );

      // Set the tile to a hiding tile
      grid.setTileType(charPos, TileType.hiding);

      final state = GameState(
        grid: grid,
        characters: [character],
        enemies: [enemy],
      );

      // Update status
      state.updateStatus();

      // Because the character is on a HidingTile, they aren't seen!
      expect(state.status, GameStatus.playing);
    });

    test('Characters NOT on a HidingTile trigger loss', () {
      final grid = HexGrid.rectangle(5, 5);

      final enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 0),
        patrolPath: [],
        visionRange: 3,
        enemyType: EnemyType.directional,
      );

      final charPos = const GridCoordinate(1, 0);
      final character = Character(
        id: 'c1',
        position: charPos,
      );

      // Tile is empty
      grid.setTileType(charPos, TileType.empty);

      final state = GameState(
        grid: grid,
        characters: [character],
        enemies: [enemy],
      );

      // Update status
      state.updateStatus();

      // Enemy spots character
      expect(state.status, GameStatus.lost);
    });
  });
}
