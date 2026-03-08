import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';

/// Describes a single stage within a level: grid dimensions, obstacles, and enemies.
class StageData {
  final int width;
  final int height;
  final Map<GridCoordinate, TileType> specialTiles;
  final Map<GridCoordinate, String> tileKeys;
  final Map<GridCoordinate, GridCoordinate> teleportLinks;
  final List<Enemy> enemies;

  StageData({
    required this.width,
    required this.height,
    this.specialTiles = const {},
    this.tileKeys = const {},
    this.teleportLinks = const {},
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

    // Parse special tiles (offset [col, row] → axial GridCoordinate)
    final specialTiles = <GridCoordinate, TileType>{};
    final tileKeys = <GridCoordinate, String>{};
    final teleportLinks = <GridCoordinate, GridCoordinate>{};

    GridCoordinate parseCoord(List pair) {
      final col = pair[0] as int;
      final row = pair[1] as int;
      return GridCoordinate(col - (row / 2).floor(), row);
    }

    if (json['blockedTiles'] != null) {
      for (final tile in json['blockedTiles'] as List) {
        specialTiles[parseCoord(tile as List)] = TileType.blocked;
      }
    }

    if (json['hidingTiles'] != null) {
      for (final tile in json['hidingTiles'] as List) {
        specialTiles[parseCoord(tile as List)] = TileType.hiding;
      }
    }

    if (json['unstableTiles'] != null) {
      for (final tile in json['unstableTiles'] as List) {
        specialTiles[parseCoord(tile as List)] = TileType.unstable;
      }
    }

    if (json['pressurePlates'] != null) {
      for (final plateData in json['pressurePlates'] as List) {
        final map = plateData as Map<String, dynamic>;
        final coord = parseCoord(map['position'] as List);
        specialTiles[coord] = TileType.pressurePlate;
        tileKeys[coord] = map['key'] as String;
      }
    }

    if (json['pressureObstacles'] != null) {
      for (final obstacleData in json['pressureObstacles'] as List) {
        final map = obstacleData as Map<String, dynamic>;
        final coord = parseCoord(map['position'] as List);
        specialTiles[coord] = TileType.pressureObstacle;
        tileKeys[coord] = map['key'] as String;
      }
    }

    if (json['teleports'] != null) {
      for (final tpData in json['teleports'] as List) {
        final map = tpData as Map<String, dynamic>;
        final from = parseCoord(map['from'] as List);
        final to = parseCoord(map['to'] as List);

        // Make teleport bi-directional
        specialTiles[from] = TileType.teleport;
        teleportLinks[from] = to;

        specialTiles[to] = TileType.teleport;
        teleportLinks[to] = from;
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
      tileKeys: tileKeys,
      teleportLinks: teleportLinks,
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
