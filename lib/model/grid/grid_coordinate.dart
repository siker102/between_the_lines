import 'package:flutter/foundation.dart';

@immutable
class GridCoordinate {
  final int q; // Column
  final int r; // Row

  const GridCoordinate(this.q, this.r);

  // The third cubic coordinate, derived from q and r
  int get s => -q - r;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridCoordinate && runtimeType == other.runtimeType && q == other.q && r == other.r;

  @override
  int get hashCode => q.hashCode ^ r.hashCode;

  @override
  String toString() {
    return 'GridCoordinate{q: $q, r: $r, s: $s}';
  }

  // Helper properties for the 6 adjacent flat-topped hexes:
  // (q, r) changes based on typical cubic/axial directions
  List<GridCoordinate> get adjacentCoordinates => [
        GridCoordinate(q + 1, r), // right
        GridCoordinate(q + 1, r - 1), // top right
        GridCoordinate(q, r - 1), // top left
        GridCoordinate(q - 1, r), // left
        GridCoordinate(q - 1, r + 1), // bottom left
        GridCoordinate(q, r + 1), // bottom right
      ];
}
