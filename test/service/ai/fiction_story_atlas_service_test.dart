import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/fiction_story_atlas_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReadingArtifact artifact({
    required String id,
    required String kind,
    required double progress,
    required Map<String, dynamic> payload,
    int? createdAt,
  }) {
    final time = createdAt ?? (progress * 1000).round();
    return ReadingArtifact(
      id: id,
      bookId: 1,
      moduleId: 'fiction.immersion',
      kind: kind,
      payload: payload,
      sourceProgress: progress,
      visibleFromProgress: progress,
      chapterHref: 'chapter-$progress.xhtml',
      chapterTitle: '章节 $progress',
      ingestedAt: time,
      createdAt: time,
      updatedAt: time,
    );
  }

  test('filters future artifacts and selects latest visible relationship', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'a',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {'entityId': 'alice', 'name': '爱丽丝'},
      ),
      artifact(
        id: 'b',
        kind: ReadingArtifactKinds.character,
        progress: .12,
        payload: {'entityId': 'bob', 'name': '鲍勃'},
      ),
      artifact(
        id: 'r1',
        kind: ReadingArtifactKinds.relationship,
        progress: .2,
        payload: {
          'from': 'alice',
          'to': 'bob',
          'relation': '陌生人',
          'state': 'active',
        },
      ),
      artifact(
        id: 'r2',
        kind: ReadingArtifactKinds.relationship,
        progress: .4,
        payload: {
          'from': '爱丽丝',
          'to': '鲍勃',
          'relation': '朋友',
          'state': 'changed',
        },
      ),
      artifact(
        id: 'future',
        kind: ReadingArtifactKinds.character,
        progress: .8,
        payload: {'name': '未来人物'},
      ),
    ], visibleAtProgress: .5);

    expect(atlas.characters.map((item) => item.name), isNot(contains('未来人物')));
    expect(atlas.relationships.single.relation, '朋友');
    expect(atlas.relationships.single.history, hasLength(2));
  });

  test('filters scoped atlas to the current arc while retaining global cast',
      () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'main',
        kind: ReadingArtifactKinds.character,
        progress: .01,
        payload: {'name': '主角', 'role': 'main_character', 'scope': 'global'},
      ),
      artifact(
        id: 'case-a',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {'name': '甲', 'arcId': 'volume-1-arc-1'},
      ),
      artifact(
        id: 'case-b',
        kind: ReadingArtifactKinds.character,
        progress: .2,
        payload: {'name': '乙', 'arcId': 'volume-1-arc-2'},
      ),
      artifact(
        id: 'event-a',
        kind: ReadingArtifactKinds.event,
        progress: .15,
        payload: {
          'title': '案件一',
          'arcId': 'volume-1-arc-1',
          'participants': ['甲']
        },
      ),
      artifact(
        id: 'event-b',
        kind: ReadingArtifactKinds.event,
        progress: .25,
        payload: {
          'title': '案件二',
          'arcId': 'volume-1-arc-2',
          'participants': ['乙']
        },
      ),
    ], visibleAtProgress: .3, arcId: 'volume-1-arc-1');

    expect(atlas.arcId, 'volume-1-arc-1');
    expect(atlas.characters.map((item) => item.name), containsAll(['主角', '甲']));
    expect(atlas.characters.map((item) => item.name), isNot(contains('乙')));
    expect(atlas.timeline.map((item) => item.title), ['案件一']);
  });

  test('does not mix explicitly scoped works inside one collection book', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'white-night-character',
        kind: ReadingArtifactKinds.character,
        progress: .3,
        payload: {
          'name': '唐泽雪穗',
          'workId': 'work-white-night',
        },
      ),
      artifact(
        id: 'white-night-event',
        kind: ReadingArtifactKinds.event,
        progress: .31,
        payload: {
          'title': '白夜行事件',
          'workId': 'work-white-night',
        },
      ),
      artifact(
        id: 'general-store-character',
        kind: ReadingArtifactKinds.character,
        progress: .6,
        payload: {
          'name': '浪矢雄治',
          'workId': 'work-general-store',
        },
      ),
      artifact(
        id: 'general-store-event',
        kind: ReadingArtifactKinds.event,
        progress: .61,
        payload: {
          'title': '杂货店事件',
          'workId': 'work-general-store',
        },
      ),
    ], visibleAtProgress: .7, workId: 'work-white-night');

    expect(atlas.workId, 'work-white-night');
    expect(atlas.characters.map((item) => item.name), ['唐泽雪穗']);
    expect(atlas.timeline.map((item) => item.title), ['白夜行事件']);
  });

  test('infers the latest encountered arc from source progress', () {
    final artifacts = [
      artifact(
        id: 'a',
        kind: ReadingArtifactKinds.event,
        progress: .1,
        payload: {'title': '一案', 'arcId': 'arc-1'},
      ),
      artifact(
        id: 'b',
        kind: ReadingArtifactKinds.event,
        progress: .2,
        payload: {'title': '二案', 'arcId': 'arc-2'},
      ),
    ];
    expect(fictionStoryAtlasService.currentArcId(artifacts, .15), 'arc-1');
    expect(fictionStoryAtlasService.currentArcId(artifacts, .25), 'arc-2');
  });

  test('promotes named event participants when character output is missing',
      () {
    final artifacts = [
      artifact(
        id: 'known-character',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {'entityId': 'known', 'name': '第五伦'},
      ),
      artifact(
        id: 'event-with-missing-character',
        kind: ReadingArtifactKinds.event,
        progress: .2,
        payload: {
          'title': '众人相遇',
          'participants': ['known', '第八娇', '众人', 'character_2', '伦'],
        },
      ),
    ];

    final atlas = fictionStoryAtlasService.fromArtifacts(
      artifacts,
      visibleAtProgress: .5,
    );

    expect(atlas.characters.map((character) => character.name),
        containsAll(['第五伦', '第八娇']));
    final names = atlas.characters.map((character) => character.name);
    expect(names, isNot(contains('众人')));
    expect(names, isNot(contains('character_2')));
    expect(names, isNot(contains('伦')));
  });

  test('sorts timeline by source order instead of story time label', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'later-text',
        kind: ReadingArtifactKinds.event,
        progress: .3,
        payload: {'title': '十年前', 'storyTimeLabel': '十年前'},
      ),
      artifact(
        id: 'earlier-text',
        kind: ReadingArtifactKinds.event,
        progress: .1,
        payload: {'title': '今天', 'storyTimeLabel': '今天'},
      ),
      artifact(
        id: 'unknown',
        kind: 'fiction.location',
        progress: .05,
        payload: {'title': '安全忽略'},
      ),
    ], visibleAtProgress: .5);

    expect(atlas.timeline.map((item) => item.title), ['今天', '十年前']);
  });

  test('merges repeated full names and resolves a unique short name', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'character-1',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {'entityId': 'diwu-lun-1', 'name': '第五伦'},
      ),
      artifact(
        id: 'character-2',
        kind: ReadingArtifactKinds.character,
        progress: .2,
        payload: {'entityId': 'diwu-lun-2', 'name': '第五伦'},
      ),
      artifact(
        id: 'character-3',
        kind: ReadingArtifactKinds.character,
        progress: .15,
        payload: {'entityId': 'jiaohua', 'name': '第八娇'},
      ),
      artifact(
        id: 'relationship',
        kind: ReadingArtifactKinds.relationship,
        progress: .3,
        payload: {
          'from': '伦',
          'to': 'jiaohua',
          'relation': '朋友',
        },
      ),
    ], visibleAtProgress: .5);

    expect(atlas.characters.where((item) => item.name == '第五伦'), hasLength(1));
    expect(atlas.characters, hasLength(2));
    final edge = atlas.relationships.single;
    expect(atlas.characters.firstWhere((item) => item.id == edge.from).name,
        '第五伦');
    expect(
        atlas.characters.firstWhere((item) => item.id == edge.to).name, '第八娇');
  });

  test('merges a legacy one-character node into its unique full name', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'short-character',
        kind: ReadingArtifactKinds.character,
        progress: .05,
        payload: {'entityId': 'old-lun', 'name': '伦'},
      ),
      artifact(
        id: 'full-character',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {'entityId': 'diwu-lun', 'name': '“第五　伦”'},
      ),
      artifact(
        id: 'target',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {'entityId': 'jiao', 'name': '第八娇'},
      ),
      artifact(
        id: 'relationship',
        kind: ReadingArtifactKinds.relationship,
        progress: .2,
        payload: {'from': 'old-lun', 'to': 'jiao', 'relation': '朋友'},
      ),
    ], visibleAtProgress: .5);

    expect(atlas.characters.map((item) => item.name),
        containsAll(<String>['第五伦', '第八娇']));
    expect(atlas.characters, hasLength(2));
    final edge = atlas.relationships.single;
    expect(atlas.characters.firstWhere((item) => item.id == edge.from).name,
        '第五伦');
  });

  test('does not guess an ambiguous one-character relationship endpoint', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'first-lun',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {'entityId': 'diwu-lun', 'name': '第五伦'},
      ),
      artifact(
        id: 'second-lun',
        kind: ReadingArtifactKinds.character,
        progress: .11,
        payload: {'entityId': 'zhou-lun', 'name': '周伦'},
      ),
      artifact(
        id: 'target',
        kind: ReadingArtifactKinds.character,
        progress: .12,
        payload: {'entityId': 'jiao', 'name': '第八娇'},
      ),
      artifact(
        id: 'ambiguous-relationship',
        kind: ReadingArtifactKinds.relationship,
        progress: .2,
        payload: {'from': '伦', 'to': 'jiao', 'relation': '朋友'},
      ),
    ], visibleAtProgress: .5);

    expect(atlas.characters.map((item) => item.name), isNot(contains('伦')));
    expect(atlas.characters, hasLength(3));
    expect(atlas.relationships, isEmpty);
  });

  test('full names take priority over conflicting aliases', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'wang-lun',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {'entityId': 'wang-lun', 'name': '王伦'},
      ),
      artifact(
        id: 'diwu-lun',
        kind: ReadingArtifactKinds.character,
        progress: .11,
        payload: {
          'entityId': 'diwu-lun',
          'name': '第五伦',
          'aliases': ['王伦'],
        },
      ),
      artifact(
        id: 'target',
        kind: ReadingArtifactKinds.character,
        progress: .12,
        payload: {'entityId': 'jiao', 'name': '第八娇'},
      ),
      artifact(
        id: 'relationship',
        kind: ReadingArtifactKinds.relationship,
        progress: .2,
        payload: {'from': '王伦', 'to': 'jiao', 'relation': '相识'},
      ),
    ], visibleAtProgress: .5);

    final edge = atlas.relationships.single;
    expect(
        atlas.characters.firstWhere((item) => item.id == edge.from).name, '王伦');
    expect(atlas.characters.where((item) => item.name == '第五伦'), hasLength(1));
  });

  test('reused model entity ids do not merge different full names', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'first',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {'entityId': 'character-1', 'name': '第五伦'},
      ),
      artifact(
        id: 'second',
        kind: ReadingArtifactKinds.character,
        progress: .11,
        payload: {'entityId': 'character-1', 'name': '第八娇'},
      ),
      artifact(
        id: 'ambiguous-id-relationship',
        kind: ReadingArtifactKinds.relationship,
        progress: .2,
        payload: {'from': 'character-1', 'to': '第五伦', 'relation': '相识'},
      ),
    ], visibleAtProgress: .5);

    expect(atlas.characters, hasLength(2));
    expect(atlas.characters.map((item) => item.name),
        containsAll(<String>['第五伦', '第八娇']));
    expect(atlas.relationships, isEmpty);
  });

  test('same entity id merges a short and compatible full name', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'short',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {'entityId': 'character-1', 'name': '伦'},
      ),
      artifact(
        id: 'full',
        kind: ReadingArtifactKinds.character,
        progress: .2,
        payload: {'entityId': 'character-1', 'name': '第五伦'},
      ),
    ], visibleAtProgress: .5);

    expect(atlas.characters, hasLength(1));
    expect(atlas.characters.single.name, '第五伦');
  });

  test('Chinese name, courtesy name and art name resolve to one person', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'liu-bei',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {
          'namingSystem': 'chinese',
          'entityId': 'liu-bei',
          'name': '刘备',
          'aliases': ['字：玄德', '称谓：汉中王'],
        },
      ),
      artifact(
        id: 'legacy-xuande',
        kind: ReadingArtifactKinds.character,
        progress: .11,
        payload: {
          'namingSystem': 'chinese',
          'entityId': 'xuande',
          'name': '玄德',
        },
      ),
      artifact(
        id: 'zhuge-liang',
        kind: ReadingArtifactKinds.character,
        progress: .12,
        payload: {
          'namingSystem': 'chinese',
          'entityId': 'zhuge-liang',
          'name': '诸葛亮',
          'courtesyNames': ['孔明'],
          'artName': '卧龙',
        },
      ),
      artifact(
        id: 'relationship',
        kind: ReadingArtifactKinds.relationship,
        progress: .2,
        payload: {'from': '玄德', 'to': '孔明', 'relation': '君臣'},
      ),
    ], visibleAtProgress: .5);

    expect(atlas.characters, hasLength(2));
    final liuBei =
        atlas.characters.firstWhere((character) => character.name == '刘备');
    final zhugeLiang =
        atlas.characters.firstWhere((character) => character.name == '诸葛亮');
    expect(liuBei.courtesyNames, ['玄德']);
    expect(liuBei.titles, ['汉中王']);
    expect(zhugeLiang.courtesyNames, ['孔明']);
    expect(zhugeLiang.artNames, ['卧龙']);
    expect(atlas.relationships.single.from, liuBei.id);
    expect(atlas.relationships.single.to, zhugeLiang.id);
  });

  test('Western full name, nickname and title form resolve to one person', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'elizabeth',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {
          'namingSystem': 'western',
          'entityId': 'elizabeth-bennet',
          'name': 'Elizabeth Bennet',
          'givenName': 'Elizabeth',
          'familyName': 'Bennet',
          'aliases': ['Lizzy', 'Miss Bennet'],
        },
      ),
      artifact(
        id: 'legacy-lizzy',
        kind: ReadingArtifactKinds.character,
        progress: .11,
        payload: {
          'namingSystem': 'western',
          'entityId': 'lizzy',
          'name': 'Lizzy',
        },
      ),
      artifact(
        id: 'darcy',
        kind: ReadingArtifactKinds.character,
        progress: .12,
        payload: {
          'namingSystem': 'western',
          'entityId': 'fitzwilliam-darcy',
          'name': 'Fitzwilliam Darcy',
          'givenName': 'Fitzwilliam',
          'familyName': 'Darcy',
          'aliases': ['Mr. Darcy'],
        },
      ),
      artifact(
        id: 'legacy-darcy',
        kind: ReadingArtifactKinds.character,
        progress: .13,
        payload: {
          'namingSystem': 'western',
          'entityId': 'mr-darcy',
          'name': 'Mr Darcy',
        },
      ),
      artifact(
        id: 'relationship',
        kind: ReadingArtifactKinds.relationship,
        progress: .2,
        payload: {'from': 'Lizzy', 'to': 'Mr. Darcy', 'relation': '相识'},
      ),
    ], visibleAtProgress: .5);

    expect(atlas.characters, hasLength(2));
    final elizabeth = atlas.characters
        .firstWhere((character) => character.name == 'Elizabeth Bennet');
    final darcy = atlas.characters
        .firstWhere((character) => character.name == 'Fitzwilliam Darcy');
    expect(elizabeth.givenName, 'Elizabeth');
    expect(elizabeth.familyName, 'Bennet');
    expect(atlas.relationships.single.from, elizabeth.id);
    expect(atlas.relationships.single.to, darcy.id);
  });

  test('ambiguous Western surname does not create a duplicate node', () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'elizabeth',
        kind: ReadingArtifactKinds.character,
        progress: .1,
        payload: {'name': 'Elizabeth Bennet'},
      ),
      artifact(
        id: 'jane',
        kind: ReadingArtifactKinds.character,
        progress: .11,
        payload: {'name': 'Jane Bennet'},
      ),
      artifact(
        id: 'darcy',
        kind: ReadingArtifactKinds.character,
        progress: .12,
        payload: {'name': 'Fitzwilliam Darcy'},
      ),
      artifact(
        id: 'relationship',
        kind: ReadingArtifactKinds.relationship,
        progress: .2,
        payload: {'from': 'Bennet', 'to': 'Darcy', 'relation': '相识'},
      ),
    ], visibleAtProgress: .5);

    expect(atlas.characters, hasLength(3));
    expect(atlas.characters.map((character) => character.name),
        isNot(contains('Bennet')));
    expect(atlas.relationships, isEmpty);
  });

  test('groups long timeline by chapter and applies density and participant',
      () {
    final atlas = fictionStoryAtlasService.fromArtifacts([
      artifact(
        id: 'major',
        kind: ReadingArtifactKinds.event,
        progress: .1,
        payload: {
          'title': '重大转折',
          'importance': 'major',
          'participants': ['林青'],
        },
      ),
      artifact(
        id: 'normal',
        kind: ReadingArtifactKinds.event,
        progress: .2,
        payload: {
          'title': '普通事件',
          'participants': ['周明']
        },
      ),
      artifact(
        id: 'scene',
        kind: ReadingArtifactKinds.scene,
        progress: .3,
        payload: {
          'title': '场景描写',
          'participants': ['林青']
        },
      ),
    ], visibleAtProgress: .5);

    final compact = fictionStoryAtlasService.timelineChapters(atlas.timeline);
    expect(
        compact.expand((chapter) => chapter.events).map((event) => event.title),
        ['重大转折']);

    final standard = fictionStoryAtlasService.timelineChapters(
      atlas.timeline,
      density: FictionTimelineDensity.standard,
    );
    expect(standard.expand((chapter) => chapter.events), hasLength(2));

    final linQing = fictionStoryAtlasService.timelineChapters(
      atlas.timeline,
      density: FictionTimelineDensity.complete,
      participant: '林青',
    );
    expect(linQing.expand((chapter) => chapter.events), hasLength(2));
  });
}
