import 'package:between_the_lines/model/entities/character.dart';
import 'package:between_the_lines/view/utils/hex_math.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class CharacterComponent extends PositionComponent with DragCallbacks, DoubleTapCallbacks {
  final Character model;
  final Function(CharacterComponent) onDragStartCallback;
  final Function(CharacterComponent) onDragUpdateCallback;
  final Function(CharacterComponent) onDragEndCallback;
  final Function(CharacterComponent) onDoubleTapCallback;

  // Visual representation
  static const double baseRadius = 12.0;

  CharacterComponent({
    required this.model,
    required this.onDragStartCallback,
    required this.onDragUpdateCallback,
    required this.onDragEndCallback,
    required this.onDoubleTapCallback,
  }) : super(
          size: Vector2(baseRadius * 2, baseRadius * 2),
          anchor: Anchor.center,
        ) {
    _updatePositionFromModel();
  }

  void _updatePositionFromModel() {
    position = HexMath.gridToScreen(model.position);
    // Center on hex tile. Hex cells are centered locally so no offset needed.
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (model.hasMoved) {
      return;
    }
    super.onDragStart(event);
    onDragStartCallback(this);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // The visual position drags along with the pointer
    position += event.localDelta;
    onDragUpdateCallback(this);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    onDragEndCallback(this);
    // Position might be snapped by the game logic, but if not we snap it back
    // to model.
    _updatePositionFromModel();
  }

  @override
  void onDoubleTapDown(DoubleTapDownEvent event) {
    if (model.hasMoved) {
      return;
    }
    onDoubleTapCallback(this);
  }

  // Sync if model position changes outside of drag (e.g., reset)
  void syncWithModel() {
    _updatePositionFromModel();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final color = model.hasMoved ? Colors.grey : Colors.blue;
    final paint = Paint()..color = color;
    // Draw simple circle for character
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), baseRadius, paint);

    // Draw a dark outline for depth
    final outlinePaint = Paint()
      ..color = model.hasMoved ? Colors.grey[800]! : Colors.blue[900]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), baseRadius, outlinePaint);
  }
}
