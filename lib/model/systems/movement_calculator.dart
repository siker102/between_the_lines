import 'package:between_the_lines/model/entities/character.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';

enum Reachability {
  /// Tile is walkable and can be moved to.
  walkable,

  /// Tile is occupied by an ally; can pass through but not end turn here.
  blockedByAlly,

  /// Tile is occupied by an enemy; cannot pass through or end turn here.
  blockedByEnemy,

  /// The character's current starting position.
  startPos,
}

class MovementCalculator {
  /// Calculates all reachable coordinates for a character within its moveRange,
  /// considering current unit positions, next-turn enemy positions, and observed tiles.
  static Map<GridCoordinate, Reachability> calculateReachableTiles({
    required HexGrid grid,
    required Character character,
    required Set<GridCoordinate> allyPositions,
    required Set<GridCoordinate> enemyPositions,
    required Set<GridCoordinate> nextTurnEnemyPositions,
    required Set<GridCoordinate> observedTiles,
  }) {
    final start = character.position;
    final range = character.moveRange;

    final reachable = <GridCoordinate, Reachability>{start: Reachability.startPos};
    final queue = <GridCoordinate>[start];
    final costs = <GridCoordinate, int>{start: 0};

    // Current position is always walkable for the character itself (if they stay put)
    // but for UI purposes, we'll start with empty and fill it.

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentCost = costs[current]!;

      if (currentCost >= range) {
        continue;
      }

      for (final adj in current.adjacentCoordinates) {
        if (!grid.isWithinBounds(adj) || !grid.isWalkable(adj)) {
          continue;
        }

        // Cannot pass through enemies
        if (enemyPositions.contains(adj)) {
          // But it's in range, so mark it as blocked by enemy for UI
          reachable[adj] = Reachability.blockedByEnemy;
          continue;
        }

        // Cannot pass through observed tiles (treating them as impassable)
        if (observedTiles.contains(adj)) {
          // Exception: hiding tiles are still landable even when observed.
          // The character becomes hidden upon arrival, so it is safe to move there.
          // We do NOT expand BFS further from this tile (still can't pass through).
          if (grid.getTileType(adj) == TileType.hiding &&
              !allyPositions.contains(adj) &&
              !nextTurnEnemyPositions.contains(adj)) {
            reachable[adj] = Reachability.walkable;
          }
          continue;
        }

        final newCost = currentCost + 1;
        if (!costs.containsKey(adj) || newCost < costs[adj]!) {
          costs[adj] = newCost;

          // Determine reachability status for this tile
          if (allyPositions.contains(adj)) {
            reachable[adj] = Reachability.blockedByAlly;
          } else if (nextTurnEnemyPositions.contains(adj)) {
            reachable[adj] = Reachability.blockedByEnemy;
          } else {
            reachable[adj] = Reachability.walkable;
          }

          queue.add(adj);
        }
      }
    }

    return reachable;
  }
}
