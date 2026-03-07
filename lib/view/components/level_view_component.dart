import 'package:between_the_lines/view/components/enemy_component.dart';
import 'package:between_the_lines/view/components/hex_tile.dart';
import 'package:between_the_lines/view/components/patrol_path_component.dart';
import 'package:flame/components.dart';

class LevelViewComponent extends PositionComponent {
  final List<HexTile> tiles;
  final List<EnemyComponent> enemies;
  final List<PatrolPathComponent> patrolPaths;

  LevelViewComponent({
    required this.tiles,
    required this.enemies,
    required this.patrolPaths,
  }) : super() {
    addAll(tiles);
    addAll(patrolPaths);
    addAll(enemies);
  }
}
