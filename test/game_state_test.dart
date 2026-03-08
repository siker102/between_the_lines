import 'package:between_the_lines/model/entities/character.dart';
import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/game_state.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState', () {
    late HexGrid grid;
    late Character char1;
    late Character char2;
    late Enemy enemy;

    setUp(() {
      grid = HexGrid.rectangle(10, 10);
      char1 = Character(id: 'c1', position: const GridCoordinate(0, 0));
      char2 = Character(id: 'c2', position: const GridCoordinate(1, 0));
      enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(5, 5),
        patrolPath: [const GridCoordinate(5, 5), const GridCoordinate(6, 5)],
      );
      enemy.initializePath(grid);
    });

    test('endTurn resets hasMoved and advances patrol', () {
      final state = GameState(
        grid: grid,
        characters: [char1],
        enemies: [enemy],
      );

      char1.hasMoved = true;
      final initialEnemyPos = enemy.position;

      state.endTurn();

      expect(char1.hasMoved, isFalse);
      expect(enemy.position, isNot(initialEnemyPos));
    });

    test('win condition: all characters in target zone', () {
      grid.setTileType(const GridCoordinate(0, 0), TileType.targetZone);
      grid.setTileType(const GridCoordinate(1, 0), TileType.targetZone);

      final state = GameState(
        grid: grid,
        characters: [char1, char2],
        enemies: [],
      );

      state.endTurn();
      expect(state.status, GameStatus.won);
    });

    test('loss condition: character spotted by enemy', () {
      // Place character in enemy vision (default directional, facing right)
      // Linear/Directional facing right covers (6,5), (7,5) etc if range allows
      final spottingEnemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 5),
        patrolPath: [],
        visionRange: 5,
      );
      char1.position = const GridCoordinate(2, 5);

      final state = GameState(
        grid: grid,
        characters: [char1],
        enemies: [spottingEnemy],
      );

      state.endTurn();
      expect(state.status, GameStatus.lost);
    });

    test('dynamic status update: win without ending turn', () {
      grid.setTileType(const GridCoordinate(0, 0), TileType.targetZone);
      grid.setTileType(const GridCoordinate(1, 0), TileType.targetZone);

      final state = GameState(
        grid: grid,
        characters: [char1, char2],
        enemies: [],
      );

      // Start them outside
      char1.position = const GridCoordinate(5, 0);
      char2.position = const GridCoordinate(6, 0);

      // Initially playing
      state.updateStatus();
      expect(state.status, GameStatus.playing);

      // Move char1 to zone
      char1.position = const GridCoordinate(0, 0);
      state.updateStatus();
      expect(state.status, GameStatus.playing); // Not won yet, char2 is left

      // Move char2 to zone
      char2.position = const GridCoordinate(1, 0);
      state.updateStatus();
      expect(state.status, GameStatus.won); // Won immediately!
    });

    test('dynamic status update: loss without ending turn', () {
      final spottingEnemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 5),
        patrolPath: [],
        visionRange: 5,
      );

      final state = GameState(
        grid: grid,
        characters: [char1],
        enemies: [spottingEnemy],
      );

      // Initially playing
      expect(state.status, GameStatus.playing);

      // Move char1 into vision
      char1.position = const GridCoordinate(2, 5);
      state.updateStatus();
      expect(state.status, GameStatus.lost); // Lost immediately!
    });
  });
}
