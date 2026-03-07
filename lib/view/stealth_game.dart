import 'package:between_the_lines/model/entities/character.dart';
import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/game_state.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:between_the_lines/model/systems/movement_calculator.dart';
import 'package:between_the_lines/model/systems/vision_calculator.dart';
import 'package:between_the_lines/view/components/character_component.dart';
import 'package:between_the_lines/view/components/enemy_component.dart';
import 'package:between_the_lines/view/components/goal_indicator_component.dart';
import 'package:between_the_lines/view/components/hex_tile.dart';
import 'package:between_the_lines/view/components/patrol_path_component.dart';
import 'package:between_the_lines/view/utils/hex_math.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class StealthGame extends FlameGame {
  late GameState gameState;

  // Component references
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
    _initializeMockLevel();
    _buildWorld();
  }

  // ── Level Setup ──

  void _initializeMockLevel() {
    // 6 columns, 12 rows for a vertical feel
    final grid = HexGrid.rectangle(6, 12);

    // Target zones at the VERY TOP (row 0)
    for (var c = 0; c < 6; c++) {
      final q = c - (0 / 2).floor();
      grid.setTileType(GridCoordinate(q, 0), TileType.targetZone);
    }

    // Obstacles creating corridors in the middle
    grid.setTileType(GridCoordinate(0 - (4 / 2).floor(), 4), TileType.blocked);
    grid.setTileType(GridCoordinate(1 - (4 / 2).floor(), 4), TileType.blocked);
    grid.setTileType(GridCoordinate(4 - (4 / 2).floor(), 4), TileType.blocked);
    grid.setTileType(GridCoordinate(5 - (4 / 2).floor(), 4), TileType.blocked);

    grid.setTileType(GridCoordinate(2 - (7 / 2).floor(), 7), TileType.blocked);
    grid.setTileType(GridCoordinate(3 - (7 / 2).floor(), 7), TileType.blocked);

    // Player characters at the BOTTOM (row 11)
    final c1 = Character(
      id: 'c1',
      position: GridCoordinate(2 - (11 / 2).floor(), 11),
    );
    final c2 = Character(
      id: 'c2',
      position: GridCoordinate(3 - (11 / 2).floor(), 11),
    );

    // Enemies in the middle
    final e1 = Enemy(
      id: 'e1',
      position: GridCoordinate(0 - (6 / 2).floor(), 6),
      patrolPath: [
        GridCoordinate(0 - (6 / 2).floor(), 6),
        GridCoordinate(5 - (6 / 2).floor(), 6),
      ],
      visionRange: 3,
    );
    final e2 = Enemy(
      id: 'e2',
      position: GridCoordinate(5 - (3 / 2).floor(), 3),
      patrolPath: [
        GridCoordinate(5 - (3 / 2).floor(), 3),
        GridCoordinate(0 - (3 / 2).floor(), 3),
      ],
      enemyType: EnemyType.linear,
    );
    final e3 = Enemy(
      id: 'e3',
      position: GridCoordinate(2 - (9 / 2).floor(), 9),
      patrolPath: [
        GridCoordinate(2 - (9 / 2).floor(), 9),
        GridCoordinate(3 - (9 / 2).floor(), 9),
      ],
      visionRange: 2,
      enemyType: EnemyType.radial,
    );

    gameState = GameState(
      grid: grid,
      characters: [c1, c2], // Added second character
      enemies: [e1, e2, e3],
    );

    // Compute tile-by-tile patrol routes
    for (final enemy in gameState.enemies) {
      enemy.initializePath(grid);
    }
  }

  // Shadow old logic till next method
  /*
  void _oldInitialize() {

    // Target zones at the TOP (negative r = top in pointy-top hex)
    grid.setTileType(
      const GridCoordinate(0, -4),
      TileType.targetZone,
    );
    grid.setTileType(
      const GridCoordinate(1, -4),
      TileType.targetZone,
    );
    grid.setTileType(
      const GridCoordinate(-1, -3),
      TileType.targetZone,
    );

    // Obstacles in the middle creating corridors
    grid.setTileType(
      const GridCoordinate(-2, 0),
      TileType.blocked,
    );
    grid.setTileType(
      const GridCoordinate(2, -1),
      TileType.blocked,
    );
    grid.setTileType(
      const GridCoordinate(0, -1),
      TileType.blocked,
    );

    // Player starts at the BOTTOM (positive r)
    final c1 = Character(
      id: 'c1',
      position: const GridCoordinate(0, 3),
    );

    // Enemies patrol across the middle
    final e1 = Enemy(
      id: 'e1',
      position: const GridCoordinate(-2, 1),
      patrolPath: [
        const GridCoordinate(-2, 1),
        const GridCoordinate(2, -1),
      ],
      visionRange: 3,
    );
    final e2 = Enemy(
      id: 'e2',
      position: const GridCoordinate(2, 0),
      patrolPath: [
        const GridCoordinate(2, 0),
        const GridCoordinate(-2, 2),
      ],
      facing: Direction.left,
      enemyType: EnemyType.linear,
    );
    final e3 = Enemy(
      id: 'e3',
      position: const GridCoordinate(0, -2),
      patrolPath: [
        const GridCoordinate(0, -2),
        const GridCoordinate(1, -2),
      ],
      visionRange: 2,
      enemyType: EnemyType.radial,
    );

  */

  // ── World Construction ──

  Future<void> _buildWorld() async {
    // 1. Add hex tiles in a rectangular grid
    final w = gameState.grid.width;
    final h = gameState.grid.height;

    // Bounds for camera centering
    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;

    for (var r = 0; r < h; r++) {
      for (var c = 0; c < w; c++) {
        final q = c - (r / 2).floor();
        final coord = GridCoordinate(q, r);
        final type = gameState.grid.getTileType(coord);

        final tile = HexTile(
          coordinate: coord,
          type: type,
        );
        _tileComponents[coord] = tile;
        world.add(tile);

        // Update bounds for camera
        final screenPos = HexMath.gridToScreen(coord);
        if (screenPos.x < minX) {
          minX = screenPos.x;
        }
        if (screenPos.x > maxX) {
          maxX = screenPos.x;
        }
        if (screenPos.y < minY) {
          minY = screenPos.y;
        }
        if (screenPos.y > maxY) {
          maxY = screenPos.y;
        }
      }
    }

    // 2. Add patrol path arrows (ON TOP of tiles)
    for (final enemy in gameState.enemies) {
      final patrol = PatrolPathComponent(
        enemy: enemy,
      );
      world.add(patrol);
    }

    // 3. Add enemies
    for (final enemy in gameState.enemies) {
      final ec = EnemyComponent(model: enemy);
      _enemyComponents.add(ec);
      world.add(ec);
    }

    // 4. Add characters
    for (final char in gameState.characters) {
      final cc = CharacterComponent(
        model: char,
        onDragStartCallback: _onCharacterDragStart,
        onDragUpdateCallback: _onCharacterDragUpdate,
        onDragEndCallback: _onCharacterDragEnd,
      );
      _characterComponents.add(cc);
      world.add(cc);
    }

    // Initial highlights
    _updateEnemyVisionHighlights();

    // 5. Fit camera to map
    // Add some padding
    const padding = 64.0;
    final mapWidth = (maxX - minX) + padding * 2;
    final mapHeight = (maxY - minY) + padding * 2;

    // Center camera on the map
    camera.viewfinder.position = Vector2((minX + maxX) / 2, (minY + maxY) / 2);

    // Calculate zoom to fill screen (canvasSize might not be ready in onLoad,
    // but building world happens after. However, better to use a ResizeEffect or update later)
    // For now, let's just set a reasonable zoom or try to use canvasSize if available
    if (size.x > 0 && size.y > 0) {
      final zoomX = size.x / mapWidth;
      final zoomY = size.y / mapHeight;
      camera.viewfinder.zoom = zoomX < zoomY ? zoomX : zoomY;
    }
  }

  // ── Interaction Logic ──

  void _onCharacterDragStart(CharacterComponent cc) {
    if (gameState.status != GameStatus.playing) {
      return;
    }

    _draggedCharacter = cc;

    // Calculate reachable tiles
    _currentReachableTiles = MovementCalculator.calculateReachableTiles(
      gameState.grid,
      cc.model,
    );

    // Highlight reachable tiles (blue)
    for (final coord in _currentReachableTiles) {
      _tileComponents[coord]?.highlightColors.add(Colors.blue);
    }

    // Spawn "!" on reachable goal tiles
    _spawnGoalIndicators();
  }

  void _onCharacterDragUpdate(CharacterComponent cc) {
    // Visual drag handled in CharacterComponent
  }

  void _onCharacterDragEnd(CharacterComponent cc) {
    if (_draggedCharacter == null) {
      return;
    }

    final dropPos = HexMath.screenToGrid(cc.position);

    // Clear blue highlights
    for (final coord in _currentReachableTiles) {
      _tileComponents[coord]?.highlightColors.remove(
            Colors.blue,
          );
    }

    // Remove goal indicators
    _removeGoalIndicators();

    // Turn skip: only consume turn if actually moved
    final didMove = _currentReachableTiles.contains(dropPos) && dropPos != cc.model.position;

    if (didMove) {
      // Valid move! Update model
      cc.model.position = dropPos;
      cc.model.hasMoved = true; // Mark as moved
      cc.syncWithModel();

      // Check if ALL characters have moved
      final allMoved = gameState.characters.every((c) => c.hasMoved);

      if (allMoved) {
        // End turn → enemies move
        gameState.endTurn();

        // Animate enemies to new positions
        _clearEnemyVisionHighlights();
        for (final ec in _enemyComponents) {
          ec.animateToModel();
        }
        _updateEnemyVisionHighlights();
      } else {
        // Just update vision highlights showing current status
        _updateEnemyVisionHighlights();
      }

      if (gameState.status != GameStatus.playing) {
        debugPrint(
          'GAME OVER: ${gameState.statusMessage}',
        );
      }
    } else {
      // No move or invalid → snap back
      cc.syncWithModel();
    }

    _draggedCharacter = null;
    _currentReachableTiles.clear();
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
      final vision = VisionCalculator.calculateVision(
        gameState.grid,
        enemy,
      );
      for (final coord in vision) {
        _tileComponents[coord]?.highlightColors.add(
              Colors.red,
            );
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
        world.add(indicator);
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
