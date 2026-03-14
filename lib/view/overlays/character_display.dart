import 'package:flutter/material.dart';

/// Displays a single character's full-body image with animated active/inactive states.
///
/// When [isActive] is true, the character is fully visible with a slight scale-up.
/// When inactive, the character is dimmed via a color filter.
class CharacterDisplay extends StatelessWidget {
  const CharacterDisplay({
    required this.assetPath,
    required this.isActive,
    required this.alignment,
    required this.flip,
    super.key,
  });

  /// Path to the full-body image asset.
  final String assetPath;

  /// Whether this character is the active speaker.
  final bool isActive;

  /// Horizontal alignment: -1.0 for left, 1.0 for right.
  final Alignment alignment;

  /// Whether to flip the image horizontally, for dialogue conversation.
  final bool flip;

  @override
  Widget build(BuildContext context) {
    if (assetPath.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: alignment,
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 300),
        child: AnimatedScale(
          scale: isActive ? 1.0 : 0.9,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: ColorFiltered(
            colorFilter: isActive
                ? const ColorFilter.mode(
                    Colors.transparent,
                    BlendMode.multiply,
                  )
                : ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.4),
                    BlendMode.srcATop,
                  ),
            child: Transform.flip(
              flipX: flip,
              child: Image.asset(
                assetPath,
                height: MediaQuery.of(context).size.height * 0.7,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
