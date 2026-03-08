import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/grid/hex_grid.dart';
import 'package:between_the_lines/model/level_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StageData.fromJson', () {
    test('parses width and height', () {
      final json = {
        'width': 6,
        'height': 13,
        'blockedTiles': <List<int>>[],
        'enemies': <Map<String, dynamic>>[],
      };

      final stage = StageData.fromJson(json);

      expect(stage.width, 6);
      expect(stage.height, 13);
    });

    test('converts blockedTiles from [col, row] to axial GridCoordinate', () {
      final json = {
        'width': 6,
        'height': 13,
        'blockedTiles': [
          [0, 4],
          [3, 7],
        ],
        'enemies': <Map<String, dynamic>>[],
      };

      final stage = StageData.fromJson(json);

      // col 0, row 4 → q = 0 - floor(4/2) = -2
      expect(stage.specialTiles[const GridCoordinate(-2, 4)], TileType.blocked);

      // col 3, row 7 → q = 3 - floor(7/2) = 3 - 3 = 0
      expect(stage.specialTiles[const GridCoordinate(0, 7)], TileType.blocked);
    });

    test('parses enemies with correct positions and patrol paths', () {
      final json = {
        'width': 6,
        'height': 13,
        'blockedTiles': <List<int>>[],
        'enemies': [
          {
            'id': 'e1',
            'position': [2, 6],
            'patrolPath': [
              [2, 6],
              [5, 6],
            ],
            'visionRange': 3,
            'enemyType': 'radial',
          },
        ],
      };

      final stage = StageData.fromJson(json);

      expect(stage.enemies.length, 1);
      final enemy = stage.enemies.first;
      expect(enemy.id, 'e1');
      expect(enemy.visionRange, 3);

      // position: col 2, row 6 → q = 2 - floor(6/2) = 2 - 3 = -1
      expect(enemy.position, const GridCoordinate(-1, 6));

      // patrol waypoint 0: same as position
      expect(enemy.patrolPath[0], const GridCoordinate(-1, 6));
      // patrol waypoint 1: col 5, row 6 → q = 5 - 3 = 2
      expect(enemy.patrolPath[1], const GridCoordinate(2, 6));
    });

    test('enemyType defaults to directional', () {
      final json = {
        'width': 4,
        'height': 4,
        'enemies': [
          {
            'id': 'e1',
            'position': [0, 0],
            'patrolPath': <List<int>>[],
          },
        ],
      };

      final stage = StageData.fromJson(json);

      expect(stage.enemies.first.enemyType.name, 'directional');
    });
  });

  group('StageData.createGrid', () {
    test('creates grid with correct dimensions and target zones at row 0', () {
      final stage = StageData(width: 4, height: 5);
      final grid = stage.createGrid();

      expect(grid.width, 4);
      expect(grid.height, 5);

      // Row 0 should all be target zones
      for (var c = 0; c < 4; c++) {
        final q = c - (0 / 2).floor();
        expect(grid.getTileType(GridCoordinate(q, 0)), TileType.targetZone);
      }
    });

    test('applies blocked tiles', () {
      final stage = StageData(
        width: 4,
        height: 5,
        specialTiles: {
          const GridCoordinate(1, 2): TileType.blocked,
        },
      );
      final grid = stage.createGrid();

      expect(grid.getTileType(const GridCoordinate(1, 2)), TileType.blocked);
    });
  });

  group('LevelData.fromJson', () {
    test('parses name and stages', () {
      final json = {
        'name': 'Test Level',
        'stages': [
          {
            'width': 4,
            'height': 4,
            'blockedTiles': <List<int>>[],
            'enemies': <Map<String, dynamic>>[],
          },
          {
            'width': 6,
            'height': 8,
            'blockedTiles': <List<int>>[],
            'enemies': <Map<String, dynamic>>[],
          },
        ],
      };

      final level = LevelData.fromJson(json);

      expect(level.name, 'Test Level');
      expect(level.stages.length, 2);
      expect(level.stages[0].width, 4);
      expect(level.stages[1].width, 6);
    });
  });
}
