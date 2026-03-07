import 'dart:math';

import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/view/utils/hex_math.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Renders an enemy and supports smooth animated movement.
class EnemyComponent extends PositionComponent {
  final Enemy model;

  static const double baseRadius = 12.0;

  // Animation state
  Vector2? _animTarget;
  static const double _moveSpeed = 200; // pixels per second

  EnemyComponent({required this.model})
      : super(
          size: Vector2(baseRadius * 2, baseRadius * 2),
          anchor: Anchor.center,
        ) {
    syncWithModel();
  }

  /// Instantly snap to the model's position.
  void syncWithModel() {
    position = HexMath.gridToScreen(model.position);
  }

  /// Smoothly animate to the model's current position
  /// over time (handled in [update]).
  void animateToModel() {
    _animTarget = HexMath.gridToScreen(model.position);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_animTarget != null) {
      final diff = _animTarget! - position;
      final dist = diff.length;
      final step = _moveSpeed * dt;
      if (dist <= step) {
        position = _animTarget!;
        _animTarget = null;
      } else {
        position += diff.normalized() * step;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Body color depends on enemy type
    final bodyColor = _bodyColorForType(model.enemyType);
    final paint = Paint()..color = bodyColor;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      baseRadius,
      paint,
    );

    // Outline
    final outlinePaint = Paint()
      ..color = bodyColor.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      baseRadius,
      outlinePaint,
    );

    // Draw facing indicator (not for radial)
    if (model.enemyType != EnemyType.radial) {
      _drawFacingIndicator(canvas);
    }
  }

  void _drawFacingIndicator(Canvas canvas) {
    final facingPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;

    final center = Offset(size.x / 2, size.y / 2);
    const double len = 10;

    double angle = 0;
    switch (model.facing) {
      case Direction.right:
        angle = 0;
      case Direction.bottomRight:
        angle = pi / 3;
      case Direction.bottomLeft:
        angle = 2 * pi / 3;
      case Direction.left:
        angle = pi;
      case Direction.topLeft:
        angle = 4 * pi / 3;
      case Direction.topRight:
        angle = 5 * pi / 3;
    }

    final end = Offset(
      center.dx + len * cos(angle),
      center.dy + len * sin(angle),
    );
    canvas.drawLine(center, end, facingPaint);
  }

  Color _bodyColorForType(EnemyType type) {
    switch (type) {
      case EnemyType.directional:
        return Colors.red;
      case EnemyType.linear:
        return Colors.orange;
      case EnemyType.radial:
        return Colors.deepPurple;
    }
  }
}
