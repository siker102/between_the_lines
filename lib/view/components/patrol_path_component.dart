import 'dart:math';

import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/view/components/enemy_component.dart';
import 'package:between_the_lines/view/utils/hex_math.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Shows the enemy's NEXT move only: a dashed line from
/// current position to next position, plus a chevron
/// showing which way the enemy will look.
class PatrolPathComponent extends PositionComponent {
  final Enemy enemy;
  EnemyComponent? enemyComponent;

  PatrolPathComponent({required this.enemy, this.enemyComponent}) : super(priority: 1); // On top of tiles

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Camera: stationary — show only a chevron indicating next facing direction
    if (enemy.enemyType == EnemyType.camera) {
      Vector2 pos;
      if (enemyComponent != null) {
        pos = enemyComponent!.position;
      } else {
        pos = HexMath.gridToScreen(enemy.position);
      }

      final facingAngle = _dirAngle(enemy.nextFacing);
      const chevronLen = 14.0;
      const chevronSpread = 0.5;

      final chevronLeft = Offset(
        pos.x - cos(facingAngle - chevronSpread) * chevronLen,
        pos.y - sin(facingAngle - chevronSpread) * chevronLen,
      );
      final chevronRight = Offset(
        pos.x - cos(facingAngle + chevronSpread) * chevronLen,
        pos.y - sin(facingAngle + chevronSpread) * chevronLen,
      );

      final chevronPaint = Paint()
        ..color = const Color(0xCC333333)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final chevronPath = Path()
        ..moveTo(chevronLeft.dx, chevronLeft.dy)
        ..lineTo(pos.x, pos.y)
        ..lineTo(chevronRight.dx, chevronRight.dy);

      canvas.drawPath(chevronPath, chevronPaint);
      return;
    }

    if (enemy.position == enemy.nextPosition) return;

    // Use the visual position of the enemy sprite (animated), not the model position
    final modelFrom = HexMath.gridToScreen(enemy.position);
    final modelTo = HexMath.gridToScreen(enemy.nextPosition);
    final delta = modelTo - modelFrom;

    Vector2 from;
    if (enemyComponent != null) {
      from = enemyComponent!.position;
    } else {
      from = modelFrom;
    }
    final to = from + delta;

    // ── Dashed path line ──
    final pathDir = to - from;
    final dist = pathDir.length;
    final norm = pathDir.normalized();
    const dashLen = 6.0;
    const gapLen = 4.0;
    final dashPaint = Paint()
      ..color = const Color(0xBB333333)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    var d = 0.0;
    while (d < dist) {
      final start = from + norm * d;
      final end = from + norm * min(d + dashLen, dist);
      canvas.drawLine(Offset(start.x, start.y), Offset(end.x, end.y), dashPaint);
      d += dashLen + gapLen;
    }

    // ── Small chevron at destination showing next facing ──
    final facingAngle = _dirAngle(enemy.nextFacing);
    const chevronLen = 10.0;
    const chevronSpread = 0.5;

    final chevronLeft = Offset(
      to.x - cos(facingAngle - chevronSpread) * chevronLen,
      to.y - sin(facingAngle - chevronSpread) * chevronLen,
    );
    final chevronRight = Offset(
      to.x - cos(facingAngle + chevronSpread) * chevronLen,
      to.y - sin(facingAngle + chevronSpread) * chevronLen,
    );

    final chevronPaint = Paint()
      ..color = const Color(0xCC333333)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final chevronPath = Path()
      ..moveTo(chevronLeft.dx, chevronLeft.dy)
      ..lineTo(to.x, to.y)
      ..lineTo(chevronRight.dx, chevronRight.dy);

    canvas.drawPath(chevronPath, chevronPaint);
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
