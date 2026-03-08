import 'package:between_the_lines/model/overworld/chapter_data.dart';
import 'package:between_the_lines/model/overworld/character_profile.dart';
import 'package:between_the_lines/model/overworld/dialogue_data.dart';
import 'package:between_the_lines/model/overworld/district_data.dart';
import 'package:between_the_lines/model/overworld/overworld_state.dart';
import 'package:between_the_lines/model/overworld/story_edge.dart';
import 'package:between_the_lines/model/overworld/story_node_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CharacterProfile', () {
    test('fromJson parses correctly', () {
      final profile = CharacterProfile.fromJson('c1', {
        'displayName': 'Alex',
        'fullBodyAsset': 'assets/images/character1.png',
      });
      expect(profile.id, 'c1');
      expect(profile.displayName, 'Alex');
      expect(profile.fullBodyAsset, 'assets/images/character1.png');
    });

    test('fromJson handles empty fullBodyAsset', () {
      final profile = CharacterProfile.fromJson('narrator', {
        'displayName': '???',
      });
      expect(profile.fullBodyAsset, '');
    });
  });

  group('DialogueData', () {
    test('fromJson parses multi-character conversation', () {
      final data = DialogueData.fromJson({
        'id': 'dlg_test',
        'lines': [
          {'speakerId': 'c1', 'text': 'Hello'},
          {'speakerId': 'c2', 'text': 'Hi there'},
          {'speakerId': 'c1', 'text': 'How are you?'},
        ],
      });
      expect(data.id, 'dlg_test');
      expect(data.lines, hasLength(3));
      expect(data.lines[0].speakerId, 'c1');
      expect(data.lines[1].speakerId, 'c2');
    });

    test('toJson round-trips correctly', () {
      const original = DialogueData(
        id: 'dlg_rt',
        lines: [
          DialogueLine(speakerId: 'a', text: 'x'),
          DialogueLine(speakerId: 'b', text: 'y'),
        ],
      );
      final json = original.toJson();
      final restored = DialogueData.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.lines.length, original.lines.length);
    });
  });

  group('StoryNodeData', () {
    test('fromJson parses all fields', () {
      final node = StoryNodeData.fromJson({
        'id': 'n1',
        'label': 'Start',
        'description': 'Starting point',
        'x': 0.5,
        'y': 0.9,
        'dialogueId': 'dlg_intro',
      });
      expect(node.id, 'n1');
      expect(node.label, 'Start');
      expect(node.description, 'Starting point');
      expect(node.x, 0.5);
      expect(node.dialogueId, 'dlg_intro');
    });

    test('fromJson handles missing optional fields', () {
      final node = StoryNodeData.fromJson({
        'id': 'n2',
        'label': 'End',
        'x': 0.5,
        'y': 0.1,
      });
      expect(node.dialogueId, isNull);
      expect(node.description, '');
    });
  });

  group('StoryEdge', () {
    test('fromJson parses with name', () {
      final edge = StoryEdge.fromJson({
        'id': 'e1',
        'name': "St. Clement's Lane",
        'fromNodeId': 'n1',
        'toNodeId': 'n2',
        'levelAssetPath': 'assets/levels/level_1.json',
      });
      expect(edge.id, 'e1');
      expect(edge.name, "St. Clement's Lane");
      expect(edge.fromNodeId, 'n1');
    });

    test('fromJson handles missing name', () {
      final edge = StoryEdge.fromJson({
        'id': 'e2',
        'fromNodeId': 'n2',
        'toNodeId': 'n3',
        'levelAssetPath': 'l.json',
      });
      expect(edge.name, '');
    });
  });

  group('DistrictData', () {
    test('fromJson parses correctly', () {
      final d = DistrictData.fromJson({
        'id': 'district_1',
        'name': 'The Outer Rim',
        'subtitle': 'The Prole Quarters',
        'tier': 1,
        'nodeIds': ['n1', 'n2', 'n3'],
        'edgeIds': ['e1', 'e2'],
      });
      expect(d.id, 'district_1');
      expect(d.name, 'The Outer Rim');
      expect(d.tier, 1);
      expect(d.nodeIds, ['n1', 'n2', 'n3']);
      expect(d.edgeIds, ['e1', 'e2']);
    });
  });

  // Shared chapter data for ChapterData and OverworldState tests.
  ChapterData buildTestChapter() {
    return ChapterData.fromJson({
      'id': 'ch1',
      'title': 'Test',
      'chapterNumber': 1,
      'startNodeId': 'n1',
      'characters': {
        'c1': {'displayName': 'A', 'fullBodyAsset': 'a.png'},
      },
      'districts': [
        {
          'id': 't1',
          'name': 'District 1',
          'subtitle': 'Sub 1',
          'tier': 1,
          'nodeIds': ['n1', 'n2', 'n3'],
          'edgeIds': ['e1', 'e2'],
        },
        {
          'id': 't2',
          'name': 'District 2',
          'subtitle': 'Sub 2',
          'tier': 2,
          'nodeIds': ['n4', 'n5'],
          'edgeIds': ['e3'],
        },
      ],
      'nodes': [
        {'id': 'n1', 'label': 'A', 'x': 0.5, 'y': 0.9},
        {
          'id': 'n2',
          'label': 'B',
          'x': 0.5,
          'y': 0.5,
          'dialogueId': 'dlg_b',
        },
        {'id': 'n3', 'label': 'C', 'x': 0.5, 'y': 0.1},
        {'id': 'n4', 'label': 'D', 'x': 0.5, 'y': 0.9},
        {'id': 'n5', 'label': 'E', 'x': 0.5, 'y': 0.1},
      ],
      'edges': [
        {
          'id': 'e1',
          'name': 'Path 1',
          'fromNodeId': 'n1',
          'toNodeId': 'n2',
          'levelAssetPath': 'l.json',
        },
        {
          'id': 'e2',
          'name': 'Path 2',
          'fromNodeId': 'n2',
          'toNodeId': 'n3',
          'levelAssetPath': 'l.json',
        },
        {
          'id': 'e3',
          'name': 'Path 3',
          'fromNodeId': 'n4',
          'toNodeId': 'n5',
          'levelAssetPath': 'l.json',
        },
      ],
    });
  }

  group('ChapterData', () {
    late ChapterData chapter;
    setUp(() => chapter = buildTestChapter());

    test('parses districts', () {
      expect(chapter.districts, hasLength(2));
      expect(chapter.districts[0].name, 'District 1');
    });

    test('getNode works', () {
      expect(chapter.getNode('n1')!.label, 'A');
      expect(chapter.getNode('missing'), isNull);
    });

    test('getEdge works', () {
      expect(chapter.getEdge('e1')!.name, 'Path 1');
      expect(chapter.getEdge('missing'), isNull);
    });

    test('getDistrictForNode works', () {
      expect(chapter.getDistrictForNode('n1')!.id, 't1');
      expect(chapter.getDistrictForNode('n4')!.id, 't2');
      expect(chapter.getDistrictForNode('missing'), isNull);
    });

    test('edgesFrom returns outgoing edges', () {
      expect(chapter.edgesFrom('n1'), hasLength(1));
      expect(chapter.edgesFrom('n3'), isEmpty);
    });
  });

  group('OverworldState', () {
    late ChapterData chapter;
    late OverworldState state;

    setUp(() {
      chapter = buildTestChapter();
      state = OverworldState(
        chapter: chapter,
        dialogues: {
          'dlg_b': const DialogueData(
            id: 'dlg_b',
            lines: [
              DialogueLine(speakerId: 'c1', text: 'hi'),
            ],
          ),
        },
      );
    });

    test('starts at first node of first district', () {
      expect(state.currentNodeId, 'n1');
      expect(state.currentDistrictIndex, 0);
      expect(state.currentDistrict.id, 't1');
    });

    test('nextEdge returns the next unfinished edge', () {
      expect(state.nextEdge!.id, 'e1');
    });

    test('completeEdge advances within district', () {
      state.completeCurrentNode();
      state.completeEdge('e1');
      expect(state.currentNodeId, 'n2');
      expect(state.nextEdge!.id, 'e2');
    });

    test('isAtDistrictEnd after completing all edges', () {
      state.completeEdge('e1');
      state.completeEdge('e2');
      expect(state.currentNodeId, 'n3');
      expect(state.isAtDistrictEnd, isTrue);
    });

    test('isDistrictComplete checks all edge IDs', () {
      expect(
        state.isDistrictComplete(state.currentDistrict),
        isFalse,
      );
      state.completedEdgeIds.addAll(['e1', 'e2']);
      expect(
        state.isDistrictComplete(state.currentDistrict),
        isTrue,
      );
    });

    test('advanceToNextDistrict moves to district 2', () {
      state.completedEdgeIds.addAll(['e1', 'e2']);
      state.currentNodeId = 'n3';
      final advanced = state.advanceToNextDistrict();
      expect(advanced, isTrue);
      expect(state.currentDistrictIndex, 1);
      expect(state.currentNodeId, 'n4');
      expect(state.currentDistrict.id, 't2');
    });

    test('advanceToNextDistrict returns false at end', () {
      state.currentDistrictIndex = 1;
      final advanced = state.advanceToNextDistrict();
      expect(advanced, isFalse);
    });

    test('getDialogue returns loaded dialogue', () {
      expect(state.getDialogue('dlg_b')!.id, 'dlg_b');
      expect(state.getDialogue(null), isNull);
      expect(state.getDialogue('missing'), isNull);
    });
  });
}
