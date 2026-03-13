import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:between_the_lines/view/utils/hex_math.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A single hex cell on the board.
///
/// Supports multiple simultaneous highlight layers so that
/// overlapping ranges (e.g. blue move + red vision) blend
/// into a combined color (purple).
class HexTile extends PositionComponent with HasGameReference {
  final GridCoordinate coordinate;
  TileType type;
  bool isOpen = false;
  bool isOccupied = false; // used by hiding tiles: true when a character stands here
  bool isActive = false; // used by pressurePlate tiles: true when pressed

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
    ..color = const Color.fromRGBO(0, 167, 167, 1.0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  // Sprites
  Sprite? _teleportSprite;
  Sprite? _hidingIdleSprite;
  Sprite? _hidingActiveSprite;
  Sprite? _bluePlateIdleSprite;
  Sprite? _bluePlateActiveSprite;
  Sprite? _brownIdleSprite;

  HexTile({
    required this.coordinate,
    required this.type,
  }) : super() {
    position = HexMath.gridToScreen(coordinate);
    anchor = Anchor.center;
    size = Vector2(HexMath.width, HexMath.height);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      // Load only the sprites relevant to this tile's type to avoid wasting memory,
      // though Flame's image cache deduplicates. For simplicity, we can load what we need.
      _teleportSprite = await game.loadSprite('tiles/teleport_active.png');
      _hidingIdleSprite = await game.loadSprite('tiles/green_idle.png');
      _hidingActiveSprite = await game.loadSprite('tiles/green_active.png');
      _bluePlateIdleSprite = await game.loadSprite('tiles/blue_idle.png');
      _bluePlateActiveSprite = await game.loadSprite('tiles/blue_active.png');
      _brownIdleSprite = await game.loadSprite('tiles/brown_idle.png');
    } catch (_) {
      // Image loading not available in test environments — skip sprite setup.
    }
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

    Paint? fill;
    switch (type) {
      case TileType.blocked:
      case TileType.crumbled:
        fill = _blockedPaint;
      case TileType.pressureObstacle:
        fill = isOpen ? _fillPaint : _blockedPaint;
      case TileType.targetZone:
        fill = _targetPaint;
      case TileType.empty:
      case TileType.pressurePlate:
        fill = _fillPaint;
      case TileType.unstable:
        if (_brownIdleSprite != null) {
          _renderRotatedSprite(canvas, _brownIdleSprite!);
        } else {
          fill = _fillPaint;
        }
      case TileType.hiding:
        final sprite = isOccupied ? _hidingActiveSprite : _hidingIdleSprite;
        if (sprite != null) {
          _renderRotatedSprite(canvas, sprite);
        } else {
          fill = _fillPaint;
        }
      case TileType.teleport:
        if (_teleportSprite != null) {
          _renderRotatedSprite(canvas, _teleportSprite!);
        } else {
          fill = _fillPaint;
        }
    }
    if (fill != null) {
      canvas.drawPath(path, fill);
    }

    // Highlight overlays
    if (isHighlighted) {
      final blended = _blendHighlights();
      final paint = Paint()
        ..color = blended.withAlpha(128)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, paint);
    }

    // Draw inner shapes for teleport/plate
    if (type == TileType.pressurePlate) {
      final sprite = isActive ? _bluePlateActiveSprite : _bluePlateIdleSprite;
      if (sprite != null) {
        _renderRotatedSprite(canvas, sprite);
      } else {
        canvas.drawCircle(Offset(cx, cy), s / 4, _pressureBorderPaint);
      }
    }

    // Border
    if (type == TileType.pressurePlate || type == TileType.pressureObstacle) {
      canvas.drawPath(path, _pressureBorderPaint);
    } else if (type == TileType.crumbled) {
      final crumbledBorderPaint = Paint()
        ..color = const Color.fromRGBO(82, 37, 24, 1.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(path, crumbledBorderPaint);
    } else {
      canvas.drawPath(path, _defaultPaint);
    }
  }

  void _renderRotatedSprite(Canvas canvas, Sprite sprite) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(math.pi / 2);
    // When rotated 90 deg, the widths and heights swap
    sprite.render(
      canvas,
      position: Vector2(-size.y / 2, -size.x / 2),
      size: Vector2(size.y, size.x),
    );
    canvas.restore();
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
