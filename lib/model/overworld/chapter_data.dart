import 'package:between_the_lines/model/overworld/character_profile.dart';
import 'package:between_the_lines/model/overworld/district_data.dart';
import 'package:between_the_lines/model/overworld/story_edge.dart';
import 'package:between_the_lines/model/overworld/story_node_data.dart';

/// A chapter containing districts, each with a linear sequence of nodes.
///
/// Also carries a registry of [CharacterProfile]s, mapping character IDs
/// to their display names and image assets.
class ChapterData {
  final String id;
  final String title;
  final int chapterNumber;
  final List<DistrictData> districts;
  final List<StoryNodeData> nodes;
  final List<StoryEdge> edges;
  final String startNodeId;
  final Map<String, CharacterProfile> characters;

  const ChapterData({
    required this.id,
    required this.title,
    required this.chapterNumber,
    required this.districts,
    required this.nodes,
    required this.edges,
    required this.startNodeId,
    required this.characters,
  });

  factory ChapterData.fromJson(Map<String, dynamic> json) {
    final nodes = (json['nodes'] as List)
        .map(
          (n) => StoryNodeData.fromJson(n as Map<String, dynamic>),
        )
        .toList();

    final edges = (json['edges'] as List)
        .map(
          (e) => StoryEdge.fromJson(e as Map<String, dynamic>),
        )
        .toList();

    final districts = (json['districts'] as List?)
            ?.map(
              (d) => DistrictData.fromJson(
                Map<String, dynamic>.from(d as Map),
              ),
            )
            .toList() ??
        [];

    final characters = <String, CharacterProfile>{};
    if (json['characters'] != null) {
      final charMap = Map<String, dynamic>.from(
        json['characters'] as Map,
      );
      for (final entry in charMap.entries) {
        characters[entry.key] = CharacterProfile.fromJson(
          entry.key,
          entry.value as Map<String, dynamic>,
        );
      }
    }

    return ChapterData(
      id: json['id'] as String,
      title: json['title'] as String,
      chapterNumber: json['chapterNumber'] as int,
      districts: districts,
      nodes: nodes,
      edges: edges,
      startNodeId: json['startNodeId'] as String,
      characters: characters,
    );
  }

  /// Looks up a node by its [id]. Returns `null` if not found.
  StoryNodeData? getNode(String id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  /// Looks up an edge by its [id]. Returns `null` if not found.
  StoryEdge? getEdge(String id) {
    for (final edge in edges) {
      if (edge.id == id) {
        return edge;
      }
    }
    return null;
  }

  /// Returns all edges originating from the given [nodeId].
  List<StoryEdge> edgesFrom(String nodeId) {
    return edges.where((e) => e.fromNodeId == nodeId).toList();
  }

  /// Returns the district that contains [nodeId], or `null`.
  DistrictData? getDistrictForNode(String nodeId) {
    for (final district in districts) {
      if (district.nodeIds.contains(nodeId)) {
        return district;
      }
    }
    return null;
  }

  /// Returns the district at the given [index].
  DistrictData getDistrictAt(int index) => districts[index];
}
