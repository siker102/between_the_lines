import 'dart:collection';

import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';

/// BFS pathfinding on the hex grid.
class Pathfinding {
  /// Returns the shortest walkable path from [from] to [to],
  /// including both endpoints. Returns empty list if no path.
  static List<GridCoordinate> findPath(
    HexGrid grid,
    GridCoordinate from,
    GridCoordinate to,
  ) {
    if (from == to) {
      return [from];
    }

    final visited = <GridCoordinate>{from};
    final cameFrom = <GridCoordinate, GridCoordinate>{};
    final queue = Queue<GridCoordinate>()..add(from);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();

      for (final neighbor in current.adjacentCoordinates) {
        if (visited.contains(neighbor)) {
          continue;
        }
        if (!grid.isWithinBounds(neighbor)) {
          continue;
        }
        if (!grid.isWalkable(neighbor) && neighbor != to) {
          continue;
        }

        visited.add(neighbor);
        cameFrom[neighbor] = current;

        if (neighbor == to) {
          return _reconstructPath(cameFrom, from, to);
        }

        queue.add(neighbor);
      }
    }

    // No path found
    return [];
  }

  /// Expands a list of waypoints into a full tile-by-tile
  /// route by chaining [findPath] between consecutive pairs.
  static List<GridCoordinate> expandWaypoints(
    HexGrid grid,
    List<GridCoordinate> waypoints,
  ) {
    if (waypoints.length < 2) {
      return List.of(waypoints);
    }

    final expanded = <GridCoordinate>[];

    for (var i = 0; i < waypoints.length - 1; i++) {
      final segment = findPath(grid, waypoints[i], waypoints[i + 1]);
      if (segment.isEmpty) {
        continue;
      }
      // Avoid duplicating the connecting waypoint
      if (expanded.isNotEmpty && segment.first == expanded.last) {
        expanded.addAll(segment.skip(1));
      } else {
        expanded.addAll(segment);
      }
    }

    return expanded;
  }

  static List<GridCoordinate> _reconstructPath(
    Map<GridCoordinate, GridCoordinate> cameFrom,
    GridCoordinate from,
    GridCoordinate to,
  ) {
    final path = <GridCoordinate>[to];
    var current = to;
    while (current != from) {
      current = cameFrom[current]!;
      path.add(current);
    }
    return path.reversed.toList();
  }
}
