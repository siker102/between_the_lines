import 'package:between_the_lines/model/grid/grid_coordinate.dart';

abstract class Entity {
  final String id;
  GridCoordinate position;

  Entity({required this.id, required this.position});
}
