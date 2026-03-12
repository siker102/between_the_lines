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
        grid: grid,
        character: character,
        allyPositions: {},
        enemyPositions: {},
        nextTurnEnemyPositions: {},
        observedTiles: {},
      );

      expect(reachable.length, 7); // 6 adjacent + start position
      expect(reachable[const GridCoordinate(0, 0)], Reachability.startPos);
      expect(reachable.containsKey(const GridCoordinate(1, 0)), isTrue); // right
      expect(reachable[const GridCoordinate(1, 0)], Reachability.walkable);

      expect(reachable.containsKey(const GridCoordinate(1, -1)), isTrue); // top right
      expect(reachable.containsKey(const GridCoordinate(0, -1)), isTrue); // top left
      expect(reachable.containsKey(const GridCoordinate(-1, 0)), isTrue); // left
      expect(reachable.containsKey(const GridCoordinate(-1, 1)), isTrue); // bottom left
      expect(reachable.containsKey(const GridCoordinate(0, 1)), isTrue); // bottom right
    });

    test('calculateReachableTiles respects obstacles and occupancy', () {
      final grid = HexGrid(-5, 5, -5, 5);
      grid.setTileType(const GridCoordinate(1, -1), TileType.blocked); // Block top-right

      final character = Character(
        id: 'c1',
        position: const GridCoordinate(0, 0),
        moveRange: 1,
      );

      final reachable = MovementCalculator.calculateReachableTiles(
        grid: grid,
        character: character,
        allyPositions: {const GridCoordinate(1, 0)}, // Ally on the right
        enemyPositions: {const GridCoordinate(0, 1)}, // Enemy on bottom-right
        nextTurnEnemyPositions: {const GridCoordinate(-1, 1)}, // Enemy moving to bottom-left
        observedTiles: {},
      );

      // Start tile
      expect(reachable[const GridCoordinate(0, 0)], Reachability.startPos);

      // Blocked by grid
      expect(reachable.containsKey(const GridCoordinate(1, -1)), isFalse);

      // Blocked by ally (reachable but marked as blockedByAlly)
      expect(reachable[const GridCoordinate(1, 0)], Reachability.blockedByAlly);

      // Blocked by enemy (cannot pass through, marked as blockedByEnemy)
      expect(reachable[const GridCoordinate(0, 1)], Reachability.blockedByEnemy);

      // Blocked by next turn enemy
      expect(reachable[const GridCoordinate(-1, 1)], Reachability.blockedByEnemy);

      // Walkable
      expect(reachable[const GridCoordinate(-1, 0)], Reachability.walkable);
    });

    test('calculateReachableTiles blocks movement through observed tiles', () {
      final grid = HexGrid(-5, 5, -5, 5);
      final character = Character(
        id: 'c1',
        position: const GridCoordinate(0, 0),
      );

      // (1, 0) is observed by an enemy
      final observedTiles = {const GridCoordinate(1, 0)};

      final reachable = MovementCalculator.calculateReachableTiles(
        grid: grid,
        character: character,
        allyPositions: {},
        enemyPositions: {},
        nextTurnEnemyPositions: {},
        observedTiles: observedTiles,
      );

      // (1, 0) should NOT be reachable because it is observed
      expect(reachable.containsKey(const GridCoordinate(1, 0)), isFalse);

      // (0, 0) should be Reachability.startPos
      expect(reachable[const GridCoordinate(0, 0)], Reachability.startPos);

      // (2, 0) should NOT be reachable because (1, 0) is impassable/blocked
      expect(reachable.containsKey(const GridCoordinate(2, 0)), isFalse);
    });

    test('calculateReachableTiles allows landing on observed hiding tile', () {
      final grid = HexGrid(-5, 5, -5, 5);
      grid.setTileType(const GridCoordinate(1, 0), TileType.hiding);

      final character = Character(
        id: 'c1',
        position: const GridCoordinate(0, 0),
        moveRange: 1,
      );

      final reachable = MovementCalculator.calculateReachableTiles(
        grid: grid,
        character: character,
        allyPositions: {},
        enemyPositions: {},
        nextTurnEnemyPositions: {},
        observedTiles: {const GridCoordinate(1, 0)},
      );

      expect(reachable[const GridCoordinate(1, 0)], Reachability.walkable);
    });

    test('calculateReachableTiles does not expand BFS through observed hiding tile', () {
      final grid = HexGrid(-5, 5, -5, 5);
      grid.setTileType(const GridCoordinate(1, 0), TileType.hiding);

      final character = Character(
        id: 'c1',
        position: const GridCoordinate(0, 0),
        moveRange: 3,
      );

      // (1, 0) and (2, 0) are observed; (2, 0) is a normal empty tile
      final observedTiles = {
        const GridCoordinate(1, 0),
        const GridCoordinate(2, 0),
      };

      final reachable = MovementCalculator.calculateReachableTiles(
        grid: grid,
        character: character,
        allyPositions: {},
        enemyPositions: {},
        nextTurnEnemyPositions: {},
        observedTiles: observedTiles,
      );

      expect(reachable[const GridCoordinate(1, 0)], Reachability.walkable);
      expect(reachable.containsKey(const GridCoordinate(2, 0)), isFalse);
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
