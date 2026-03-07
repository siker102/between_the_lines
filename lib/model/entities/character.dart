import 'package:between_the_lines/model/entities/entity.dart';

class Character extends Entity {
  final int moveRange;
  bool hasMoved = false;

  Character({
    required super.id,
    required super.position,
    this.moveRange = 2, // Reduced from 3
  });
}
