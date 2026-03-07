import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Enemy', () {
    late HexGrid grid;

    setUp(() {
      grid = HexGrid.rectangle(10, 10);
    });

    test('initializePath expands waypoints correctly', () {
      final enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 0),
        patrolPath: [const GridCoordinate(0, 0), const GridCoordinate(2, 0)],
      );

      enemy.initializePath(grid);

      expect(enemy.expandedPath.length, 3);
      expect(enemy.expandedPath[1], const GridCoordinate(1, 0));
      expect(enemy.expandedPath[2], const GridCoordinate(2, 0));
    });

    test('advancePatrol moves forward and backward', () {
      final enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(0, 0),
        patrolPath: [const GridCoordinate(0, 0), const GridCoordinate(1, 0)],
      );
      enemy.initializePath(grid);

      // Initial: (0,0)
      enemy.advancePatrol();
      expect(enemy.position, const GridCoordinate(1, 0));
      expect(enemy.facing, Direction.right);

      // End of path, should turn around
      enemy.advancePatrol();
      expect(enemy.position, const GridCoordinate(0, 0));
      expect(enemy.facing, Direction.left);
    });

    test('facing updates correctly for various directions', () {
      final enemy = Enemy(
        id: 'e1',
        position: const GridCoordinate(1, 1),
        patrolPath: [const GridCoordinate(1, 1), const GridCoordinate(1, 0)], // Top left move: dq=0, dr=-1
      );
      enemy.initializePath(grid);

      enemy.advancePatrol();
      expect(enemy.facing, Direction.topLeft);
    });
  });
}
