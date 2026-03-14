import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';

/// Calculates visible tiles for enemies based on their [EnemyType].
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
      case EnemyType.camera:
        return _calculateCameraVision(grid, enemy);
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
      if (!_hasLineOfSight(grid, start, pos)) {
        break; // if sight is blocked here, it is blocked further down the ray
      }
      visible.add(pos);
    }
    return visible;
  }

  // ── Radial: Flood within range and check LoS ──

  static Set<GridCoordinate> _calculateRadialVision(
    HexGrid grid,
    Enemy enemy,
  ) {
    final visible = <GridCoordinate>{};
    final start = enemy.position;
    final r = enemy.visionRange;

    for (var dq = -r; dq <= r; dq++) {
      for (var dr = -r; dr <= r; dr++) {
        final pos = GridCoordinate(start.q + dq, start.r + dr);
        if (_hexDistance(start, pos) <= r && pos != start) {
          if (_hasLineOfSight(grid, start, pos)) {
            visible.add(pos);
          }
        }
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

      if (_hasLineOfSight(grid, start, pos)) {
        visible.add(pos);
      }

      // Cone: add neighbors at the same hex distance
      if (i > 1) {
        for (final neighbor in pos.adjacentCoordinates) {
          if (_hexDistance(neighbor, start) == i) {
            if (_hasLineOfSight(grid, start, neighbor)) {
              visible.add(neighbor);
            }
          }
        }
      }
    }
    return visible;
  }

  // ── Camera: fixed 4-tile pattern ──

  static Set<GridCoordinate> _calculateCameraVision(
    HexGrid grid,
    Enemy enemy,
  ) {
    final visible = <GridCoordinate>{};
    final start = enemy.position;
    final dir = enemy.facing;

    const order = [
      Direction.right,
      Direction.topRight,
      Direction.topLeft,
      Direction.left,
      Direction.bottomLeft,
      Direction.bottomRight,
    ];

    final dirIdx = order.indexOf(dir);
    final leftDir = order[(dirIdx - 1 + 6) % 6];
    final rightDir = order[(dirIdx + 1) % 6];

    // Front 1: one step ahead
    final front1 = _stepInDirection(start, dir, 1);
    if (grid.isWithinBounds(front1) && _hasLineOfSight(grid, start, front1)) {
      visible.add(front1);

      // Front 2: two steps ahead
      final front2 = _stepInDirection(start, dir, 2);
      if (grid.isWithinBounds(front2) && _hasLineOfSight(grid, start, front2)) {
        visible.add(front2);
      }

      // Front-Left: from front1, one step in the left-adjacent direction
      final frontLeft = _stepInDirection(front1, leftDir, 1);
      if (grid.isWithinBounds(frontLeft) && _hasLineOfSight(grid, start, frontLeft)) {
        visible.add(frontLeft);
      }

      // Front-Right: from front1, one step in the right-adjacent direction
      final frontRight = _stepInDirection(front1, rightDir, 1);
      if (grid.isWithinBounds(frontRight) && _hasLineOfSight(grid, start, frontRight)) {
        visible.add(frontRight);
      }
    }

    return visible;
  }

  // ── Line of Sight Helpers ──

  /// Verifies if a straight line from [start] to [end] is clear of blocks.
  static bool _hasLineOfSight(HexGrid grid, GridCoordinate start, GridCoordinate end) {
    final line = _hexLinedraw(start, end);
    for (var i = 0; i < line.length; i++) {
      final pos = line[i];
      if (!grid.isWithinBounds(pos)) return false;
      // start tile never blocks its own line of sight
      if (pos != start) {
        final type = grid.getTileType(pos);
        if (type == TileType.blocked || type == TileType.pressureObstacle || type == TileType.crumbled) {
          return false;
        }
      }
    }
    return true;
  }

  /// Calculates the hexes intersected by a straight line between [a] and [b].
  static List<GridCoordinate> _hexLinedraw(GridCoordinate a, GridCoordinate b) {
    final n = _hexDistance(a, b);
    final results = <GridCoordinate>[];
    if (n == 0) {
      results.add(a);
      return results;
    }

    // Add a small epsilon to coordinates to nudge the line
    // This avoids edge/corner ambiguity by consistently picking one side.
    const epsilonQ = 1e-6;
    const epsilonR = 1e-6;
    const epsilonS = -2e-6;

    final aQ = a.q + epsilonQ;
    final aR = a.r + epsilonR;
    final aS = a.s + epsilonS;

    final bQ = b.q + epsilonQ;
    final bR = b.r + epsilonR;
    final bS = b.s + epsilonS;

    for (var i = 0; i <= n; i++) {
      final t = n == 0 ? 0.0 : i / n;
      final q = aQ + (bQ - aQ) * t;
      final r = aR + (bR - aR) * t;
      final s = aS + (bS - aS) * t;
      results.add(_cubeRound(q, r, s));
    }
    return results;
  }

  /// Converts fractional cube coordinates back to the nearest hex grid coordinate.
  static GridCoordinate _cubeRound(double fracQ, double fracR, double fracS) {
    var q = fracQ.round();
    var r = fracR.round();
    final s = fracS.round();

    final qDiff = (q - fracQ).abs();
    final rDiff = (r - fracR).abs();
    final sDiff = (s - fracS).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      q = -r - s;
    } else if (rDiff > sDiff) {
      r = -q - s;
    }
    return GridCoordinate(q, r);
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
}
