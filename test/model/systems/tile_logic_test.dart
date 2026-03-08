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
      );

      // Character exactly in vision at (1, 0)
      const charPos = GridCoordinate(1, 0);
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
      );

      const charPos = GridCoordinate(1, 0);
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

  group('Tile Walkability', () {
    test('Crumbled UnstableTiles act like blocked tiles', () {
      final grid = HexGrid.rectangle(3, 3);
      const charPos = GridCoordinate(0, 0);
      const destPos = GridCoordinate(2, 0);

      // Set middle tile to crumbled
      const middlePos = GridCoordinate(1, 0);
      grid.setTileType(middlePos, TileType.crumbled);

      // Verify the HexGrid refuses to consider it walkable
      expect(grid.isWalkable(middlePos), isFalse);

      // Also verify empty tiles ARE walkable to prove the contrast
      expect(grid.isWalkable(destPos), isTrue);
    });
  });
}
