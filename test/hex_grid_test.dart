import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HexGrid', () {
    test('rectangle constructor creates correct bounds', () {
      final grid = HexGrid.rectangle(6, 13);

      expect(grid.width, 6);
      expect(grid.height, 13);

      // Row 0: q from 0 to 5
      expect(grid.getTileType(const GridCoordinate(0, 0)), TileType.empty);
      expect(grid.getTileType(const GridCoordinate(5, 0)), TileType.empty);

      // Row 1: q from 0 to 5 (offset calculation: q = c - floor(r/2) = c - 0 = c)
      // Actually q = c - floor(r/2).
      // r=0: q = c - 0 = c. c in [0,5] -> q in [0,5]
      // r=1: q = c - 0 = c. c in [0,5] -> q in [0,5]
      // r=2: q = c - 1. c in [0,5] -> q in [-1,4]
      // r=12: q = c - 6. c in [0,5] -> q in [-6,-1]
    });

    test('getTileType returns blocked for out-of-bounds', () {
      final grid = HexGrid.rectangle(6, 13);
      expect(grid.getTileType(const GridCoordinate(-10, 0)), TileType.blocked);
      expect(grid.getTileType(const GridCoordinate(10, 0)), TileType.blocked);
    });

    test('setTileType and getTileType persist data', () {
      final grid = HexGrid.rectangle(6, 13);
      const coord = GridCoordinate(0, 0);

      grid.setTileType(coord, TileType.blocked);
      expect(grid.getTileType(coord), TileType.blocked);

      grid.setTileType(coord, TileType.targetZone);
      expect(grid.getTileType(coord), TileType.targetZone);
    });
  });
}
