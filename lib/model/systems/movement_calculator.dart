import 'package:between_the_lines/model/entities/character.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';

class MovementCalculator {
  /// Calculates all reachable coordinates for a character within its moveRange.
  /// Uses a basic Breadth-First Search (BFS).
  static Set<GridCoordinate> calculateReachableTiles(
      HexGrid grid, Character character,) {
    final start = character.position;
    final range = character.moveRange;

    final reachable = <GridCoordinate>{start};
    final queue = <GridCoordinate>[start];
    final costs = <GridCoordinate, int>{start: 0};

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

        final newCost = currentCost + 1;
        if (!costs.containsKey(adj) || newCost < costs[adj]!) {
          costs[adj] = newCost;
          reachable.add(adj);
          queue.add(adj);
        }
      }
    }

    return reachable;
  }
}
