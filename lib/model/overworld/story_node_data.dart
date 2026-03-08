/// A story node on the overworld map.
///
/// Each node has a position on the map canvas and optionally references
/// a dialogue conversation by [dialogueId].
class StoryNodeData {
  final String id;
  final String label;
  final String description;
  final double x;
  final double y;
  final String? dialogueId;

  const StoryNodeData({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    this.description = '',
    this.dialogueId,
  });

  factory StoryNodeData.fromJson(Map<String, dynamic> json) {
    return StoryNodeData(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      dialogueId: json['dialogueId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (description.isNotEmpty) 'description': description,
        'x': x,
        'y': y,
        if (dialogueId != null) 'dialogueId': dialogueId,
      };
}
