import 'package:between_the_lines/model/entities/character.dart';
import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:between_the_lines/model/systems/vision_calculator.dart';

enum GameStatus {
  playing,
  won,
  lost,
}

class GameState {
  final HexGrid grid;
  final List<Character> characters;
  final List<Enemy> enemies;

  GameStatus status = GameStatus.playing;
  String? statusMessage;

  GameState({
    required this.grid,
    required this.characters,
    required this.enemies,
  });

  Character? getCharacter(String id) {
    try {
      return characters.firstWhere((c) => c.id == id);
    } on StateError {
      return null;
    }
  }

  void endTurn() {
    if (status != GameStatus.playing) {
      return;
    }

    // Reset move status for all characters
    for (final char in characters) {
      char.hasMoved = false;
    }

    // Enemies take their turn
    for (final enemy in enemies) {
      enemy.advancePatrol();
    }

    _checkWinLossConditions();
  }

  void _checkWinLossConditions() {
    // Check Loss (if any character is in any enemy's vision)
    for (final enemy in enemies) {
      final visibleTiles = VisionCalculator.calculateVision(grid, enemy);
      for (final character in characters) {
        if (visibleTiles.contains(character.position)) {
          status = GameStatus.lost;
          statusMessage = 'You were spotted! Big Brother is watching.';
          return;
        }
      }
    }

    // Check Win (if ALL characters are in a target zone)
    var allInZone = true;
    for (final character in characters) {
      if (grid.getTileType(character.position) != TileType.targetZone) {
        allInZone = false;
        break;
      }
    }

    if (allInZone && characters.isNotEmpty) {
      status = GameStatus.won;
      statusMessage = 'Level Clear!';
    }
  }
}
