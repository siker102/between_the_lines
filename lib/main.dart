import 'package:between_the_lines/model/level_repository.dart';
import 'package:between_the_lines/model/overworld/dialogue_data.dart';
import 'package:between_the_lines/model/overworld/overworld_state.dart';
import 'package:between_the_lines/model/overworld/story_edge.dart';
import 'package:between_the_lines/view/overlays/dialogue_overlay.dart';
import 'package:between_the_lines/view/overworld/overworld_screen.dart';
import 'package:between_the_lines/view/stealth_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameShell(),
    ),
  );
}

/// Top-level navigation state.
enum AppScreen { loading, overworld, dialogue, gameplay }

/// Navigation shell that manages the flow:
/// Overworld → Dialogue → Gameplay → Dialogue → Overworld → ...
class GameShell extends StatefulWidget {
  const GameShell({super.key});

  @override
  State<GameShell> createState() => _GameShellState();
}

class _GameShellState extends State<GameShell> {
  AppScreen _screen = AppScreen.loading;

  // Data
  late OverworldState _overworldState;
  StealthGame? _currentGame;

  // For dialogue flow
  DialogueData? _pendingDialogue;
  StoryEdge? _pendingEdge;
  bool _isPreLevelDialogue = true;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    final chapters = await LevelRepository.loadAllChapters();
    final chapter = chapters.first;
    final dialogues = await LevelRepository.loadAllDialogues(chapter);

    _overworldState = OverworldState(
      chapter: chapter,
      dialogues: dialogues,
    );

    // Check if the start node has a dialogue to show first.
    final startNode = _overworldState.currentNode;
    final startDialogue = _overworldState.getDialogue(startNode.dialogueId);

    if (startDialogue != null) {
      setState(() {
        _pendingDialogue = startDialogue;
        _isPreLevelDialogue = true;
        _pendingEdge = null;
        _screen = AppScreen.dialogue;
      });
    } else {
      setState(() => _screen = AppScreen.overworld);
    }
  }

  void _onEdgeSelected(StoryEdge edge) {
    // Start pre-level dialogue (destination node's dialogue) or go straight to gameplay.
    _pendingEdge = edge;

    // Go straight to gameplay.
    _startGameplay(edge);
  }

  Future<void> _startGameplay(StoryEdge edge) async {
    final levelData = await LevelRepository.loadLevel(edge.levelAssetPath);

    final game = StealthGame(
      levelData: levelData,
      onLevelComplete: () => _onLevelComplete(edge),
    );

    setState(() {
      _currentGame = game;
      _screen = AppScreen.gameplay;
    });
  }

  void _onLevelComplete(StoryEdge edge) {
    // Complete the edge and advance to the destination node.
    _overworldState.completeCurrentNode();
    _overworldState.completeEdge(edge.id);

    // Return to overworld. Arrival animation will play, and then trigger dialogue.
    setState(() {
      _currentGame = null;
      _screen = AppScreen.overworld;
    });
  }

  void _onArrivalAnimationComplete() {
    // Check if the destination node has dialogue after arriving.
    final destNode = _overworldState.currentNode;
    final postDialogue = _overworldState.getDialogue(destNode.dialogueId);

    if (postDialogue != null) {
      setState(() {
        _pendingDialogue = postDialogue;
        _isPreLevelDialogue = false;
        _pendingEdge = null;
        _screen = AppScreen.dialogue;
      });
    }
  }

  void _onDialogueComplete() {
    if (_isPreLevelDialogue && _pendingEdge != null) {
      // After pre-level dialogue, start the level.
      _startGameplay(_pendingEdge!);
    } else {
      // After post-level dialogue (or intro), check if a boss level is needed.
      if (_overworldState.needsBossLevel) {
        _startBossLevel();
      } else {
        setState(() {
          _pendingDialogue = null;
          _currentGame = null;
          _screen = AppScreen.overworld;
        });
      }
    }
  }

  Future<void> _startBossLevel() async {
    final district = _overworldState.currentDistrict;
    final levelData = await LevelRepository.loadLevel(district.bossLevelAssetPath!);

    final game = StealthGame(
      levelData: levelData,
      onLevelComplete: _onBossLevelComplete,
    );

    setState(() {
      _currentGame = game;
      _screen = AppScreen.gameplay;
      _pendingDialogue = null;
    });
  }

  void _onBossLevelComplete() {
    _overworldState.completeBossLevel();
    setState(() {
      _currentGame = null;
      _screen = AppScreen.overworld;
    });
  }

  void _onTransitionOutBoundReached(Offset direction) {
    if (_overworldState.advanceToNextDistrict()) {
      setState(() {
        _overworldState.isTransitioningIn = true;
        _overworldState.lastTransitionDirection = direction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case AppScreen.loading:
        return const Scaffold(
          backgroundColor: Color(0xFF0D1117),
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF64B5F6),
            ),
          ),
        );

      case AppScreen.overworld:
        return OverworldScreen(
          state: _overworldState,
          onEdgeSelected: _onEdgeSelected,
          onArrivalAnimationComplete: _onArrivalAnimationComplete,
          onTransitionOutBoundReached: _onTransitionOutBoundReached,
        );

      case AppScreen.dialogue:
        return DialogueOverlay(
          dialogue: _pendingDialogue!,
          characters: _overworldState.chapter.characters,
          onComplete: _onDialogueComplete,
        );

      case AppScreen.gameplay:
        return Scaffold(
          body: GameWidget(
            game: _currentGame!,
            overlayBuilderMap: {
              'failure': (context, game) => _FailureOverlay(
                    onRetry: () {
                      (game! as StealthGame).resetCurrentStage();
                    },
                  ),
            },
          ),
        );
    }
  }
}

class _FailureOverlay extends StatelessWidget {
  const _FailureOverlay({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You Failed!',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay),
              label: const Text('Retry Stage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
