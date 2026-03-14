import 'package:between_the_lines/model/overworld/district_data.dart';
import 'package:between_the_lines/model/overworld/overworld_state.dart';
import 'package:between_the_lines/model/overworld/story_edge.dart';
import 'package:between_the_lines/view/overworld/overworld_painter.dart';
import 'package:flutter/material.dart';

/// Full-screen overworld displaying one district at a time.
///
/// Shows the district's nodes/edges, the district title bar,
/// a character portrait at the current node, and a bottom info panel.
class OverworldScreen extends StatefulWidget {
  const OverworldScreen({
    required this.state,
    required this.onEdgeSelected,
    this.onArrivalAnimationComplete,
    this.onTransitionOutBoundReached,
    super.key,
  });

  final OverworldState state;
  final void Function(StoryEdge edge) onEdgeSelected;
  final VoidCallback? onArrivalAnimationComplete;
  final void Function(Offset direction)? onTransitionOutBoundReached;

  @override
  State<OverworldScreen> createState() => _OverworldScreenState();
}

class _OverworldScreenState extends State<OverworldScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _moveController;
  Animation<Offset>? _moveAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.state.needsArrivalAnimation) {
      widget.state.needsArrivalAnimation = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runArrivalAnimation();
      });
    } else if (widget.state.isTransitioningIn) {
      widget.state.isTransitioningIn = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runTransitionInAnimation();
      });
    }
  }

  @override
  void didUpdateWidget(OverworldScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.needsArrivalAnimation) {
      widget.state.needsArrivalAnimation = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runArrivalAnimation();
      });
    } else if (widget.state.isTransitioningIn) {
      widget.state.isTransitioningIn = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runTransitionInAnimation();
      });
    }
  }

  void _runArrivalAnimation() {
    final edgeId = widget.state.lastCompletedEdgeId;
    if (edgeId == null) return;

    final edge = widget.state.chapter.getEdge(edgeId);
    if (edge == null) return;

    final fromNode = widget.state.chapter.getNode(edge.fromNodeId);
    final toNode = widget.state.chapter.getNode(edge.toNodeId);
    if (fromNode == null || toNode == null) return;

    final startOffset = Offset(
      (fromNode.x + toNode.x) / 2,
      (fromNode.y + toNode.y) / 2,
    );
    final endOffset = Offset(toNode.x, toNode.y);

    setState(() {
      _moveAnimation = Tween<Offset>(begin: startOffset, end: endOffset).animate(
        CurvedAnimation(
          parent: _moveController,
          curve: Curves.easeInOut,
        ),
      );
    });

    _moveController.forward(from: 0).then((_) {
      if (mounted) {
        widget.onArrivalAnimationComplete?.call();
        setState(() {
          _moveAnimation = null;
        });
      }
    });
  }

  void _runTransitionInAnimation() {
    final currentNode = widget.state.currentNode;
    final direction = widget.state.lastTransitionDirection;
    if (direction == null) return;

    final endOffset = Offset(currentNode.x, currentNode.y);

    const padding = 0.12;
    var tx = double.infinity;
    var ty = double.infinity;

    // We want to calculate the start point outside the screen.
    // If we left going RIGHT (direction.dx = 1), we want to enter from LEFT (start < 0).
    // So if direction.dx > 0, we are starting at a negative x.
    if (direction.dx > 0) {
      tx = (padding + endOffset.dx) / direction.dx;
    } else if (direction.dx < 0) {
      tx = (1.0 + padding - endOffset.dx) / -direction.dx;
    }

    if (direction.dy > 0) {
      ty = (padding + endOffset.dy) / direction.dy;
    } else if (direction.dy < 0) {
      ty = (1.0 + padding - endOffset.dy) / -direction.dy;
    }

    var t = (tx < ty ? tx : ty);
    if (t == double.infinity || t < 0) t = 0.3; // Fallback

    final startOffset = Offset(endOffset.dx - direction.dx * t, endOffset.dy - direction.dy * t);

    setState(() {
      _moveAnimation = Tween<Offset>(begin: startOffset, end: endOffset).animate(
        CurvedAnimation(
          parent: _moveController,
          curve: Curves.easeInOut,
        ),
      );
    });

    _moveController.duration = Duration(milliseconds: (t / 0.35 * 1500).round().clamp(100, 3000));
    _moveController.forward(from: 0).then((_) {
      if (mounted) {
        widget.onArrivalAnimationComplete?.call();
        setState(() {
          _moveAnimation = null;
        });
        _moveController.duration = const Duration(milliseconds: 1500);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _moveController.dispose();
    super.dispose();
  }

  // Per-district color themes.
  static const _tierColors = [
    Color(0xFF3A7CA5), // District 1: Prole blue
    Color(0xFFC97B2A), // District 2: Industrial amber
    Color(0xFF8B5CF6), // District 3: Inner Party purple
    Color(0xFFDC2626), // District 4: Big Brother red
  ];

  Color get _tierColor {
    final tier = widget.state.currentDistrict.tier;
    if (tier >= 1 && tier <= _tierColors.length) {
      return _tierColors[tier - 1];
    }
    return _tierColors[0];
  }

  @override
  Widget build(BuildContext context) {
    final district = widget.state.currentDistrict;
    final size = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Background gradient with tier-specific tint
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.3),
                radius: 1.3,
                colors: [
                  _tierColor.withValues(alpha: 0.15),
                  const Color(0xFF0D1117),
                ],
              ),
            ),
          ),

          // Graph canvas
          GestureDetector(
            onTapUp: _handleTap,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return CustomPaint(
                  painter: OverworldPainter(
                    state: widget.state,
                    district: district,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // Character portrait at current node
          AnimatedBuilder(
            animation: _moveController,
            builder: (context, child) {
              return _buildCharacterPortrait(size);
            },
          ),

          // District title bar (top right)
          Positioned(
            top: safePadding.top + 12,
            right: 20,
            child: _buildDistrictTitle(district),
          ),

          // District progress dots (top center)
          Positioned(
            top: safePadding.top + 16,
            left: 0,
            right: 0,
            child: _buildDistrictDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictTitle(DistrictData district) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _tierColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'District ${district.tier}: ${district.name}',
            style: TextStyle(
              color: _tierColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (district.subtitle.isNotEmpty)
            Text(
              district.subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDistrictDots() {
    final totalDistricts = widget.state.chapter.districts.length;
    final currentIdx = widget.state.currentDistrictIndex;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDistricts, (i) {
        final isActive = i == currentIdx;
        final isComplete = i < currentIdx;
        return Container(
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? _tierColor
                : isComplete
                    ? const Color(0xFF66BB6A)
                    : Colors.white.withValues(alpha: 0.2),
            border: isActive
                ? Border.all(
                    color: _tierColor.withValues(alpha: 0.6),
                    width: 2,
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildCharacterPortrait(Size screenSize) {
    double portraitX;
    double portraitY;

    if (_moveAnimation != null) {
      portraitX = _moveAnimation!.value.dx * screenSize.width;
      portraitY = _moveAnimation!.value.dy * screenSize.height;
    } else {
      final currentNode = widget.state.currentNode;
      portraitX = currentNode.x * screenSize.width;
      portraitY = currentNode.y * screenSize.height;
    }

    // Offset the portrait above the node
    const portraitSize = 56.0;

    return Positioned(
      left: portraitX - portraitSize / 2,
      top: portraitY - portraitSize - 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: portraitSize,
            height: portraitSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _tierColor,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _tierColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                padding: const EdgeInsets.all(2),
                child: Image.asset(
                  'assets/images/character_portrait/character1_portrait.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Small triangle pointing down to the node
          CustomPaint(
            size: const Size(12, 8),
            painter: _TrianglePainter(color: _tierColor),
          ),
        ],
      ),
    );
  }

  double _pointToLineDistance(Offset p, Offset start, Offset end) {
    final l2 = (start - end).distanceSquared;
    var t = 1.0;
    if (l2 > 0) {
      t = ((p.dx - start.dx) * (end.dx - start.dx) + (p.dy - start.dy) * (end.dy - start.dy)) / l2;
      t = t.clamp(0.0, 1.0);
    }
    final projection = Offset(
      start.dx + t * (end.dx - start.dx),
      start.dy + t * (end.dy - start.dy),
    );
    return (p - projection).distance;
  }

  void _handleTap(TapUpDetails details) {
    // Ignore taps while an animation is playing
    if (_moveController.isAnimating) return;

    final size = MediaQuery.of(context).size;
    final currentNode = widget.state.currentNode;
    final p = details.localPosition;

    if (widget.state.isTransitioningOut) {
      final district = widget.state.currentDistrict;
      final direction = district.transitionDirection;
      if (direction == null) return;

      final startPos = Offset(currentNode.x * size.width, currentNode.y * size.height);
      final destPos = Offset(
        (currentNode.x + direction.dx * 1.5) * size.width,
        (currentNode.y + direction.dy * 1.5) * size.height,
      );

      if (_pointToLineDistance(p, startPos, destPos) < 45) {
        final startOffset = Offset(currentNode.x, currentNode.y);
        final destOffset = Offset(currentNode.x + direction.dx * 1.5, currentNode.y + direction.dy * 1.5);

        setState(() {
          _moveAnimation = Tween<Offset>(begin: startOffset, end: destOffset).animate(
            CurvedAnimation(
              parent: _moveController,
              curve: Curves.easeInOut,
            ),
          );
        });

        var transitionTriggered = false;
        void boundListener() {
          if (transitionTriggered || _moveAnimation == null) return;
          final pos = _moveAnimation!.value;
          const padding = 0.12; // When node padding crosses the line
          if (pos.dx <= -padding || pos.dx >= 1.0 + padding || pos.dy <= -padding || pos.dy >= 1.0 + padding) {
            transitionTriggered = true;
            _moveAnimation?.removeListener(boundListener);
            _moveController.stop();
            if (mounted) {
              widget.onTransitionOutBoundReached?.call(direction);
              setState(() {
                _moveAnimation = null;
              });
            }
          }
        }

        _moveAnimation?.addListener(boundListener);

        _moveController.duration = const Duration(milliseconds: 2500);
        _moveController.forward(from: 0);
        return;
      }
    }

    final nextEdge = widget.state.nextEdge;
    if (nextEdge == null) return;

    final destNode = widget.state.chapter.getNode(nextEdge.toNodeId);
    if (destNode == null) return;

    final startPos = Offset(currentNode.x * size.width, currentNode.y * size.height);
    final destPos = Offset(destNode.x * size.width, destNode.y * size.height);

    final distanceToEdge = _pointToLineDistance(p, startPos, destPos);
    final distanceToNode = (p - destPos).distance;

    if (distanceToNode < 45 || distanceToEdge < 30) {
      final startOffset = Offset(currentNode.x, currentNode.y);
      final destOffset = Offset(
        (currentNode.x + destNode.x) / 2,
        (currentNode.y + destNode.y) / 2,
      );

      setState(() {
        _moveAnimation = Tween<Offset>(begin: startOffset, end: destOffset).animate(
          CurvedAnimation(
            parent: _moveController,
            curve: Curves.easeInOut,
          ),
        );
      });

      _moveController.duration = const Duration(milliseconds: 1500);
      _moveController.forward(from: 0).then((_) {
        if (mounted) {
          widget.onEdgeSelected(nextEdge);
        }
      });
    }
  }
}

/// Small downward-pointing triangle painted below the character portrait.
class _TrianglePainter extends CustomPainter {
  _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
