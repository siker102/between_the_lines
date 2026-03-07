import 'dart:collection';

import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';

/// Calculates visible tiles for enemies based on their [EnemyType].
///
/// New vision strategies can be added by:
/// 1. Adding a value to [EnemyType].
/// 2. Creating a `_calculate<Type>Vision` method here.
/// 3. Adding the case to [calculateVision].
class VisionCalculator {
  static Set<GridCoordinate> calculateVision(
    HexGrid grid,
    Enemy enemy,
  ) {
    switch (enemy.enemyType) {
      case EnemyType.linear:
        return _calculateLinearVision(grid, enemy);
      case EnemyType.radial:
        return _calculateRadialVision(grid, enemy);
      case EnemyType.directional:
        return _calculateDirectionalVision(grid, enemy);
    }
  }

  // ── Linear: straight ray, no widening ──

  static Set<GridCoordinate> _calculateLinearVision(
    HexGrid grid,
    Enemy enemy,
  ) {
    final visible = <GridCoordinate>{};
    final start = enemy.position;

    for (var i = 1; i <= enemy.visionRange; i++) {
      final pos = _stepInDirection(start, enemy.facing, i);
      if (!grid.isWithinBounds(pos)) {
        break;
      }
      if (grid.getTileType(pos) == TileType.blocked) {
        break;
      }
      visible.add(pos);
    }
    return visible;
  }

  // ── Radial: BFS flood in all directions ──

  static Set<GridCoordinate> _calculateRadialVision(
    HexGrid grid,
    Enemy enemy,
  ) {
    final visible = <GridCoordinate>{};
    final queue = Queue<_BfsNode>();
    final visited = <GridCoordinate>{enemy.position};

    queue.add(_BfsNode(enemy.position, 0));

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      if (node.dist > 0) {
        visible.add(node.coord);
      }
      if (node.dist >= enemy.visionRange) {
        continue;
      }

      for (final neighbor in node.coord.adjacentCoordinates) {
        if (visited.contains(neighbor)) {
          continue;
        }
        visited.add(neighbor);
        if (!grid.isWithinBounds(neighbor)) {
          continue;
        }
        if (grid.getTileType(neighbor) == TileType.blocked) {
          continue;
        }
        queue.add(_BfsNode(neighbor, node.dist + 1));
      }
    }
    return visible;
  }

  // ── Directional: straight ray + cone widening ──

  static Set<GridCoordinate> _calculateDirectionalVision(
    HexGrid grid,
    Enemy enemy,
  ) {
    final visible = <GridCoordinate>{};
    final start = enemy.position;

    for (var i = 1; i <= enemy.visionRange; i++) {
      final pos = _stepInDirection(start, enemy.facing, i);
      if (!grid.isWithinBounds(pos)) {
        break;
      }
      if (grid.getTileType(pos) == TileType.blocked) {
        break;
      }
      visible.add(pos);

      // Cone: add neighbors at the same hex distance
      if (i > 1) {
        for (final neighbor in pos.adjacentCoordinates) {
          if (_hexDistance(neighbor, start) == i) {
            _tryAdd(grid, neighbor, visible);
          }
        }
      }
    }
    return visible;
  }

  // ── Shared helpers ──

  /// Steps [distance] tiles from [origin] in [dir].
  static GridCoordinate _stepInDirection(
    GridCoordinate origin,
    Direction dir,
    int distance,
  ) {
    final d = _directionOffset(dir);
    return GridCoordinate(
      origin.q + d.q * distance,
      origin.r + d.r * distance,
    );
  }

  /// Returns the unit axial offset for a [Direction].
  static GridCoordinate _directionOffset(Direction dir) {
    switch (dir) {
      case Direction.right:
        return const GridCoordinate(1, 0);
      case Direction.topRight:
        return const GridCoordinate(1, -1);
      case Direction.topLeft:
        return const GridCoordinate(0, -1);
      case Direction.left:
        return const GridCoordinate(-1, 0);
      case Direction.bottomLeft:
        return const GridCoordinate(-1, 1);
      case Direction.bottomRight:
        return const GridCoordinate(0, 1);
    }
  }

  /// Hex (cube) distance between two axial coordinates.
  static int _hexDistance(GridCoordinate a, GridCoordinate b) {
    return ((a.q - b.q).abs() + (a.r - b.r).abs() + (a.s - b.s).abs()) ~/ 2;
  }

  static void _tryAdd(
    HexGrid grid,
    GridCoordinate pos,
    Set<GridCoordinate> visible,
  ) {
    if (grid.isWithinBounds(pos) && grid.getTileType(pos) != TileType.blocked) {
      visible.add(pos);
    }
  }
}

class _BfsNode {
  final GridCoordinate coord;
  final int dist;
  const _BfsNode(this.coord, this.dist);
}
