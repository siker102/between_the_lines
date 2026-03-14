import 'package:between_the_lines/model/entities/entity.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:between_the_lines/model/systems/pathfinding.dart';

enum Direction {
  right,
  topRight,
  topLeft,
  left,
  bottomLeft,
  bottomRight,
}

/// Determines how an enemy sees tiles.
enum EnemyType {
  /// Sees in a straight line only (no cone widening).
  linear,

  /// Sees N tiles in all directions (ignores facing).
  radial,

  /// Sees a cone in the facing direction (default).
  directional,

  /// Stationary camera that rotates facing each turn.
  camera,
}

class Enemy extends Entity {
  final int visionRange;
  final EnemyType enemyType;
  final List<GridCoordinate> patrolPath;

  /// +1 = clockwise, -1 = counter-clockwise. Used by camera enemies.
  final int turnDirection;

  List<GridCoordinate> _expandedPath = [];
  int _currentPathIndex = 0;
  bool _patrolForward = true;

  Direction facing;

  Enemy({
    required super.id,
    required super.position,
    required this.patrolPath,
    this.visionRange = 4,
    this.facing = Direction.right,
    this.enemyType = EnemyType.directional,
    this.turnDirection = 1,
  });

  /// Creates a fresh copy with the original construction parameters.
  Enemy clone() => Enemy(
        id: id,
        position: patrolPath.isNotEmpty ? patrolPath.first : position,
        patrolPath: List.of(patrolPath),
        visionRange: visionRange,
        enemyType: enemyType,
        facing: facing,
        turnDirection: turnDirection,
      );

  /// The full tile-by-tile route.
  List<GridCoordinate> get expandedPath => _expandedPath;

  /// Compute the expanded tile-by-tile path from waypoints.
  void initializePath(HexGrid grid) {
    _expandedPath = Pathfinding.expandWaypoints(
      grid,
      patrolPath,
      walkCheck: grid.isEnemyWalkable,
    );
    _currentPathIndex = _expandedPath.indexOf(position);
    if (_currentPathIndex < 0) {
      _currentPathIndex = 0;
    }
    // Set initial facing toward the next patrol step (skip for camera — uses constructor-defined facing)
    if (enemyType != EnemyType.camera && _expandedPath.length >= 2) {
      final next = nextPosition;
      if (next != position) {
        facing = _facingFromDelta(next.q - position.q, next.r - position.r);
      }
    }
  }

  /// Where this enemy will move next turn (peek only).
  GridCoordinate get nextPosition {
    if (enemyType == EnemyType.camera) {
      return position;
    }
    if (_expandedPath.length < 2) {
      return position;
    }
    var idx = _currentPathIndex;
    final fwd = _patrolForward;
    if (fwd) {
      idx++;
      if (idx >= _expandedPath.length) {
        idx = _expandedPath.length - 2;
      }
    } else {
      idx--;
      if (idx < 0) {
        idx = 1;
      }
    }
    return _expandedPath[idx];
  }

  /// Facing direction after the next move.
  Direction get nextFacing {
    if (enemyType == EnemyType.camera) {
      return _rotateDirection(facing, turnDirection);
    }
    final next = nextPosition;
    if (next == position) {
      return facing;
    }
    return _facingFromDelta(
      next.q - position.q,
      next.r - position.r,
    );
  }

  /// Advance one tile along the expanded path.
  void advancePatrol() {
    // Camera enemies rotate in place instead of moving
    if (enemyType == EnemyType.camera) {
      facing = _rotateDirection(facing, turnDirection);
      return;
    }

    if (_expandedPath.length < 2) {
      return;
    }

    if (_patrolForward) {
      _currentPathIndex++;
      if (_currentPathIndex >= _expandedPath.length) {
        _currentPathIndex = _expandedPath.length - 2;
        _patrolForward = false;
      }
    } else {
      _currentPathIndex--;
      if (_currentPathIndex < 0) {
        _currentPathIndex = 1;
        _patrolForward = true;
      }
    }

    final nextPos = _expandedPath[_currentPathIndex];
    _updateFacing(position, nextPos);
    position = nextPos;
  }

  void _updateFacing(
    GridCoordinate oldPos,
    GridCoordinate newPos,
  ) {
    facing = _facingFromDelta(
      newPos.q - oldPos.q,
      newPos.r - oldPos.r,
    );
  }

  static Direction _rotateDirection(Direction dir, int turnDir) {
    const order = [
      Direction.right,
      Direction.topRight,
      Direction.topLeft,
      Direction.left,
      Direction.bottomLeft,
      Direction.bottomRight,
    ];
    final idx = order.indexOf(dir);
    final newIdx = (idx + turnDir) % order.length;
    return order[newIdx < 0 ? newIdx + order.length : newIdx];
  }

  static Direction _facingFromDelta(int dq, int dr) {
    if (dq > 0 && dr == 0) {
      return Direction.right;
    } else if (dq > 0 && dr < 0) {
      return Direction.topRight;
    } else if (dq == 0 && dr < 0) {
      return Direction.topLeft;
    } else if (dq < 0 && dr == 0) {
      return Direction.left;
    } else if (dq < 0 && dr > 0) {
      return Direction.bottomLeft;
    }
    return Direction.bottomRight;
  }
}
