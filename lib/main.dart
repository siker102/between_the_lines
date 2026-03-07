import 'package:between_the_lines/view/stealth_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(
          game: StealthGame(),
        ),
      ),
    ),
  );
}
