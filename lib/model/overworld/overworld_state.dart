import 'package:between_the_lines/model/overworld/chapter_data.dart';
import 'package:between_the_lines/model/overworld/dialogue_data.dart';
import 'package:between_the_lines/model/overworld/district_data.dart';
import 'package:between_the_lines/model/overworld/story_edge.dart';
import 'package:between_the_lines/model/overworld/story_node_data.dart';
import 'package:flutter/material.dart';

/// Tracks the player's progression through a district-based chapter.
///
/// The player moves through one district at a time. Within a district,
/// nodes are traversed in order. When a district is complete, the player
/// advances to the next district.
class OverworldState {
  final ChapterData chapter;
  final Map<String, DialogueData> dialogues;
  String currentNodeId;
  int currentDistrictIndex;
  final Set<String> completedNodeIds;
  final Set<String> completedEdgeIds;
  final Set<String> completedBossDistrictIds;

  /// Whether the character needs to animate from an edge mid-point to the current node.
  bool needsArrivalAnimation = false;

  /// The edge that was just completed, if we are animating an arrival.
  String? lastCompletedEdgeId;

  /// Whether the player is currently animating onto the screen for a new district.
  bool isTransitioningIn = false;

  /// The direction of the last transition out of a district. Used to enter from the opposite side.
  Offset? lastTransitionDirection;

  OverworldState({
    required this.chapter,
    required this.dialogues,
    String? startNodeId,
    int? startDistrictIndex,
  })  : currentNodeId = startNodeId ?? chapter.startNodeId,
        currentDistrictIndex = startDistrictIndex ?? 0,
        completedNodeIds = {},
        completedEdgeIds = {},
        completedBossDistrictIds = {};

  /// The current story node the player is on.
  StoryNodeData get currentNode => chapter.getNode(currentNodeId)!;

  /// The district currently being displayed.
  DistrictData get currentDistrict => chapter.getDistrictAt(currentDistrictIndex);

  /// Whether a district is fully complete (all edges cleared).
  bool isDistrictComplete(DistrictData district) {
    return district.edgeIds.every(completedEdgeIds.contains);
  }

  /// Whether we are on the last node of the current district
  /// (no more edges to traverse in this district).
  bool get isAtDistrictEnd {
    final district = currentDistrict;
    return district.nodeIds.last == currentNodeId;
  }

  /// Whether the player has reached the end of the district and needs to complete a boss level
  /// before proceeding to the next district.
  bool get needsBossLevel {
    if (!isAtDistrictEnd || !isDistrictComplete(currentDistrict)) return false;
    final district = currentDistrict;
    if (district.bossLevelAssetPath == null) return false;
    return !completedBossDistrictIds.contains(district.id);
  }

  /// Whether the player has completed the district (and its boss) and is ready to travel
  /// along an out-of-screen transition edge to the next district.
  bool get isTransitioningOut {
    if (!isAtDistrictEnd || !isDistrictComplete(currentDistrict)) return false;
    if (needsBossLevel) return false;
    return currentDistrictIndex < chapter.districts.length - 1;
  }

  /// Whether all districts are complete.
  bool get isGameComplete {
    return currentDistrictIndex >= chapter.districts.length - 1 &&
        isAtDistrictEnd &&
        isDistrictComplete(currentDistrict);
  }

  /// The next available edge from the current node within
  /// the current district. Returns `null` if none available.
  StoryEdge? get nextEdge {
    final district = currentDistrict;
    for (final edgeId in district.edgeIds) {
      if (completedEdgeIds.contains(edgeId)) {
        continue;
      }
      final edge = chapter.getEdge(edgeId);
      if (edge != null && edge.fromNodeId == currentNodeId) {
        return edge;
      }
    }
    return null;
  }

  /// Looks up a loaded dialogue by its ID.
  DialogueData? getDialogue(String? id) {
    if (id == null) {
      return null;
    }
    return dialogues[id];
  }

  /// Marks the current node as completed.
  void completeCurrentNode() {
    completedNodeIds.add(currentNodeId);
  }

  /// Marks an edge as completed and advances to its destination.
  ///
  /// If the destination is the last node in the current district,
  /// auto-advances to the next district when all edges are done.
  void completeEdge(String edgeId) {
    final edge = chapter.edges.firstWhere((e) => e.id == edgeId);
    completedEdgeIds.add(edgeId);
    currentNodeId = edge.toNodeId;
    lastCompletedEdgeId = edgeId;
    needsArrivalAnimation = true;
  }

  /// Advance to the next district. Called when a district is fully
  /// complete and the player triggers progression.
  bool advanceToNextDistrict() {
    if (currentDistrictIndex + 1 < chapter.districts.length) {
      currentDistrictIndex++;
      final nextDistrict = currentDistrict;
      currentNodeId = nextDistrict.nodeIds.first;
      return true;
    }
    return false;
  }

  /// Marks the boss of the current district as complete.
  void completeBossLevel() {
    completedBossDistrictIds.add(currentDistrict.id);
  }
}
