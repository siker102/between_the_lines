import 'package:between_the_lines/model/overworld/character_profile.dart';
import 'package:between_the_lines/model/overworld/dialogue_data.dart';
import 'package:between_the_lines/view/overlays/character_display.dart';
import 'package:between_the_lines/view/utils/utility.dart';
import 'package:flutter/material.dart';

/// Full-screen visual novel dialogue overlay.
///
/// Displays a multi-character conversation with full-body character images,
/// typewriter text, and speaker name plates. Tap to advance through lines.
class DialogueOverlay extends StatefulWidget {
  const DialogueOverlay({
    required this.dialogue,
    required this.characters,
    required this.onComplete,
    super.key,
  });

  /// The conversation to display.
  final DialogueData dialogue;

  /// Character registry mapping IDs to profiles (display names + images).
  final Map<String, CharacterProfile> characters;

  /// Called when all dialogue lines have been exhausted.
  final VoidCallback onComplete;

  @override
  State<DialogueOverlay> createState() => _DialogueOverlayState();
}

class _DialogueOverlayState extends State<DialogueOverlay>
    with TickerProviderStateMixin {
  int _currentLineIndex = 0;
  bool _isTextComplete = false;
  late AnimationController _typewriterController;

  // Track which character positions (left / right) are assigned.
  final Map<String, _CharacterSlot> _characterSlots = {};

  DialogueLine get _currentLine => widget.dialogue.lines[_currentLineIndex];

  CharacterProfile? get _currentSpeaker =>
      widget.characters[_currentLine.speakerId];

  bool get _isLastLine => _currentLineIndex >= widget.dialogue.lines.length - 1;

  @override
  void initState() {
    super.initState();
    _typewriterController = AnimationController(vsync: this);
    _assignCharacterSlots();
    _startTypewriter();
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    super.dispose();
  }

  /// Assign characters to left/right slots based on order of appearance.
  void _assignCharacterSlots() {
    var nextSlot = _CharacterSlot.left;
    for (final line in widget.dialogue.lines) {
      final id = line.speakerId;
      if (!_characterSlots.containsKey(id)) {
        final profile = widget.characters[id];
        // Skip characters without images (e.g. narrator).
        if (profile != null && profile.fullBodyAsset.isNotEmpty) {
          _characterSlots[id] = nextSlot;
          nextSlot = nextSlot == _CharacterSlot.left
              ? _CharacterSlot.right
              : _CharacterSlot.left;
        }
      }
    }
  }

  void _startTypewriter() {
    final text = _currentLine.text;
    // ~30ms per character for typewriter speed.
    final duration = Duration(milliseconds: text.length * 30);
    _typewriterController
      ..reset()
      ..duration = duration
      ..forward().then((_) {
        if (mounted) {
          setState(() => _isTextComplete = true);
        }
      });
    setState(() => _isTextComplete = false);
  }

  void _onTap() {
    if (!_isTextComplete) {
      // First tap: complete current text instantly.
      _typewriterController.forward(from: 1.0);
      setState(() => _isTextComplete = true);
      return;
    }

    if (_isLastLine) {
      widget.onComplete();
      return;
    }

    // Advance to next line.
    setState(() {
      _currentLineIndex++;
    });
    _startTypewriter();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _onTap,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: screenSize.width,
          height: screenSize.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0D1117).withAlpha(150),
                const Color(0xFF0D1117).withAlpha(250),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Character images
              ..._buildCharacterImages(),

              // Dialogue box at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildDialogueBox(screenSize),
              ),

              // "Tap to continue" indicator
              if (_isTextComplete)
                Positioned(
                  right: 32,
                  bottom: 24,
                  child: _buildContinueIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCharacterImages() {
    final widgets = <Widget>[];

    for (final entry in _characterSlots.entries) {
      final characterId = entry.key;
      final slot = entry.value;
      final profile = widget.characters[characterId];
      if (profile == null) continue;

      final isActive = _currentLine.speakerId == characterId;
      final alignment = slot == _CharacterSlot.left
          ? Alignment.bottomLeft
          : Alignment.bottomRight;

      widgets.add(
        Positioned(
          left: slot == _CharacterSlot.left ? 20 : null,
          right: slot == _CharacterSlot.right ? 20 : null,
          bottom: 10,
          child: CharacterDisplay(
            assetPath: profile.fullBodyAsset,
            isActive: isActive,
            alignment: alignment,
            flip: slot == _CharacterSlot.left,
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildDialogueBox(Size screenSize) {
    final speakerName = _currentSpeaker?.displayName ?? _currentLine.speakerId;

    return Container(
      width: screenSize.width,
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/overworld/page.png'), fit: BoxFit.fill),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speaker name plate
          Container(
            padding: const EdgeInsets.only(top: 12, left: 12),
            // decoration: BoxDecoration(
            //   color: _speakerColor.withValues(alpha: 0.9),
            //   borderRadius: const BorderRadius.only(
            //     topLeft: Radius.circular(12),
            //     topRight: Radius.circular(12),
            //   ),
            // ),
            child: Text(
              speakerName,
              style: const TextStyle(
                color: headingAmberColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

          // Text box
          Container(
            width: screenSize.width,
            padding: const EdgeInsets.all(20),
            // decoration: BoxDecoration(
            //   color: Colors.black.withValues(alpha: 0.85),
            //   borderRadius: const BorderRadius.only(
            //     topRight: Radius.circular(12),
            //     bottomLeft: Radius.circular(12),
            //     bottomRight: Radius.circular(12),
            //   ),
            //   border: Border.all(
            //     color: _speakerColor.withValues(alpha: 0.5),
            //     width: 1.5,
            //   ),
            // ),
            child: AnimatedBuilder(
              animation: _typewriterController,
              builder: (context, child) {
                final text = _currentLine.text;
                final visibleChars =
                    (_typewriterController.value * text.length).round();
                return Text(
                  text.substring(0, visibleChars),
                  style: const TextStyle(
                    color: dialogueAmberColor,
                    fontSize: 18,
                    height: 1.5,
                    decoration: TextDecoration.none,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value * 2).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 4),
            child: const Text(
              '▼',
              style: TextStyle(
                color: dialogueAmberColor,
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        );
      },
    );
  }

  Color get _speakerColor {
    final speakerId = _currentLine.speakerId;
    // Assign consistent colors per character.
    final index = _characterSlots.keys.toList().indexOf(speakerId);
    const colors = [
      Color(0xFF2196F3), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFFF44336), // Red
      Color(0xFFFF9800), // Orange
      Color(0xFF9C27B0), // Purple
    ];
    if (index >= 0 && index < colors.length) return colors[index];
    // Default for narrator or unknown.
    return const Color(0xFF607D8B);
  }
}

enum _CharacterSlot { left, right }
