import 'package:between_the_lines/model/entities/character.dart';
import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:between_the_lines/model/systems/movement_calculator.dart';
import 'package:between_the_lines/model/systems/vision_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MovementCalculator', () {
    test('calculateReachableTiles returns correct set for open hex grid', () {
      final grid = HexGrid(-5, 5, -5, 5);
      final character = Character(
        id: 'c1',
        position: const GridCoordinate(0, 0),
        moveRange: 1,
      );

      final reachable = MovementCalculator.calculateReachableTiles(
        grid,
        character,
      );

      expect(reachable.length, 7); // Center + 6 adjacent
      expect(reachable.contains(const GridCoordinate(0, 0)), isTrue);
      expect(reachable.contains(const GridCoordinate(1, 0)), isTrue); // right
      expect(
        reachable.contains(const GridCoordinate(1, -1)),
        isTrue,
      ); // top right
      expect(
        reachable.contains(const GridCoordinate(0, -1)),
        isTrue,
      ); // top left
      expect(reachable.contains(const GridCoordinate(-1, 0)), isTrue); // left
      expect(
        reachable.contains(const GridCoordinate(-1, 1)),
        isTrue,
      ); // bottom left
      expect(
        reachable.contains(const GridCoordinate(0, 1)),
        isTrue,
      ); // bottom right
    });

    test('calculateReachableTiles respects obstacles on hex grid', () {
      final grid = HexGrid(-5, 5, -5, 5);
      grid.setTileType(
        const GridCoordinate(1, 0),
        TileType.blocked,
      ); // Block the right tile

      final character = Character(
        id: 'c1',
        position: const GridCoordinate(0, 0),
        moveRange: 1,
      );

      final reachable = MovementCalculator.calculateReachableTiles(
        grid,
        character,
      );

      expect(reachable.length, 6);
      expect(reachable.contains(const GridCoordinate(1, 0)), isFalse);
    });
  });

  group('VisionCalculator', () {
    test('calculateVision returns correct linear tiles on hex grid', () {
      final grid = HexGrid(-5, 5, -5, 5);
      final enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 0),
        patrolPath: [],
        visionRange: 3,
      );

      final vision = VisionCalculator.calculateVision(grid, enemy);

      // facing right(1, 0)
      expect(vision.contains(const GridCoordinate(1, 0)), isTrue);
      expect(vision.contains(const GridCoordinate(2, 0)), isTrue);
      expect(vision.contains(const GridCoordinate(3, 0)), isTrue);

      // With our simple cone addition, at dist 2 we include neighbors of (2,0)
      // that are dist 2 from origin
      expect(
        vision.contains(const GridCoordinate(2, -1)),
        isTrue,
      ); // top right neighbor of the ray
      expect(
        vision.contains(const GridCoordinate(1, 1)),
        isTrue,
      ); // bottom right neighbor of the ray...wait, hex math
      // Let's assure it gets the primary straight ray accurately for now
    });

    test('calculateVision respects line of sight blockers on hex grid', () {
      final grid = HexGrid(-5, 5, -5, 5);
      grid.setTileType(const GridCoordinate(2, 0), TileType.blocked);
      final enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 0),
        patrolPath: [],
        visionRange: 3,
      );

      final vision = VisionCalculator.calculateVision(grid, enemy);

      // Should stop at 1,0
      expect(vision.contains(const GridCoordinate(1, 0)), isTrue);
      expect(vision.contains(const GridCoordinate(2, 0)), isFalse);
      expect(vision.contains(const GridCoordinate(3, 0)), isFalse);
    });
  });
}
