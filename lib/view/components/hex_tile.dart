import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:between_the_lines/view/utils/hex_math.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A single hex cell on the board.
///
/// Supports multiple simultaneous highlight layers so that
/// overlapping ranges (e.g. blue move + red vision) blend
/// into a combined color (purple).
class HexTile extends PositionComponent {
  final GridCoordinate coordinate;
  TileType type;
  bool isOpen = false;

  /// Active highlight colors. When both blue and red are
  /// present, the tile renders as purple.
  final Set<Color> highlightColors = {};

  static final Paint _defaultPaint = Paint()
    ..color = Colors.grey[800]!
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint _fillPaint = Paint()
    ..color = Colors.grey[300]!
    ..style = PaintingStyle.fill;

  static final Paint _blockedPaint = Paint()
    ..color = Colors.grey[900]!
    ..style = PaintingStyle.fill;

  static final Paint _targetPaint = Paint()
    ..color = Colors.green[200]!
    ..style = PaintingStyle.fill;

  static final Paint _pressureBorderPaint = Paint()
    ..color = Colors.pinkAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final Paint _hidingPaint = Paint()
    ..color = Colors.lightGreen[800]!
    ..style = PaintingStyle.fill;

  static final Paint _teleportPaint = Paint()
    ..color = Colors.cyanAccent
    ..style = PaintingStyle.fill;

  static final Paint _unstablePaint = Paint()
    ..color = Colors.brown[400]!
    ..style = PaintingStyle.fill;

  HexTile({
    required this.coordinate,
    required this.type,
  }) : super() {
    position = HexMath.gridToScreen(coordinate);
    anchor = Anchor.center;
    size = Vector2(HexMath.width, HexMath.height);
  }

  bool get isHighlighted => highlightColors.isNotEmpty;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;
    const s = HexMath.size;
    final cx = w / 2;
    final cy = h / 2;

    final path = Path()
      ..moveTo(cx, cy - h / 2)
      ..lineTo(cx + w / 2, cy - s / 2)
      ..lineTo(cx + w / 2, cy + s / 2)
      ..lineTo(cx, cy + h / 2)
      ..lineTo(cx - w / 2, cy + s / 2)
      ..lineTo(cx - w / 2, cy - s / 2)
      ..close();

    Paint fill;
    switch (type) {
      case TileType.blocked:
      case TileType.crumbled:
      case TileType.pressureObstacle:
        fill = isOpen ? _fillPaint : _blockedPaint;
      case TileType.targetZone:
        fill = _targetPaint;
      case TileType.hiding:
        fill = _hidingPaint;
      case TileType.unstable:
        fill = _unstablePaint;
      case TileType.empty:
      case TileType.pressurePlate:
      case TileType.teleport:
        fill = _fillPaint;
    }
    canvas.drawPath(path, fill);

    // Highlight overlays
    if (isHighlighted) {
      final blended = _blendHighlights();
      final paint = Paint()
        ..color = blended.withAlpha(128)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }

    // Draw inner shapes for teleport/plate
    if (type == TileType.teleport) {
      canvas.drawCircle(Offset(cx, cy), s / 3, _teleportPaint);
    } else if (type == TileType.pressurePlate) {
      canvas.drawCircle(Offset(cx, cy), s / 4, _pressureBorderPaint);
    }

    // Border
    if (type == TileType.pressurePlate || type == TileType.pressureObstacle) {
      canvas.drawPath(path, _pressureBorderPaint);
    } else {
      canvas.drawPath(path, _defaultPaint);
    }
  }

  /// Blends all active highlight colors.
  /// Special cases:
  /// - blue + red = purple (move range + enemy vision)
  /// - dark blue + red = dark purple (blocked by ally + enemy vision)
  /// - dark red (blocked by enemy)
  Color _blendHighlights() {
    final hasBlue = highlightColors.contains(Colors.blue);
    final hasRed = highlightColors.contains(Colors.red);
    final hasDarkBlue = highlightColors.contains(Colors.blue.shade800);
    final hasDarkRed = highlightColors.contains(Colors.red.shade800);

    if (hasDarkRed) {
      return Colors.red.shade900;
    }

    if (hasDarkBlue && hasRed) {
      return Colors.purple.shade900;
    }

    if (hasDarkBlue) {
      return Colors.blue.shade800;
    }

    if (hasBlue && hasRed) {
      return Colors.purple;
    }

    // Average all colors if there are multiple non-standard ones
    if (highlightColors.length == 1) {
      return highlightColors.first;
    }
    // Fallback: blend via averaging
    var rSum = 0;
    var gSum = 0;
    var bSum = 0;
    for (final c in highlightColors) {
      rSum += (c.r * 255).round();
      gSum += (c.g * 255).round();
      bSum += (c.b * 255).round();
    }
    final n = highlightColors.length;
    return Color.fromARGB(
      255,
      rSum ~/ n,
      gSum ~/ n,
      bSum ~/ n,
    );
  }
}
