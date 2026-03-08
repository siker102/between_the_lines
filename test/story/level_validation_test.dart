import 'dart:convert';
import 'dart:io';

import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:between_the_lines/model/level_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Enemy Patrol Validation', () {
    test('No enemy patrol paths may cross a PressureObstacle', () async {
      // 1. Read game_story.json to find all levels
      final storyFile = File('assets/story/game_story.json');
      expect(storyFile.existsSync(), isTrue, reason: 'game_story.json not found');

      final storyJson = jsonDecode(await storyFile.readAsString());
      final gameStory = storyJson as Map<String, dynamic>;

      final levelPaths = <String>{};

      // Extract from districts
      if (gameStory['districts'] != null) {
        for (final district in gameStory['districts'] as List) {
          if (district['bossLevelAssetPath'] != null) {
            levelPaths.add(district['bossLevelAssetPath'] as String);
          }
        }
      }

      // Extract from edges
      if (gameStory['edges'] != null) {
        for (final edge in gameStory['edges'] as List) {
          if (edge['levelAssetPath'] != null) {
            levelPaths.add(edge['levelAssetPath'] as String);
          }
        }
      }

      // 2. Load all levels and iterate stages
      for (final path in levelPaths) {
        final levelFile = File(path);
        expect(levelFile.existsSync(), isTrue, reason: 'Level file $path not found');

        final levelJson = jsonDecode(await levelFile.readAsString());
        final levelData = LevelData.fromJson(levelJson as Map<String, dynamic>);

        for (var i = 0; i < levelData.stages.length; i++) {
          final stage = levelData.stages[i];
          final grid = stage.createGrid();

          // 3. For each enemy, verify their path doesn't hit a pressure obstacle
          for (final enemy in stage.enemies) {
            enemy.initializePath(grid);
            for (final coord in enemy.expandedPath) {
              final type = grid.getTileType(coord);
              if (type == TileType.pressureObstacle) {
                fail(
                  'Validation Error in $path (Stage ${i + 1}): Enemy ${enemy.id} patrol path crosses a PressureObstacle at coordinate $coord.',
                );
              }
            }
          }
        }
      }
    });
  });
}
