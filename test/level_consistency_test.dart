import 'dart:convert';
import 'dart:io';

import 'package:between_the_lines/model/grid/grid_coordinate.dart';
import 'package:between_the_lines/model/level_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validates that consecutive stages within each level have
/// matching walkability at their shared boundary:
///   stage N goal zone (row 0) ↔ stage N+1 entry row (last row).
///
/// Stages may have different widths; only overlapping columns
/// are checked. Both wider and thinner following stages are handled.
void main() {
  group('Level/Stage boundary consistency', () {
    final levelDir = Directory('assets/levels');
    final levelFiles = levelDir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in levelFiles) {
      final levelName = file.uri.pathSegments.last;

      test('$levelName: consecutive stages have matching boundaries', () {
        final jsonString = file.readAsStringSync();
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final level = LevelData.fromJson(jsonMap);

        for (var i = 0; i < level.stages.length - 1; i++) {
          final stageA = level.stages[i];
          final stageB = level.stages[i + 1];

          final gridA = stageA.createGrid();
          final gridB = stageB.createGrid();

          // The shared column range is the overlap of both widths.
          final sharedCols = stageA.width < stageB.width ? stageA.width : stageB.width;

          final lastRowB = stageB.height - 1;

          for (var col = 0; col < sharedCols; col++) {
            // Row 0 axial: q = col - (0 / 2).floor() = col
            final coordA = _axial(col, 0);
            // Last row axial: q = col - (lastRowB / 2).floor()
            final coordB = _axial(col, lastRowB);

            final walkableA = gridA.isWalkable(coordA);
            final walkableB = gridB.isWalkable(coordB);

            expect(
              walkableA,
              walkableB,
              reason: 'Stage ${i + 1} → ${i + 2}: '
                  'column $col mismatch at boundary. '
                  'Stage ${i + 1} row 0 is ${walkableA ? "walkable" : "blocked"}, '
                  'but stage ${i + 2} row $lastRowB is ${walkableB ? "walkable" : "blocked"}.',
            );
          }
        }
      });
    }
  });
}

/// Converts offset (col, row) to axial GridCoordinate, matching
/// the convention used throughout the project.
GridCoordinate _axial(int col, int row) {
  return GridCoordinate(col - (row / 2).floor(), row);
}
