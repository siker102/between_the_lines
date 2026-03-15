import 'package:between_the_lines/view/utils/utility.dart';
import 'package:flutter/material.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({required this.onDismissed, super.key});

  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismissed,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BETWEEN THE LINES',
                    style: TextStyle(
                      fontFamily: appFontFamily,
                      color: headingAmberColor,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'BIG BROTHER IS WATCHING',
                    style: TextStyle(
                      fontFamily: appFontFamily,
                      color: dialogueAmberColor.withAlpha(180),
                      fontSize: 16,
                      letterSpacing: 4,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 64),
                  Text(
                    'CREATED BY',
                    style: TextStyle(
                      fontFamily: appFontFamily,
                      color: dialogueAmberColor.withAlpha(120),
                      fontSize: 12,
                      letterSpacing: 3,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kerowav  ·  Brvank  ·  SuluX',
                    style: TextStyle(
                      fontFamily: appFontFamily,
                      color: dialogueAmberColor,
                      fontSize: 20,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 80),
                  _BlinkingText(
                    text: 'CLICK ANYWHERE TO CONTINUE',
                    style: TextStyle(
                      fontFamily: appFontFamily,
                      color: dialogueAmberColor.withAlpha(150),
                      fontSize: 14,
                      letterSpacing: 2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Text(
                'Made for the 2026 Flame Game Jam, Sounds by JDSherbert – https://jdsherbert.itch.io',
                style: TextStyle(
                  fontFamily: appFontFamily,
                  color: dialogueAmberColor.withAlpha(100),
                  fontSize: 10,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingText extends StatefulWidget {
  const _BlinkingText({required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  State<_BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<_BlinkingText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Text(widget.text, style: widget.style),
    );
  }
}
