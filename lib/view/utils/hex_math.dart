import 'dart:math';

import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:flame/extensions.dart';

class HexMath {
  // Using Pointy-topped hexes (commonly used for maps with horizontal layouts)
  // Let's stick with pointy for now:
  // Width = sqrt(3) * size
  // Height = 2 * size
  // Horizontal distance = width
  // Vertical distance = 3/4 * height
  static const double size = 32.0;

  static final double width = sqrt(3.0) * size;
  static const double height = 2.0 * size;

  static Vector2 gridToScreen(GridCoordinate coord) {
    // Pointy-top calculations for Axial coords
    final x = size * sqrt(3.0) * (coord.q + coord.r / 2.0);
    final y = size * 3.0 / 2.0 * coord.r;

    return Vector2(x, y);
  }

  static GridCoordinate screenToGrid(Vector2 screenPos) {
    // Pointy-top calculations
    final qStr =
        (sqrt(3.0) / 3.0 * screenPos.x - 1.0 / 3.0 * screenPos.y) / size;
    final rStr = (2.0 / 3.0 * screenPos.y) / size;

    return _axialRound(qStr, rStr);
  }

  static GridCoordinate _axialRound(double fq, double fr) {
    final fs = -fq - fr;

    var q = fq.round();
    var r = fr.round();
    var s = fs.round();

    final qDiff = (q - fq).abs();
    final rDiff = (r - fr).abs();
    final sDiff = (s - fs).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      q = -r - s;
    } else if (rDiff > sDiff) {
      r = -q - s;
    } else {
      s = -q - r;
    }

    return GridCoordinate(q, r);
  }
}
