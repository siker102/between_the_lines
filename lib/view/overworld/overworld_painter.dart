import 'package:between_the_lines/model/overworld/district_data.dart';
import 'package:between_the_lines/model/overworld/overworld_state.dart';
import 'package:between_the_lines/view/utils/utility.dart';
import 'package:flutter/material.dart';

/// CustomPainter that renders a single district's nodes and edges
/// in a vertical layout from bottom to top.
class OverworldPainter extends CustomPainter {
  OverworldPainter({
    required this.state,
    required this.district,
  });

  final OverworldState state;
  final DistrictData district;

  @override
  void paint(Canvas canvas, Size size) {
    final nodePositions = _computeNodePositions(size);
    _drawEdges(canvas, size, nodePositions);
    _drawNodes(canvas, size, nodePositions);
  }

  /// Compute screen positions for each node in the district.
  Map<String, Offset> _computeNodePositions(Size size) {
    final positions = <String, Offset>{};
    final nodeIds = district.nodeIds;

    for (var i = 0; i < nodeIds.length; i++) {
      final node = state.chapter.getNode(nodeIds[i]);
      if (node == null) {
        continue;
      }
      // Use the node's x/y coords (normalized 0..1)
      positions[node.id] = Offset(
        node.x * size.width,
        node.y * size.height,
      );
    }
    return positions;
  }

  void _drawEdges(
    Canvas canvas,
    Size size,
    Map<String, Offset> positions,
  ) {
    for (final edgeId in district.edgeIds) {
      final edge = state.chapter.getEdge(edgeId);
      if (edge == null) {
        continue;
      }

      final from = positions[edge.fromNodeId];
      final to = positions[edge.toNodeId];
      if (from == null || to == null) continue;

      final isCompleted = state.completedEdgeIds.contains(edge.id);
      final isNext = state.nextEdge?.id == edge.id;

      // Glow for the next available edge
      if (isNext) {
        final glowPaint = Paint()
          ..color = const Color(0xFF42A5F5).withValues(alpha: 0.35)
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        _drawPath(canvas, from, to, glowPaint);
      }

      final linePaint = Paint()
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isCompleted) {
        linePaint.color = const Color(0xFF81C784);
      } else if (isNext) {
        linePaint.color = const Color(0xFF64B5F6);
      } else {
        linePaint.color = Colors.white.withValues(alpha: 0.12);
      }

      _drawPath(canvas, from, to, linePaint);

      // Draw dots along the next edge
      if (isNext && !isCompleted) {
        _drawDots(canvas, from, to);
      }

      // Path name label at the midpoint
      if (edge.name.isNotEmpty && (isCompleted || isNext)) {
        _drawEdgeLabel(canvas, from, to, edge.name, isNext);
      }
    }

    // Draw incoming edge from previous district if applicable
    if (state.currentDistrictIndex > 0) {
      final prevDistrict = state.chapter.districts[state.currentDistrictIndex - 1];
      final direction = prevDistrict.transitionDirection;
      if (direction != null && district.nodeIds.isNotEmpty) {
        final firstNodeId = district.nodeIds.first;
        final firstNode = state.chapter.getNode(firstNodeId);
        if (firstNode != null) {
          final to = positions[firstNodeId];
          if (to != null) {
            // Compute offset to extend path to the screen edge.
            var t = 0.3;
            if (direction.dx != 0) {
              final tx = direction.dx > 0 ? firstNode.x / direction.dx : (firstNode.x - 1.0) / direction.dx;
              t = tx.abs() + 0.05;
            }
            if (direction.dy != 0) {
              final ty = direction.dy > 0 ? firstNode.y / direction.dy : (firstNode.y - 1.0) / direction.dy;
              final tCandidate = ty.abs() + 0.05;
              if (direction.dx != 0) {
                t = t < tCandidate ? t : tCandidate;
              } else {
                t = tCandidate;
              }
            }
            final from = Offset(
              (firstNode.x - direction.dx * t) * size.width,
              (firstNode.y - direction.dy * t) * size.height,
            );

            final linePaint = Paint()
              ..color = const Color(0xFF81C784)
              ..strokeWidth = 3.0
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round;

            _drawPath(canvas, from, to, linePaint);
          }
        }
      }
    }

    if (state.isTransitioningOut) {
      final direction = district.transitionDirection;
      if (direction != null) {
        final currentNode = state.chapter.getNode(state.currentNodeId);
        if (currentNode != null) {
          final from = positions[currentNode.id];
          if (from != null) {
            final to = Offset(
              (currentNode.x + direction.dx * 1.5) * size.width,
              (currentNode.y + direction.dy * 1.5) * size.height,
            );

            final glowPaint = Paint()
              ..color = const Color(0xFF42A5F5).withValues(alpha: 0.35)
              ..strokeWidth = 6.0
              ..style = PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
            _drawPath(canvas, from, to, glowPaint);

            final linePaint = Paint()
              ..color = const Color(0xFF64B5F6)
              ..strokeWidth = 3.0
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round;
            _drawPath(canvas, from, to, linePaint);

            _drawDots(canvas, from, to);
          }
        }
      }
    }
  }

  void _drawPath(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
  }

  void _drawDots(Canvas canvas, Offset from, Offset to) {
    final dotPaint = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    const dotCount = 5;
    for (var i = 1; i <= dotCount; i++) {
      final t = i / (dotCount + 1);
      final pos = Offset.lerp(from, to, t)!;
      canvas.drawCircle(pos, 2.5, dotPaint);
    }
  }

  void _drawEdgeLabel(
    Canvas canvas,
    Offset from,
    Offset to,
    String name,
    bool isActive,
  ) {
    final mid = Offset.lerp(from, to, 0.5)!;
    final painter = TextPainter(
      text: TextSpan(
        text: name,
        style: TextStyle(
          color: isActive ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.5),
          fontSize: 11,
          fontStyle: FontStyle.italic,
          fontFamily: appFontFamily,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    // Background pill
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: mid + const Offset(20, 0),
        width: painter.width + 16,
        height: painter.height + 8,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    painter.paint(
      canvas,
      mid + Offset(20 - painter.width / 2, -painter.height / 2),
    );
  }

  void _drawNodes(
    Canvas canvas,
    Size size,
    Map<String, Offset> positions,
  ) {
    for (final nodeId in district.nodeIds) {
      final node = state.chapter.getNode(nodeId);
      if (node == null) {
        continue;
      }

      final center = positions[nodeId]!;
      final isCurrent = nodeId == state.currentNodeId;
      final isCompleted = state.completedNodeIds.contains(nodeId);

      // Outer glow for current node
      if (isCurrent) {
        final glowPaint = Paint()
          ..color = const Color(0xFF64B5F6).withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
        canvas.drawCircle(center, 26, glowPaint);
      }

      // Node circle
      final fillPaint = Paint()..style = PaintingStyle.fill;
      if (isCurrent) {
        fillPaint.color = const Color(0xFF1E88E5);
      } else if (isCompleted) {
        fillPaint.color = const Color(0xFF66BB6A);
      } else {
        fillPaint.color = const Color(0xFF2A2A2A);
      }
      canvas.drawCircle(center, 18, fillPaint);

      // Border ring
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = isCurrent
            ? const Color(0xFF90CAF9)
            : isCompleted
                ? const Color(0xFFA5D6A7)
                : Colors.white.withValues(alpha: 0.2);
      canvas.drawCircle(center, 18, borderPaint);

      // Checkmark for completed nodes
      if (isCompleted && !isCurrent) {
        final checkPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          center + const Offset(-5, 0),
          center + const Offset(-1, 4),
          checkPaint,
        );
        canvas.drawLine(
          center + const Offset(-1, 4),
          center + const Offset(6, -4),
          checkPaint,
        );
      }

      // Node label below
      final labelPainter = TextPainter(
        text: TextSpan(
          text: node.label,
          style: TextStyle(
            color: isCurrent || isCompleted ? Colors.white : Colors.white.withValues(alpha: 0.35),
            fontSize: 13,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontFamily: appFontFamily,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 160);

      labelPainter.paint(
        canvas,
        center + Offset(-labelPainter.width / 2, 26),
      );

      // Description below label
      if (node.description.isNotEmpty && (isCurrent || isCompleted)) {
        final descPainter = TextPainter(
          text: TextSpan(
            text: node.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontFamily: appFontFamily,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 160);

        descPainter.paint(
          canvas,
          center +
              Offset(
                -descPainter.width / 2,
                26 + labelPainter.height + 2,
              ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant OverworldPainter oldDelegate) => true;
}
