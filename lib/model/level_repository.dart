import 'dart:convert';
import 'package:between_the_lines/model/level_data.dart';
import 'package:between_the_lines/model/overworld/chapter_data.dart';
import 'package:between_the_lines/model/overworld/dialogue_data.dart';
import 'package:flutter/services.dart';

/// Loads [LevelData], [ChapterData], and [DialogueData] from JSON asset files.
class LevelRepository {
  /// Asset paths for all levels, in order.
  static const List<String> _levelAssets = [
    'assets/levels/level_1.json',
  ];

  /// Asset paths for all chapters, in order.
  static const List<String> _chapterAssets = [
    'assets/chapters/chapter_1.json',
  ];

  /// Loads every level defined in [_levelAssets].
  static Future<List<LevelData>> loadAllLevels() async {
    final levels = <LevelData>[];
    for (final path in _levelAssets) {
      levels.add(await loadLevel(path));
    }
    return levels;
  }

  /// Loads a single level from [assetPath].
  static Future<LevelData> loadLevel(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return LevelData.fromJson(jsonMap);
  }

  /// Loads every chapter defined in [_chapterAssets].
  static Future<List<ChapterData>> loadAllChapters() async {
    final chapters = <ChapterData>[];
    for (final path in _chapterAssets) {
      chapters.add(await loadChapter(path));
    }
    return chapters;
  }

  /// Loads a single chapter from [assetPath].
  static Future<ChapterData> loadChapter(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return ChapterData.fromJson(jsonMap);
  }

  /// Loads a single dialogue from [assetPath].
  static Future<DialogueData> loadDialogue(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return DialogueData.fromJson(jsonMap);
  }

  /// Loads all dialogues referenced by nodes in [chapter].
  ///
  /// Returns a map of dialogue ID → [DialogueData].
  static Future<Map<String, DialogueData>> loadAllDialogues(
    ChapterData chapter,
  ) async {
    final dialogues = <String, DialogueData>{};
    for (final node in chapter.nodes) {
      if (node.dialogueId != null) {
        final path = 'assets/dialogues/${node.dialogueId}.json';
        final dialogue = await loadDialogue(path);
        dialogues[dialogue.id] = dialogue;
      }
    }
    return dialogues;
  }
}
