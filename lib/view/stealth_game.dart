import 'package:between_the_lines/model/entities/character.dart';
import 'package:between_the_lines/model/game_state.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
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
import 'package:between_the_lines/view/utils/utility.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

const _pressureKeyPalette = [
  Color(0xFF00A7A7), // teal
  Color(0xFFFF8C00), // orange
  Color(0xFFCC44CC), // magenta
  Color(0xFFCCCC00), // gold
  Color(0xFF3399FF), // cyan-blue
];

class StealthGame extends FlameGame {
  late GameState gameState;
  final LevelData _level;
  final int _districtTier;
  final void Function(int totalTurns)? onLevelComplete;
  static bool _musicEnabled = true;
  late TextComponent _musicLabel;

  // Stage tracking (within this single level)
  int _currentStageIndex = 0;
  LevelViewComponent? _currentLevelView;
  late TextComponent _levelCounter;

  // Component references (for the active stage)
  final Map<GridCoordinate, HexTile> _tileComponents = {};
  final List<CharacterComponent> _characterComponents = [];
  final List<EnemyComponent> _enemyComponents = [];
  final List<GoalIndicatorComponent> _goalIndicators = [];

  bool showCoordinates = false;

  CharacterComponent? _draggedCharacter;
  Map<GridCoordinate, Reachability> _currentReachableTiles = {};

  // Snapshot of character positions at stage start (for reset)
  Map<String, GridCoordinate> _stageStartPositions = {};

  // Turn counter (cumulative across all stages and levels)
  int _totalTurnCount;
  int _stageStartTurnCount = 0;
  TextComponent? _turnCounter;

  /// The total number of turns taken so far (for testing / external reads).
  int get totalTurnCount => _totalTurnCount;

  StealthGame({
    required LevelData levelData,
    required int districtTier,
    this.onLevelComplete,
    int initialTurnCount = 0,
  }) : _level = levelData,
       _districtTier = districtTier,
       _totalTurnCount = initialTurnCount;

  @override
  void onRemove() {
    FlameAudio.bgm.stop();
    super.onRemove();
  }

  @override
  Color backgroundColor() => Colors.black87;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final tc = _turnCounter;
    if (tc != null && tc.isMounted) {
      tc.position = Vector2(size.x - 20, 20);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializeStage();
    _buildInitialWorld();
    _setupUI();
    if (_musicEnabled) {
      FlameAudio.bgm.play('music/district_$_districtTier.wav', volume: 1.0);
    }
  }

  void _setupUI() {
    _levelCounter = TextComponent(
      text: _stageLabel,
      position: Vector2(20, 20),
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: appFontFamily,
        ),
      ),
    );
    camera.viewport.add(_levelCounter);

    _turnCounter = TextComponent(
      text: _turnLabel,
      anchor: Anchor.topRight,
      position: Vector2(size.x - 20, 20),
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: appFontFamily,
        ),
      ),
    );
    camera.viewport.add(_turnCounter!);

    // Restart Stage Button
    final restartButton = ButtonComponent(
      button: TextComponent(
        text: 'RESTART',
        textRenderer: TextPaint(
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: appFontFamily,
          ),
        ),
      ),
      position: Vector2(20, 60),
      onPressed: resetCurrentStage,
    );
    camera.viewport.add(restartButton);

    // End Turn Button
    final endTurnButton = ButtonComponent(
      button: TextComponent(
        text: 'END TURN',
        textRenderer: TextPaint(
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: appFontFamily,
          ),
        ),
      ),
      position: Vector2(20, 100),
      onPressed: _endTurnForAll,
    );
    camera.viewport.add(endTurnButton);

    // Music Toggle
    _musicLabel = TextComponent(
      text: _musicEnabled ? 'MUSIC: ON' : 'MUSIC: OFF',
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: appFontFamily,
        ),
      ),
    );
    final musicButton = ButtonComponent(
      button: _musicLabel,
      position: Vector2(size.x - 160, size.y - 40),
      onPressed: _toggleMusic,
    );
    camera.viewport.add(musicButton);
  }

  String get _turnLabel => 'Turns: $_totalTurnCount';

  String get _stageLabel {
    if (_level.stages.length == 1) {
      return _level.name;
    }
    return '${_level.name} - Stage ${_currentStageIndex + 1}';
  }

  void _toggleMusic() {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) {
      FlameAudio.bgm.play('music/district_$_districtTier.wav', volume: 1.0);
      _musicLabel.text = 'MUSIC: ON';
    } else {
      FlameAudio.bgm.stop();
      _musicLabel.text = 'MUSIC: OFF';
    }
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
    _transitionToNextStage();
  }

  // ── Stage Setup ──

  void _initializeStage() {
    final stage = _level.stages[_currentStageIndex];
    final grid = stage.createGrid();

    // Player characters
    List<Character> characters;
    if (_currentStageIndex == 0) {
      // Start at the bottom for the very first stage
      final lastRow = stage.height - 1;
      characters = [
        for (var i = 0; i < _level.characterStartX.length; i++)
          Character(
            id: 'c${i + 1}',
            position: GridCoordinate(
              _level.characterStartX[i] - (lastRow / 2).floor(),
              lastRow,
            ),
          ),
      ];
    } else {
      // Retain positions from previous stage and remap them to the start of the new stage
      final nextLastRow = stage.height - 1;
      characters = gameState.characters;
      for (final char in characters) {
        final offsetCol = char.position.q + (char.position.r / 2).floor();
        final newQ = offsetCol - (nextLastRow / 2).floor();
        char.position = GridCoordinate(newQ, nextLastRow);
        char.hasMoved = false; // Reset move status for the new stage
      }
    }

    gameState = GameState(
      grid: grid,
      characters: characters,
      enemies: stage.createEnemies(),
    );

    for (final enemy in gameState.enemies) {
      enemy.initializePath(grid);
    }

    // Snapshot starting positions for stage reset
    _stageStartPositions = {
      for (final c in characters) c.id: c.position,
    };

    _stageStartTurnCount = _totalTurnCount;

    _updatePressurePlates();
  }

  // ── World Construction ──

  LevelViewComponent _createLevelView(GameState state) {
    final tiles = <HexTile>[];
    final enemyComps = <EnemyComponent>[];
    final paths = <PatrolPathComponent>[];

    _tileComponents.clear();
    _enemyComponents.clear();

    final stage = _level.stages[_currentStageIndex];
    final keyIndexMap = <String, int>{};
    for (final key in stage.tileKeys.values.toSet()) {
      keyIndexMap.putIfAbsent(key, () => keyIndexMap.length);
    }

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

        final tileKey = stage.tileKeys[coord];
        if (tileKey != null) {
          tile.pressureKeyColor = _pressureKeyPalette[
              keyIndexMap[tileKey]! % _pressureKeyPalette.length];
        }

        tile.showCoordinates = showCoordinates;
        _tileComponents[coord] = tile;
        tiles.add(tile);
      }
    }

    for (final enemy in state.enemies) {
      final ec = EnemyComponent(model: enemy);
      paths.add(PatrolPathComponent(enemy: enemy, enemyComponent: ec));
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
    for (final char in gameState.characters) {
      final cc = CharacterComponent(
        model: char,
        onDragStartCallback: _onCharacterDragStart,
        onDragUpdateCallback: _onCharacterDragUpdate,
        onDragEndCallback: _onCharacterDragEnd,
        onDoubleTapCallback: _onCharacterDoubleTap,
      );
      cc.priority = 10; // Ensure characters are on top
      _characterComponents.add(cc);
      world.add(cc);
    }

    _updateEnemyVisionHighlights();
    _fitCamera();
    _updateHidingTiles();
    _updatePressurePlateActive();
  }

  ({Vector2 position, double zoom}) _computeCameraFit(int stageIndex) {
    // Compute grid bounds dynamically from the given stage
    final stage = _level.stages[stageIndex];
    final lastRow = stage.height - 1;
    final lastCol = stage.width - 1;

    // Screen positions of the grid corners
    final topLeft = HexMath.gridToScreen(const GridCoordinate(0, 0));
    final qBottomRight = lastCol - (lastRow / 2).floor();
    final bottomRight =
        HexMath.gridToScreen(GridCoordinate(qBottomRight, lastRow));

    // Center the camera on the grid midpoint (with half-tile padding)
    final center = (topLeft + bottomRight) / 2;
    var currentZoom = 1.0;

    if (size.x > 0 && size.y > 0) {
      // World size with one-tile padding on each side
      final worldW = (bottomRight.x - topLeft.x).abs() + HexMath.width * 2;
      final worldH = (bottomRight.y - topLeft.y).abs() + HexMath.height * 2;
      final zoomX = size.x / worldW;
      final zoomY = size.y / worldH;
      currentZoom = (zoomX < zoomY ? zoomX : zoomY).clamp(0.5, 2.0);
    }

    return (position: center, zoom: currentZoom);
  }

  void _fitCamera() {
    final fit = _computeCameraFit(_currentStageIndex);
    camera.viewfinder.position = fit.position;
    camera.viewfinder.zoom = fit.zoom;
  }

  // ── Interaction Logic ──

  void _onCharacterDragStart(CharacterComponent cc) {
    if (gameState.status != GameStatus.playing) return;

    _draggedCharacter = cc;

    final stage = _level.stages[_currentStageIndex];

    // Safety check: is the character standing on a pressurePlate?
    if (stage.specialTiles[cc.model.position] == TileType.pressurePlate) {
      final key = stage.tileKeys[cc.model.position];
      if (key != null) {
        var keyStillActive = false;
        for (final otherChar in gameState.characters) {
          if (otherChar.id == cc.model.id) continue;
          if (stage.specialTiles[otherChar.position] ==
                  TileType.pressurePlate &&
              stage.tileKeys[otherChar.position] == key) {
            keyStillActive = true;
            break;
          }
        }

        // Also check if any enemy is on a same-key pressurePlate
        if (!keyStillActive) {
          for (final enemy in gameState.enemies) {
            if (stage.specialTiles[enemy.position] ==
                    TileType.pressurePlate &&
                stage.tileKeys[enemy.position] == key) {
              keyStillActive = true;
              break;
            }
          }
        }

        if (!keyStillActive) {
          var someoneOnObstacle = false;
          for (final anyChar in gameState.characters) {
            if (stage.specialTiles[anyChar.position] ==
                    TileType.pressureObstacle &&
                stage.tileKeys[anyChar.position] == key) {
              someoneOnObstacle = true;
              break;
            }
          }

          if (someoneOnObstacle) {
            // Safety Lock! Prevent movement that would crush a teammate
            _currentReachableTiles = {cc.model.position: Reachability.startPos};
            final color = Colors.blue.shade800;
            _tileComponents[cc.model.position]?.highlightColors.add(color);
            return;
          }
        }
      }
    }

    final allyPositions = gameState.characters
        .where((c) => c.id != cc.model.id)
        .map((c) => c.position)
        .toSet();
    final enemyPositions = gameState.enemies.map((e) => e.position).toSet();
    final nextTurnEnemyPositions =
        gameState.enemies.map((e) => e.nextPosition).toSet();

    // Calculate all currently observed tiles
    final observedTiles = <GridCoordinate>{};
    for (final enemy in gameState.enemies) {
      observedTiles
          .addAll(VisionCalculator.calculateVision(gameState.grid, enemy));
    }

    _currentReachableTiles = MovementCalculator.calculateReachableTiles(
      grid: gameState.grid,
      character: cc.model,
      allyPositions: allyPositions,
      enemyPositions: enemyPositions,
      nextTurnEnemyPositions: nextTurnEnemyPositions,
      observedTiles: observedTiles,
    );

    for (final entry in _currentReachableTiles.entries) {
      final coord = entry.key;
      final status = entry.value;

      Color color;
      switch (status) {
        case Reachability.walkable:
          color = Colors.blue;
        case Reachability.blockedByAlly:
          color = Colors.blue.shade800;
        case Reachability.blockedByEnemy:
          color = Colors.red.shade800;
        case Reachability.startPos:
          color = Colors.blue.shade800;
      }
      _tileComponents[coord]?.highlightColors.add(color);
    }
    _spawnGoalIndicators();
  }

  void _onCharacterDragUpdate(CharacterComponent cc) {}

  void _onCharacterDragEnd(CharacterComponent cc) {
    if (_draggedCharacter == null) {
      return;
    }

    final worldPos = cc.position;
    final localPos = worldPos - _currentLevelView!.position;
    final dropPos = HexMath.screenToGrid(localPos);

    for (final entry in _currentReachableTiles.entries) {
      final coord = entry.key;
      final status = entry.value;

      Color color;
      switch (status) {
        case Reachability.walkable:
          color = Colors.blue;
        case Reachability.blockedByAlly:
          color = Colors.blue.shade800;
        case Reachability.blockedByEnemy:
          color = Colors.red.shade800;
        case Reachability.startPos:
          color = Colors.blue.shade800;
      }
      _tileComponents[coord]?.highlightColors.remove(color);
    }
    _removeGoalIndicators();

    final isWalkable = _currentReachableTiles[dropPos] == Reachability.walkable;
    final didMove = isWalkable && dropPos != cc.model.position;

    if (didMove) {
      final startPos = cc.model.position;
      var finalPos = dropPos;

      // Teleportation
      final stageData = _level.stages[_currentStageIndex];
      if (stageData.specialTiles[finalPos] == TileType.teleport) {
        final destination = stageData.teleportLinks[finalPos];
        if (destination != null) {
          final otherPositions = gameState.characters
              .where((c) => c.id != cc.model.id)
              .map((c) => c.position)
              .toSet();
          if (!otherPositions.contains(destination)) {
            finalPos = destination;
          }
        }
      }

      // Unstable tile crumbling
      if (gameState.grid.getTileType(startPos) == TileType.unstable) {
        gameState.grid.setTileType(startPos, TileType.crumbled);
        _tileComponents[startPos]?.type = TileType.crumbled;
      }

      cc.model.position = finalPos;
      cc.model.hasMoved = true;
      cc.syncWithModel();

      _updatePressurePlates();
      _onTurnCompletion();
    } else {
      cc.syncWithModel();
    }

    _draggedCharacter = null;
    _currentReachableTiles.clear();
    _updateHidingTiles();
    _updatePressurePlateActive();
  }

  void _onCharacterDoubleTap(CharacterComponent cc) {
    if (gameState.status != GameStatus.playing) return;
    if (cc.model.hasMoved) {
      return;
    }

    final startPos = cc.model.position;

    // Prevent waiting on an unstable tile
    if (gameState.grid.getTileType(startPos) == TileType.unstable) {
      return;
    }

    // Teleportation on Wait
    final stageData = _level.stages[_currentStageIndex];
    if (stageData.specialTiles[startPos] == TileType.teleport) {
      final destination = stageData.teleportLinks[startPos];
      if (destination != null) {
        final otherPositions = gameState.characters
            .where((c) => c.id != cc.model.id)
            .map((c) => c.position)
            .toSet();
        if (!otherPositions.contains(destination)) {
          cc.model.position = destination;
          cc.syncWithModel();
          _updatePressurePlates();
        }
      }
    }

    cc.model.hasMoved = true;
    cc.syncWithModel();
    _updateHidingTiles();
    _updatePressurePlateActive();
    _onTurnCompletion();
  }

  void _endTurnForAll() {
    if (gameState.status != GameStatus.playing) return;

    final unmovedComponents = _characterComponents
        .where((cc) => !cc.model.hasMoved)
        .toList();

    if (unmovedComponents.isEmpty) return;

    for (final cc in unmovedComponents) {
      final startPos = cc.model.position;

      // Skip characters on unstable tiles — they must move manually
      if (gameState.grid.getTileType(startPos) == TileType.unstable) {
        continue;
      }

      // Teleportation on Wait (mirrors _onCharacterDoubleTap logic)
      final stageData = _level.stages[_currentStageIndex];
      if (stageData.specialTiles[startPos] == TileType.teleport) {
        final destination = stageData.teleportLinks[startPos];
        if (destination != null) {
          final otherPositions = gameState.characters
              .where((c) => c.id != cc.model.id)
              .map((c) => c.position)
              .toSet();
          if (!otherPositions.contains(destination)) {
            cc.model.position = destination;
            cc.syncWithModel();
            _updatePressurePlates();
          }
        }
      }

      cc.model.hasMoved = true;
      cc.syncWithModel();
    }

    _updateHidingTiles();
    _updatePressurePlateActive();
    _onTurnCompletion();
  }

  void _onTurnCompletion() {
    gameState.updateStatus();

    final allMoved = gameState.characters.every((c) => c.hasMoved);

    if (allMoved) {
      _totalTurnCount++;
      _turnCounter?.text = _turnLabel;
      if (gameState.status == GameStatus.playing) {
        gameState.endTurn();
        _updatePressurePlates();
        gameState.updateStatus();
        for (final cc in _characterComponents) {
          cc.syncWithModel();
        }
        _clearEnemyVisionHighlights();
        for (final ec in _enemyComponents) {
          ec.animateToModel();
        }
        _updateEnemyVisionHighlights();
      }
    } else {
      _updateEnemyVisionHighlights();
    }

    if (gameState.status == GameStatus.won) {
      _transitionToNextStage();
    } else if (gameState.status == GameStatus.lost) {
      _showFailurePopup();
    }
  }

  // ── Transition Logic ──

  Future<void> _transitionToNextStage() async {
    // Determine the next stage within this level
    if (_currentStageIndex + 1 < _level.stages.length) {
      // More stages in this level
      _currentStageIndex++;
    } else {
      // All stages cleared — notify the shell.
      debugPrint('LEVEL CLEARED!');
      onLevelComplete?.call(_totalTurnCount);
      return;
    }

    final oldLevelView = _currentLevelView!;

    // Grab next stage dimensions BEFORE _initializeStage replaces gameState
    final nextStage = _level.stages[_currentStageIndex];
    final nextLastRow = nextStage.height - 1;

    // 1. Prepare next stage data
    _initializeStage();

    // 2. Create next stage view
    final nextLevelView = _createLevelView(gameState);

    // 3. Animate sliding — compute offset dynamically
    const duration = 1.5;
    const curve = Curves.easeInOutCubic;

    // The bottom-left of the next stage (offset col 0, last row)
    final qAtLastRow = 0 - (nextLastRow / 2).floor();
    final bottomPos =
        HexMath.gridToScreen(GridCoordinate(qAtLastRow, nextLastRow));
    final topPos = HexMath.gridToScreen(const GridCoordinate(0, 0));
    final offset = bottomPos - topPos;

    nextLevelView.position = oldLevelView.position - offset;
    world.add(nextLevelView);
    _currentLevelView = nextLevelView;

    // Temporary lock interaction
    final originalStatus = gameState.status;
    gameState.status = GameStatus.lost;

    // Animate the camera cleanly to the next stage
    final nextFit = _computeCameraFit(_currentStageIndex);
    camera.viewfinder.add(
      MoveToEffect(
        nextFit.position,
        EffectController(duration: duration, curve: curve),
      ),
    );
    camera.viewfinder.add(
      ScaleEffect.to(
        Vector2.all(nextFit.zoom),
        EffectController(duration: duration, curve: curve),
      ),
    );

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
          for (final cc in _characterComponents) {
            cc.syncWithModel();
          }

          gameState.status = originalStatus == GameStatus.won
              ? GameStatus.playing
              : originalStatus;
          _updateEnemyVisionHighlights();
          _fitCamera(); // Keep this as a final safety check/snap to ensure exactness natively
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

    _levelCounter.text = _stageLabel;
    _turnCounter?.text = _turnLabel;
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
    for (final entry in _currentReachableTiles.entries) {
      if (entry.value != Reachability.walkable) {
        continue;
      }

      final coord = entry.key;
      final tile = _tileComponents[coord];
      if (tile != null && tile.type == TileType.targetZone) {
        final indicator = GoalIndicatorComponent(
          tileCenter: HexMath.gridToScreen(coord),
        );
        _goalIndicators.add(indicator);
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

  // ── Failure / Reset ──

  void _showFailurePopup() {
    overlays.add('failure');
  }

  /// Resets the current stage to its initial state.
  void resetCurrentStage() {
    overlays.remove('failure');
    _totalTurnCount = _stageStartTurnCount;

    // Tear down old view
    _currentLevelView?.removeFromParent();
    for (final cc in _characterComponents) {
      cc.removeFromParent();
    }
    _characterComponents.clear();
    _tileComponents.clear();
    _enemyComponents.clear();
    _goalIndicators.clear();

    // Re-initialise the stage from scratch
    final stage = _level.stages[_currentStageIndex];
    final grid = stage.createGrid();

    // Restore characters to their saved starting positions
    final characters = _stageStartPositions.entries
        .map((e) => Character(id: e.key, position: e.value))
        .toList();

    gameState = GameState(
      grid: grid,
      characters: characters,
      enemies: stage.createEnemies(),
    );

    for (final enemy in gameState.enemies) {
      enemy.initializePath(grid);
    }

    // Rebuild with fresh view
    _buildInitialWorld();
    _updateHidingTiles();
    _updatePressurePlateActive();
    _levelCounter.text = _stageLabel;
    _turnCounter?.text = _turnLabel;
  }

  void _updatePressurePlates() {
    final stage = _level.stages[_currentStageIndex];
    if (stage.tileKeys.isEmpty) {
      return;
    }

    final activeKeys = <String>{};
    for (final char in gameState.characters) {
      if (stage.specialTiles[char.position] == TileType.pressurePlate) {
        final key = stage.tileKeys[char.position];
        if (key != null) {
          activeKeys.add(key);
        }
      }
    }
    for (final enemy in gameState.enemies) {
      if (stage.specialTiles[enemy.position] == TileType.pressurePlate) {
        final key = stage.tileKeys[enemy.position];
        if (key != null) {
          activeKeys.add(key);
        }
      }
    }

    for (final entry in stage.specialTiles.entries) {
      if (entry.value == TileType.pressureObstacle) {
        final coord = entry.key;
        final key = stage.tileKeys[coord];
        final isOpen = key != null && activeKeys.contains(key);

        gameState.grid.setTileType(
            coord, isOpen ? TileType.empty : TileType.pressureObstacle);

        final tileCompo = _tileComponents[coord];
        if (tileCompo != null) {
          tileCompo.isOpen = isOpen;
        }
      }
    }

    // Check for characters crushed by closing obstacles
    for (final char in gameState.characters) {
      final charTileType = stage.specialTiles[char.position];
      if (charTileType == TileType.pressureObstacle) {
        final key = stage.tileKeys[char.position];
        if (key != null && !activeKeys.contains(key)) {
          gameState.status = GameStatus.lost;
          gameState.statusMessage = 'A character was crushed!';
          _showFailurePopup();
          return;
        }
      }
    }

    _updateHidingTiles();
    _updatePressurePlateActive();
  }

  void _updateHidingTiles() {
    final stage = _level.stages[_currentStageIndex];
    final occupiedByCharacter =
        gameState.characters.map((c) => c.position).toSet();

    for (final entry in stage.specialTiles.entries) {
      if (entry.value == TileType.hiding) {
        final tile = _tileComponents[entry.key];
        if (tile != null) {
          tile.isOccupied = occupiedByCharacter.contains(entry.key);
        }
      }
    }
  }

  void _updatePressurePlateActive() {
    final stage = _level.stages[_currentStageIndex];
    final occupiedByCharacter =
        gameState.characters.map((c) => c.position).toSet();

    for (final entry in stage.specialTiles.entries) {
      if (entry.value == TileType.pressurePlate) {
        final tile = _tileComponents[entry.key];
        if (tile != null) {
          tile.isActive = occupiedByCharacter.contains(entry.key);
        }
      }
    }
  }
}
