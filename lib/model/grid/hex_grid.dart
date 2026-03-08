import 'package:between_the_lines/model/grid/grid_coordinate.dart';

enum TileType {
  empty,
  blocked,
  targetZone, // The zone the player needs to reach
  pressurePlate,
  pressureObstacle,
  teleport,
  hiding,
  unstable,
  crumbled,
}

class HexGrid {
  final int minCol;
  final int maxCol;
  final int minRow;
  final int maxRow;

  final Map<GridCoordinate, TileType> _tiles = {};

  HexGrid(this.minCol, this.maxCol, this.minRow, this.maxRow);

  /// Helper for 0-indexed rectangular grid
  factory HexGrid.rectangle(int width, int height) {
    return HexGrid(0, width - 1, 0, height - 1);
  }

  int get width => (maxCol - minCol).abs() + 1;
  int get height => (maxRow - minRow).abs() + 1;

  TileType getTileType(GridCoordinate coordinate) {
    if (!isWithinBounds(coordinate)) {
      return TileType.blocked; // Treat out of bounds as blocked
    }
    return _tiles[coordinate] ?? TileType.empty;
  }

  void setTileType(GridCoordinate coordinate, TileType type) {
    if (isWithinBounds(coordinate)) {
      _tiles[coordinate] = type;
    }
  }

  bool isWithinBounds(GridCoordinate coordinate) {
    // For a rectangular layout using axial coordinates (pointy-top):
    // The "column" can be approximated by q + r/2
    final col = coordinate.q + (coordinate.r / 2).floor();
    final row = coordinate.r;

    return col >= minCol && col <= maxCol && row >= minRow && row <= maxRow;
  }

  bool isWalkable(GridCoordinate coordinate) {
    final type = getTileType(coordinate);
    return type == TileType.empty ||
        type == TileType.targetZone ||
        type == TileType.teleport ||
        type == TileType.hiding ||
        type == TileType.unstable ||
        type == TileType.pressurePlate;
  }
}
