import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/view/utils/hex_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HexMath', () {
    test('gridToScreen and screenToGrid are consistent', () {
      final coords = [
        const GridCoordinate(0, 0),
        const GridCoordinate(5, 0),
        const GridCoordinate(-6, 12),
        const GridCoordinate(3, 7),
      ];

      for (final coord in coords) {
        final screenPos = HexMath.gridToScreen(coord);
        final backToGrid = HexMath.screenToGrid(screenPos);
        expect(backToGrid, coord, reason: 'Failed for $coord');
      }
    });

    test('gridToScreen returns expected vertical alignment for row 0 and row 12', () {
      // col 0 at row 0 is (0, 0)
      // col 0 at row 12 is (-6, 12)  (q = col - floor(r/2) = 0 - 6 = -6)
      final pos0 = HexMath.gridToScreen(const GridCoordinate(0, 0));
      final pos12 = HexMath.gridToScreen(const GridCoordinate(-6, 12));

      expect(pos0.x, pos12.x, reason: 'Horizontal alignment between row 0 and 12 failed');
    });
  });
}
