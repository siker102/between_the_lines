import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Animated "!" indicator shown on goal tiles during character drag.
class GoalIndicatorComponent extends PositionComponent {
  double _elapsed = 0;

  GoalIndicatorComponent({required Vector2 tileCenter})
      : super(
          position: tileCenter,
          size: Vector2(20, 20),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Pulsing scale effect
    final pulse = 1.0 + 0.2 * sin(_elapsed * 6);
    final cx = size.x / 2;
    final cy = size.y / 2;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(pulse);
    canvas.translate(-cx, -cy);

    // Draw "!" text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '!',
        style: TextStyle(
          color: Colors.yellow,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        cx - textPainter.width / 2,
        cy - textPainter.height / 2,
      ),
    );

    canvas.restore();
  }
}
