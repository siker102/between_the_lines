import 'package:between_the_lines/model/entities/character.dart';
import 'package:between_the_lines/model/game_state.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/level_data.dart';
import 'package:between_the_lines/model/systems/movement_calculator.dart';
import 'package:between_the_lines/model/systems/vision_calculator.dart';
import 'package:between_the_lines/view/components/character_component.dart';
import 'package:between_the_lines/view/components/enemy_component.dart';
import 'package:between_the_lines/view/components/goal_indicator_component.dart';
import 'package:between_the_lines/view/components/hex_tile.dart';
import 'package:between_the_lines/view/components/level_view_component.dart';
import 'package:between_the_lines/view/components/patrol_path_component.dart';
import 'package:between_the_lines/view/utils/hex_math.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class StealthGame extends FlameGame {
  late GameState gameState;

  // Level tracking
  int _currentLevelIndex = 0;
  LevelViewComponent? _currentLevelView;
  late TextComponent _levelCounter;

  // Component references (for the active level)
  final Map<GridCoordinate, HexTile> _tileComponents = {};
  final List<CharacterComponent> _characterComponents = [];
  final List<EnemyComponent> _enemyComponents = [];
  final List<GoalIndicatorComponent> _goalIndicators = [];

  CharacterComponent? _draggedCharacter;
  Set<GridCoordinate> _currentReachableTiles = {};

  StealthGame() : super();

  @override
  Color backgroundColor() => Colors.black87;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializeLevel(_currentLevelIndex);
    _buildInitialWorld();
    _setupUI();
  }

  void _setupUI() {
    _levelCounter = TextComponent(
      text: 'Level ${_currentLevelIndex + 1}',
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    camera.viewport.add(_levelCounter);

    // Debug Button
    final debugButton = ButtonComponent(
      button: TextComponent(
        text: 'DEBUG WIN',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      position: Vector2(20, 60),
      onPressed: _debugWin,
    );
    camera.viewport.add(debugButton);
  }

  void _debugWin() {
    if (gameState.status != GameStatus.playing) return;

    // Teleport all characters to row 0
    for (final char in gameState.characters) {
      // col = q + r/2
      final col = char.position.q + (char.position.r / 2).floor();
      char.position = GridCoordinate(col, 0);
    }

    for (final cc in _characterComponents) {
      cc.syncWithModel();
    }

    // Trigger win check
    gameState.status = GameStatus.won;
    _transitionToNextLevel();
  }

  // ── Level Setup ──

  void _initializeLevel(int index) {
    final data = levelsRepository[index];
    final grid = data.createGrid();

    // Player characters
    List<Character> characters;
    if (_currentLevelIndex == 0) {
      // Start at the bottom for the first level (row 12 for a 13-row grid)
      characters = [
        Character(
          id: 'c1',
          position: GridCoordinate(2 - (12 / 2).floor(), 12),
        ),
        Character(
          id: 'c2',
          position: GridCoordinate(3 - (12 / 2).floor(), 12),
        ),
      ];
    } else {
      // Retain positions from previous level (already updated in transition)
      characters = gameState.characters;
    }

    gameState = GameState(
      grid: grid,
      characters: characters,
      enemies: data.enemies,
    );

    for (final enemy in gameState.enemies) {
      enemy.initializePath(grid);
    }
  }

  // ── World Construction ──

  LevelViewComponent _createLevelView(GameState state) {
    final tiles = <HexTile>[];
    final enemyComps = <EnemyComponent>[];
    final paths = <PatrolPathComponent>[];

    _tileComponents.clear();
    _enemyComponents.clear();

    final w = state.grid.width;
    final h = state.grid.height;

    for (var r = 0; r < h; r++) {
      for (var c = 0; c < w; c++) {
        final q = c - (r / 2).floor();
        final coord = GridCoordinate(q, r);
        final type = state.grid.getTileType(coord);

        final tile = HexTile(
          coordinate: coord,
          type: type,
        );
        _tileComponents[coord] = tile;
        tiles.add(tile);
      }
    }

    for (final enemy in state.enemies) {
      paths.add(PatrolPathComponent(enemy: enemy));
      final ec = EnemyComponent(model: enemy);
      _enemyComponents.add(ec);
      enemyComps.add(ec);
    }

    return LevelViewComponent(
      tiles: tiles,
      enemies: enemyComps,
      patrolPaths: paths,
    )..priority = 0; // Explicitly set priority
  }

  Future<void> _buildInitialWorld() async {
    _currentLevelView = _createLevelView(gameState);
    world.add(_currentLevelView!);

    // Add characters globally to world so they don't slide with levels automatically
    // unless we want them to (but the user said "maps slide down", implying characters stay)
    for (final char in gameState.characters) {
      final cc = CharacterComponent(
        model: char,
        onDragStartCallback: _onCharacterDragStart,
        onDragUpdateCallback: _onCharacterDragUpdate,
        onDragEndCallback: _onCharacterDragEnd,
      );
      cc.priority = 10; // Ensure characters are on top
      _characterComponents.add(cc);
      world.add(cc);
    }

    _updateEnemyVisionHighlights();
    _fitCamera();
  }

  void _fitCamera() {
    // 13-row grid bounding box:
    // Left edge ~ -28, Right edge ~ 305 -> Width ~ 333
    // Top edge ~ -32, Bottom edge ~ 608 -> Height ~ 640
    // Center ~ Vector2(138.5, 288)

    camera.viewfinder.position = Vector2(138.5, 288);
    camera.viewfinder.zoom = 1.0;

    if (size.x > 0 && size.y > 0) {
      // Calculate zoom to fit the grid with some padding
      final zoomX = size.x / 360; // 333 + 27 padding
      final zoomY = size.y / 680; // 640 + 40 padding
      camera.viewfinder.zoom = (zoomX < zoomY ? zoomX : zoomY).clamp(0.5, 2.0);
    }
  }

  // ── Interaction Logic ──

  void _onCharacterDragStart(CharacterComponent cc) {
    if (gameState.status != GameStatus.playing) return;

    _draggedCharacter = cc;
    _currentReachableTiles = MovementCalculator.calculateReachableTiles(
      gameState.grid,
      cc.model,
    );

    for (final coord in _currentReachableTiles) {
      _tileComponents[coord]?.highlightColors.add(Colors.blue);
    }
    _spawnGoalIndicators();
  }

  void _onCharacterDragUpdate(CharacterComponent cc) {}

  void _onCharacterDragEnd(CharacterComponent cc) {
    if (_draggedCharacter == null) return;

    // Adjust drop position based on level view offset if needed
    // Actually HexMath handles absolute world coordinates, and tiles are relative to LevelView.
    // So we need to subtract LevelView position from world position to get local...
    // OR just use the tile components to find the closest one.

    final worldPos = cc.position;
    final localPos = worldPos - _currentLevelView!.position;
    final dropPos = HexMath.screenToGrid(localPos);

    for (final coord in _currentReachableTiles) {
      _tileComponents[coord]?.highlightColors.remove(Colors.blue);
    }
    _removeGoalIndicators();

    final didMove = _currentReachableTiles.contains(dropPos) && dropPos != cc.model.position;

    if (didMove) {
      cc.model.position = dropPos;
      cc.model.hasMoved = true;
      cc.syncWithModel();

      final allMoved = gameState.characters.every((c) => c.hasMoved);

      if (allMoved) {
        gameState.endTurn();
        _clearEnemyVisionHighlights();
        for (final ec in _enemyComponents) {
          ec.animateToModel();
        }
        _updateEnemyVisionHighlights();
      } else {
        _updateEnemyVisionHighlights();
      }

      if (gameState.status == GameStatus.won) {
        _transitionToNextLevel();
      } else if (gameState.status == GameStatus.lost) {
        debugPrint('GAME OVER: ${gameState.statusMessage}');
      }
    } else {
      cc.syncWithModel();
    }

    _draggedCharacter = null;
    _currentReachableTiles.clear();
  }

  // ── Transition Logic ──

  Future<void> _transitionToNextLevel() async {
    if (_currentLevelIndex + 1 >= levelsRepository.length) {
      debugPrint('ALL LEVELS CLEARED!');
      return;
    }

    final oldLevelView = _currentLevelView!;
    _currentLevelIndex++;

    // 1. Prepare next level data
    _initializeLevel(_currentLevelIndex);

    // 2. Create next level view
    final nextLevelView = _createLevelView(gameState);

    // 3. Animate sliding
    const duration = 1.5;
    const curve = Curves.easeInOutCubic;

    // Perfect alignment offset calculation
    // Logical column 0 at row 12 is GridCoordinate(-6, 12) due to axial offset: q = col - floor(r/2)
    // Logical column 0 at row 0 is GridCoordinate(0, 0)
    // We want these two to align vertically.
    final row12Pos = HexMath.gridToScreen(const GridCoordinate(-6, 12));
    final row0Pos = HexMath.gridToScreen(const GridCoordinate(0, 0));
    final offset = row12Pos - row0Pos;

    nextLevelView.position = oldLevelView.position - offset;
    world.add(nextLevelView);
    _currentLevelView = nextLevelView;

    // Temporary lock interaction
    final originalStatus = gameState.status;
    gameState.status = GameStatus.lost;

    oldLevelView.add(
      MoveByEffect(
        offset,
        EffectController(duration: duration, curve: curve),
        onComplete: oldLevelView.removeFromParent,
      ),
    );

    nextLevelView.add(
      MoveByEffect(
        offset,
        EffectController(duration: duration, curve: curve),
        onComplete: () {
          // NOW update model position to match visual result
          for (final char in gameState.characters) {
            // column = q + floor(r/2). At r=0, column=q.
            // We want to map this directly to Row 12 start zone: q = column - floor(12/2) = column - 6
            final column = char.position.q;
            char.position = GridCoordinate(column - 6, 12);
          }
          for (final cc in _characterComponents) {
            cc.syncWithModel();
          }

          gameState.status = originalStatus == GameStatus.won ? GameStatus.playing : originalStatus;
          _updateEnemyVisionHighlights();
        },
      ),
    );

    for (final cc in _characterComponents) {
      cc.add(
        MoveByEffect(
          offset,
          EffectController(duration: duration, curve: curve),
        ),
      );
    }

    _levelCounter.text = 'Level ${_currentLevelIndex + 1}';
  }

  // ── Highlighting ──

  void _clearEnemyVisionHighlights() {
    for (final tile in _tileComponents.values) {
      tile.highlightColors.remove(Colors.red);
    }
  }

  void _updateEnemyVisionHighlights() {
    _clearEnemyVisionHighlights();
    for (final enemy in gameState.enemies) {
      final vision = VisionCalculator.calculateVision(gameState.grid, enemy);
      for (final coord in vision) {
        _tileComponents[coord]?.highlightColors.add(Colors.red);
      }
    }
  }

  // ── Goal Indicators ──

  void _spawnGoalIndicators() {
    for (final coord in _currentReachableTiles) {
      final tile = _tileComponents[coord];
      if (tile != null && tile.type == TileType.targetZone) {
        final indicator = GoalIndicatorComponent(
          tileCenter: HexMath.gridToScreen(coord),
        );
        _goalIndicators.add(indicator);
        // Add to level view so it moves with it during transition if active?
        // Actually goal indicators are only active during drag.
        _currentLevelView!.add(indicator);
      }
    }
  }

  void _removeGoalIndicators() {
    for (final indicator in _goalIndicators) {
      indicator.removeFromParent();
    }
    _goalIndicators.clear();
  }
}
