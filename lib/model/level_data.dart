import 'package:between_the_lines/model/entities/enemy.dart';
import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';

class LevelData {
  final int width;
  final int height;
  final Map<GridCoordinate, TileType> specialTiles;
  final List<Enemy> enemies;

  LevelData({
    required this.width,
    required this.height,
    this.specialTiles = const {},
    this.enemies = const [],
  });

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
}

final List<LevelData> levelsRepository = [
  // Level 1
  LevelData(
    width: 6,
    height: 13,
    specialTiles: {
      GridCoordinate(0 - (4 / 2).floor(), 4): TileType.blocked,
      GridCoordinate(1 - (4 / 2).floor(), 4): TileType.blocked,
      GridCoordinate(4 - (4 / 2).floor(), 4): TileType.blocked,
      GridCoordinate(5 - (4 / 2).floor(), 4): TileType.blocked,
      GridCoordinate(2 - (7 / 2).floor(), 7): TileType.blocked,
      GridCoordinate(3 - (7 / 2).floor(), 7): TileType.blocked,
    },
    enemies: [
      Enemy(
        id: 'e1_l1',
        position: GridCoordinate(0 - (6 / 2).floor(), 6),
        patrolPath: [
          GridCoordinate(0 - (6 / 2).floor(), 6),
          GridCoordinate(5 - (6 / 2).floor(), 6),
        ],
        visionRange: 3,
      ),
      Enemy(
        id: 'e2_l1',
        position: GridCoordinate(5 - (3 / 2).floor(), 3),
        patrolPath: [
          GridCoordinate(5 - (3 / 2).floor(), 3),
          GridCoordinate(0 - (3 / 2).floor(), 3),
        ],
        enemyType: EnemyType.linear,
      ),
      Enemy(
        id: 'e3_l1',
        position: GridCoordinate(2 - (9 / 2).floor(), 9),
        patrolPath: [
          GridCoordinate(2 - (9 / 2).floor(), 9),
          GridCoordinate(3 - (9 / 2).floor(), 9),
        ],
        visionRange: 2,
        enemyType: EnemyType.radial,
      ),
    ],
  ),
  // Level 2
  LevelData(
    width: 6,
    height: 13,
    specialTiles: {
      GridCoordinate(1 - (3 / 2).floor(), 3): TileType.blocked,
      GridCoordinate(2 - (3 / 2).floor(), 3): TileType.blocked,
      GridCoordinate(3 - (3 / 2).floor(), 3): TileType.blocked,
      GridCoordinate(4 - (3 / 2).floor(), 3): TileType.blocked,
      GridCoordinate(0 - (8 / 2).floor(), 8): TileType.blocked,
      GridCoordinate(5 - (8 / 2).floor(), 8): TileType.blocked,
    },
    enemies: [
      Enemy(
        id: 'e1_l2',
        position: GridCoordinate(1 - (5 / 2).floor(), 5),
        patrolPath: [
          GridCoordinate(1 - (5 / 2).floor(), 5),
          GridCoordinate(4 - (5 / 2).floor(), 5),
        ],
        visionRange: 3,
      ),
    ],
  ),
];
