import 'package:between_the_lines/model/overworld/story_node_data.dart' show StoryNodeData;

/// An edge connecting two [StoryNodeData]s on the overworld graph.
///
/// Each edge references a level JSON asset that the player must complete
/// to traverse from [fromNodeId] to [toNodeId].
class StoryEdge {
  final String id;
  final String name;
  final String fromNodeId;
  final String toNodeId;
  final String levelAssetPath;

  const StoryEdge({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    required this.levelAssetPath,
    this.name = '',
  });

  factory StoryEdge.fromJson(Map<String, dynamic> json) {
    return StoryEdge(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      fromNodeId: json['fromNodeId'] as String,
      toNodeId: json['toNodeId'] as String,
      levelAssetPath: json['levelAssetPath'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (name.isNotEmpty) 'name': name,
        'fromNodeId': fromNodeId,
        'toNodeId': toNodeId,
        'levelAssetPath': levelAssetPath,
      };
}
