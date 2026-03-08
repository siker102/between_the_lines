import 'package:flutter/material.dart';

/// A district within a chapter — a linear sequence of story nodes.
///
/// Districts group nodes into themed areas that are displayed one at a time
/// on the overworld screen. Nodes within a district are traversed in order.
class DistrictData {
  final String id;
  final String name;
  final String subtitle;
  final int tier;
  final List<String> nodeIds;
  final List<String> edgeIds;
  final String? bossLevelAssetPath;
  final Offset? transitionDirection;

  const DistrictData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.tier,
    required this.nodeIds,
    required this.edgeIds,
    this.bossLevelAssetPath,
    this.transitionDirection,
  });

  factory DistrictData.fromJson(Map<String, dynamic> json) {
    Offset? transitionDirection;
    if (json['transitionDirection'] != null) {
      final arr = json['transitionDirection'] as List;
      if (arr.length == 2) {
        transitionDirection = Offset(
          (arr[0] as num).toDouble(),
          (arr[1] as num).toDouble(),
        );
      }
    }

    return DistrictData(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      tier: json['tier'] as int,
      nodeIds: (json['nodeIds'] as List).cast<String>(),
      edgeIds: (json['edgeIds'] as List).cast<String>(),
      bossLevelAssetPath: json['bossLevelAssetPath'] as String?,
      transitionDirection: transitionDirection,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'tier': tier,
        'nodeIds': nodeIds,
        'edgeIds': edgeIds,
        'bossLevelAssetPath': bossLevelAssetPath,
        'transitionDirection': transitionDirection != null ? [transitionDirection!.dx, transitionDirection!.dy] : null,
      };
}
