/// Maps a character ID to their display name and full-body image asset.
///
/// Defined in the chapter JSON under the `"characters"` map.
class CharacterProfile {
  final String id;
  final String displayName;
  final String fullBodyAsset;

  const CharacterProfile({
    required this.id,
    required this.displayName,
    required this.fullBodyAsset,
  });

  factory CharacterProfile.fromJson(String id, Map<String, dynamic> json) {
    return CharacterProfile(
      id: id,
      displayName: json['displayName'] as String,
      fullBodyAsset: json['fullBodyAsset'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'fullBodyAsset': fullBodyAsset,
      };
}
