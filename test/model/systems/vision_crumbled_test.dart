import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:between_the_lines/model/systems/vision_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Crumbled tiles block enemy vision', () {
    test('linear enemy cannot see past a crumbled tile', () {
      final grid = HexGrid.rectangle(5, 5);
      const crumbledPos = GridCoordinate(1, 0);
      grid.setTileType(crumbledPos, TileType.crumbled);

      final enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 0),
        patrolPath: [],
        enemyType: EnemyType.linear,
      );

      final visible = VisionCalculator.calculateVision(grid, enemy);

      // The crumbled tile itself should NOT be visible (it blocks at that tile)
      expect(visible.contains(crumbledPos), isFalse);
      // Tiles beyond should also not be visible
      expect(visible.contains(const GridCoordinate(2, 0)), isFalse);
      expect(visible.contains(const GridCoordinate(3, 0)), isFalse);
    });

    test('radial enemy cannot see past a crumbled tile', () {
      final grid = HexGrid.rectangle(5, 5);
      const crumbledPos = GridCoordinate(1, 0);
      grid.setTileType(crumbledPos, TileType.crumbled);

      final enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 0),
        patrolPath: [],
        visionRange: 3,
        enemyType: EnemyType.radial,
      );

      final visible = VisionCalculator.calculateVision(grid, enemy);

      expect(visible.contains(crumbledPos), isFalse);
      expect(visible.contains(const GridCoordinate(2, 0)), isFalse);
    });

    test('directional enemy cannot see past a crumbled tile', () {
      final grid = HexGrid.rectangle(5, 5);
      const crumbledPos = GridCoordinate(1, 0);
      grid.setTileType(crumbledPos, TileType.crumbled);

      final enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 0),
        patrolPath: [],
      );

      final visible = VisionCalculator.calculateVision(grid, enemy);

      expect(visible.contains(crumbledPos), isFalse);
      expect(visible.contains(const GridCoordinate(2, 0)), isFalse);
    });

    test('unstable tile (not yet crumbled) does NOT block vision', () {
      final grid = HexGrid.rectangle(5, 5);
      const unstablePos = GridCoordinate(1, 0);
      grid.setTileType(unstablePos, TileType.unstable);

      final enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 0),
        patrolPath: [],
        enemyType: EnemyType.linear,
      );

      final visible = VisionCalculator.calculateVision(grid, enemy);

      // Unstable tile and tiles beyond it should be visible
      expect(visible.contains(unstablePos), isTrue);
      expect(visible.contains(const GridCoordinate(2, 0)), isTrue);
    });
  });
}
