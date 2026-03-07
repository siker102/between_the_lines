import 'dart:math';

import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/view/utils/hex_math.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Shows the enemy's NEXT move only: a bold arrow from
/// current position to next position, plus a facing
/// indicator showing which way the enemy will look.
class PatrolPathComponent extends PositionComponent {
  final Enemy enemy;

  PatrolPathComponent({required this.enemy}) : super(priority: 1); // On top of tiles

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final from = HexMath.gridToScreen(enemy.position);
    final to = HexMath.gridToScreen(enemy.nextPosition);

    // Skip if not moving
    if (enemy.position == enemy.nextPosition) {
      return;
    }

    // ── Movement arrow (current → next) ──
    final linePaint = Paint()
      ..color = Colors.red.withAlpha(200)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(from.x, from.y),
      Offset(to.x, to.y),
      linePaint,
    );

    // Arrowhead at the destination
    _drawArrowhead(canvas, from, to);

    // ── Facing indicator at destination ──
    // Shows which direction the enemy will look
    _drawFacingPreview(canvas, to, enemy.nextFacing);
  }

  void _drawArrowhead(Canvas canvas, Vector2 from, Vector2 to) {
    final dir = (to - from).normalized();
    final angle = atan2(dir.y, dir.x);

    const s = 8.0;
    final tip = Offset(to.x, to.y);
    final left = Offset(
      to.x + cos(angle + 2.6) * s,
      to.y + sin(angle + 2.6) * s,
    );
    final right = Offset(
      to.x + cos(angle - 2.6) * s,
      to.y + sin(angle - 2.6) * s,
    );

    final paint = Paint()
      ..color = Colors.red.withAlpha(220)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawFacingPreview(
    Canvas canvas,
    Vector2 pos,
    Direction dir,
  ) {
    final angle = _dirAngle(dir);
    const len = 14.0;

    final end = Offset(
      pos.x + cos(angle) * len,
      pos.y + sin(angle) * len,
    );

    // Vision cone outline (wider wedge)
    const spread = 0.4; // radians
    final coneLeft = Offset(
      pos.x + cos(angle - spread) * len,
      pos.y + sin(angle - spread) * len,
    );
    final coneRight = Offset(
      pos.x + cos(angle + spread) * len,
      pos.y + sin(angle + spread) * len,
    );

    final conePaint = Paint()
      ..color = Colors.orange.withAlpha(120)
      ..style = PaintingStyle.fill;

    final conePath = Path()
      ..moveTo(pos.x, pos.y)
      ..lineTo(coneLeft.dx, coneLeft.dy)
      ..lineTo(end.dx, end.dy)
      ..lineTo(coneRight.dx, coneRight.dy)
      ..close();

    canvas.drawPath(conePath, conePaint);

    // Center line
    final linePaint = Paint()
      ..color = Colors.orange.withAlpha(220)
      ..strokeWidth = 2;

    canvas.drawLine(Offset(pos.x, pos.y), end, linePaint);
  }

  double _dirAngle(Direction dir) {
    switch (dir) {
      case Direction.right:
        return 0;
      case Direction.bottomRight:
        return pi / 3;
      case Direction.bottomLeft:
        return 2 * pi / 3;
      case Direction.left:
        return pi;
      case Direction.topLeft:
        return 4 * pi / 3;
      case Direction.topRight:
        return 5 * pi / 3;
    }
  }
}
