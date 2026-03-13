import 'package:between_the_lines/model/entities/character.dart';
import 'package:between_the_lines/view/utils/hex_math.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class CharacterComponent extends PositionComponent with DragCallbacks, DoubleTapCallbacks, HasGameReference {
  final Character model;
  final Function(CharacterComponent) onDragStartCallback;
  final Function(CharacterComponent) onDragUpdateCallback;
  final Function(CharacterComponent) onDragEndCallback;
  final Function(CharacterComponent) onDoubleTapCallback;

  // Visual representation
  SpriteAnimationComponent? _animComponent;
  SpriteAnimation? _idleAnim;
  SpriteAnimation? _walkAnim;
  double _idleWidth = 0;
  double _walkWidth = 0;
  Vector2? _dragStartPosition;

  static const double baseRadius = 24.0;

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

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      final path = model.id == 'c1' ? 'spritesheets/man' : 'spritesheets/woman';

      final idleImage = await game.images.load('$path/idle_anim.png');
      _idleAnim = SpriteAnimation.fromFrameData(
        idleImage,
        SpriteAnimationData.sequenced(
          amount: 25,
          amountPerRow: 25,
          stepTime: 0.03,
          textureSize: Vector2(144, 216),
        ),
      );

      final walkImage = await game.images.load('$path/walk_anim.png');
      _walkAnim = SpriteAnimation.fromFrameData(
        walkImage,
        SpriteAnimationData.sequenced(
          amount: 37,
          amountPerRow: 37,
          stepTime: 0.03,
          textureSize: Vector2(144, 216),
        ),
      );

      const targetHeight = 52.0;
      _idleWidth = 144.0 * (targetHeight / 216.0);
      _walkWidth = 144.0 * (targetHeight / 216.0);

      _animComponent = SpriteAnimationComponent(
        animation: _idleAnim,
        size: Vector2(_idleWidth, targetHeight),
        anchor: Anchor.center,
      );
      _animComponent!.position = size / 2;
      add(_animComponent!);
    } catch (_) {
      // Image loading not available in test environments — skip animation setup.
    }
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
    _dragStartPosition = position.clone();
    if (_animComponent != null) {
      _animComponent!.animation = _walkAnim;
      _animComponent!.size.x = _walkWidth;
      _animComponent!.animationTicker?.reset();
      _animComponent!.playing = true;
    }
    onDragStartCallback(this);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // The visual position drags along with the pointer
    position += event.localDelta;

    // Flip sprite based on accumulated horizontal displacement from drag start
    if (_dragStartPosition != null) {
      final horizontalDisplacement = position.x - _dragStartPosition!.x;
      if (horizontalDisplacement.abs() > 8.0) {
        _animComponent?.scale.x = horizontalDisplacement < 0 ? -1 : 1;
      }
    }

    onDragUpdateCallback(this);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragStartPosition = null;
    if (_animComponent != null) {
      _animComponent!.animation = _idleAnim;
      _animComponent!.size.x = _idleWidth;
      _animComponent!.animationTicker?.reset();
      _animComponent!.playing = true;
    }
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
    if (_animComponent != null) {
      if (model.hasMoved) {
        _animComponent!.paint = Paint()
          ..colorFilter = ColorFilter.mode(
            Colors.white.withAlpha(128),
            BlendMode.modulate,
          );
      } else {
        _animComponent!.paint = Paint();
      }
    }
  }

  // Remove render override as children handle drawing
}
