import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';

/// Describes a single stage within a level: grid dimensions, obstacles, and enemies.
class StageData {
  final int width;
  final int height;
  final Map<GridCoordinate, TileType> specialTiles;
  final List<Enemy> enemies;

  StageData({
    required this.width,
    required this.height,
    this.specialTiles = const {},
    this.enemies = const [],
  });

  /// Deserialises a stage from a JSON map.
  ///
  /// Expected shape:
  /// ```json
  /// {
  ///   "width": 6,
  ///   "height": 13,
  ///   "blockedTiles": [[col, row], ...],
  ///   "enemies": [ { "id": "...", "position": [col, row], ... } ]
  /// }
  /// ```
  factory StageData.fromJson(Map<String, dynamic> json) {
    final width = json['width'] as int;
    final height = json['height'] as int;

    // Parse blocked tiles (offset [col, row] → axial GridCoordinate)
    final specialTiles = <GridCoordinate, TileType>{};
    if (json['blockedTiles'] != null) {
      for (final tile in json['blockedTiles'] as List) {
        final pair = tile as List;
        final col = pair[0] as int;
        final row = pair[1] as int;
        final q = col - (row / 2).floor();
        specialTiles[GridCoordinate(q, row)] = TileType.blocked;
      }
    }

    // Parse enemies
    final enemies = <Enemy>[];
    if (json['enemies'] != null) {
      for (final e in json['enemies'] as List) {
        enemies.add(_enemyFromJson(e as Map<String, dynamic>));
      }
    }

    return StageData(
      width: width,
      height: height,
      specialTiles: specialTiles,
      enemies: enemies,
    );
  }

  /// Returns fresh clones of this stage's enemy templates.
  List<Enemy> createEnemies() => enemies.map((e) => e.clone()).toList();

  /// Creates a [HexGrid] from this stage's data, including target zones at row 0.
  HexGrid createGrid() {
    final grid = HexGrid.rectangle(width, height);

    // Set target zones at the very top (row 0)
    for (var c = 0; c < width; c++) {
      final q = c - (0 / 2).floor();
      grid.setTileType(GridCoordinate(q, 0), TileType.targetZone);
    }

    specialTiles.forEach(grid.setTileType);

    return grid;
  }

  static Enemy _enemyFromJson(Map<String, dynamic> json) {
    final pos = json['position'] as List;
    final posCol = pos[0] as int;
    final posRow = pos[1] as int;

    final patrolPath = <GridCoordinate>[];
    for (final wp in json['patrolPath'] as List) {
      final pair = wp as List;
      final c = pair[0] as int;
      final r = pair[1] as int;
      patrolPath.add(GridCoordinate(c - (r / 2).floor(), r));
    }

    final typeStr = json['enemyType'] as String? ?? 'directional';
    final enemyType = EnemyType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => EnemyType.directional,
    );

    return Enemy(
      id: json['id'] as String,
      position: GridCoordinate(posCol - (posRow / 2).floor(), posRow),
      patrolPath: patrolPath,
      visionRange: json['visionRange'] as int? ?? 4,
      enemyType: enemyType,
    );
  }
}

/// A level is a named collection of stages.
class LevelData {
  final String name;
  final List<StageData> stages;

  LevelData({required this.name, required this.stages});

  factory LevelData.fromJson(Map<String, dynamic> json) {
    final stages = (json['stages'] as List).map((s) => StageData.fromJson(s as Map<String, dynamic>)).toList();

    return LevelData(
      name: json['name'] as String,
      stages: stages,
    );
  }
}
