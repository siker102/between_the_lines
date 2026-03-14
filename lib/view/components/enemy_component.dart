
import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/view/utils/hex_math.dart';
import 'package:flame/components.dart';

/// Renders an enemy and supports smooth animated movement.
class EnemyComponent extends PositionComponent with HasGameReference {
  final Enemy model;

  static const double baseRadius = 24.0;
  static const double _stepTime = 0.05;

  // Animation state
  SpriteAnimationComponent? _animComponent;
  SpriteAnimation? _idleAnim;
  SpriteAnimation? _walkAnim;
  double _idleWidth = 0;
  double _walkWidth = 0;

  Vector2? _animTarget;
  static const double _moveSpeed = 200; // pixels per second

  EnemyComponent({required this.model})
      : super(
          size: Vector2(baseRadius * 2, baseRadius * 2),
          anchor: Anchor.center,
        ) {
    syncWithModel();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      const path = 'spritesheets/soldier';

      final idleImage = await game.images.load('$path/idle_anim.png');
      _idleAnim = SpriteAnimation.fromFrameData(
        idleImage,
        SpriteAnimationData.range(
          amount: 25,
          amountPerRow: 25,
          stepTimes: List.filled(14, _stepTime),
          textureSize: Vector2(144, 216), start: 0, end: 13,
        ),
      );

      final walkImage = await game.images.load('$path/walk_anim.png');
      _walkAnim = SpriteAnimation.fromFrameData(
        walkImage,
        SpriteAnimationData.range(
          amount: 37,
          amountPerRow: 37,
          stepTimes: List.filled(20, _stepTime),
          textureSize: Vector2(144, 216), start: 0, end: 19,
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

      // Apply initial facing orientation now that _animComponent exists.
      _updateFlip();
    } catch (_) {
      // Image loading not available in test environments — skip animation setup.
    }
  }

  /// Instantly snap to the model's position.
  void syncWithModel() {
    position = HexMath.gridToScreen(model.position);
    _updateFlip();
  }

  void _updateFlip() {
    if (_animComponent == null) return;
    // Soldier sprite faces left by default.
    // Flip horizontally when facing rightward directions.
    if (model.facing == Direction.right ||
        model.facing == Direction.topRight ||
        model.facing == Direction.bottomRight) {
      _animComponent!.scale.x = -1;
    } else {
      _animComponent!.scale.x = 1;
    }
  }

  /// Smoothly animate to the model's current position
  /// over time (handled in [update]).
  void animateToModel() {
    if (_animComponent != null) {
      _animComponent!.animation = _walkAnim;
      _animComponent!.size.x = _walkWidth;
      _animComponent!.animationTicker?.reset();
      _animComponent!.playing = true;
    }
    _animTarget = HexMath.gridToScreen(model.position);
    _updateFlip();
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
        if (_animComponent != null) {
          _animComponent!.animation = _idleAnim;
          _animComponent!.size.x = _idleWidth;
          _animComponent!.animationTicker?.reset();
          _animComponent!.playing = true;
        }
        _updateFlip();
      } else {
        position += diff.normalized() * step;
      }
    }
  }

  // Remove render override as children handle drawing
}
