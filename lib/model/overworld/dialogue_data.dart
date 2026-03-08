/// A single line of dialogue within a conversation.
class DialogueLine {
  final String speakerId;
  final String text;

  const DialogueLine({
    required this.speakerId,
    required this.text,
  });

  factory DialogueLine.fromJson(Map<String, dynamic> json) {
    return DialogueLine(
      speakerId: json['speakerId'] as String,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'speakerId': speakerId,
        'text': text,
      };
}

/// A full conversation sequence loaded from a separate JSON file.
///
/// Contains an ordered list of [DialogueLine]s from multiple characters.
class DialogueData {
  final String id;
  final List<DialogueLine> lines;

  const DialogueData({
    required this.id,
    required this.lines,
  });

  factory DialogueData.fromJson(Map<String, dynamic> json) {
    final lines = (json['lines'] as List)
        .map((l) => DialogueLine.fromJson(l as Map<String, dynamic>))
        .toList();

    return DialogueData(
      id: json['id'] as String,
      lines: lines,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}
