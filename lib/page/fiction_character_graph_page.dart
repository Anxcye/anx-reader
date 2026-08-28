import 'dart:math' as math;

import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/fiction_story_atlas_service.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:flutter/material.dart';

class FictionCharacterGraphPage extends StatefulWidget {
  const FictionCharacterGraphPage({
    super.key,
    required this.book,
    this.onOpenLocation,
    this.onRequestOrganize,
    this.initialAtlas,
    this.arcId,
  });

  final Book book;
  final Future<void> Function(String cfi)? onOpenLocation;
  final VoidCallback? onRequestOrganize;
  final FictionStoryAtlas? initialAtlas;
  final String? arcId;

  @override
  State<FictionCharacterGraphPage> createState() =>
      _FictionCharacterGraphPageState();
}

class _FictionCharacterGraphPageState extends State<FictionCharacterGraphPage> {
  late Future<FictionStoryAtlas> _future;
  FictionCharacterNode? _selected;
  FictionStoryAtlas? _atlas;
  bool? _fullMode;

  @override
  void initState() {
    super.initState();
    _future = widget.initialAtlas != null
        ? Future.value(widget.initialAtlas)
        : fictionStoryAtlasService.load(
            bookId: widget.book.id,
            visibleAtProgress: widget.book.readingPercentage,
            arcId: widget.arcId,
          );
  }

  void _select(FictionCharacterNode node, {bool sheet = true}) {
    setState(() => _selected = node);
    if (sheet && MediaQuery.sizeOf(context).width < 840) {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(child: _details(node)),
      );
    }
  }

  Future<void> _openSource(ReadingArtifactSource source) async {
    final cfi = source.cfi;
    if (cfi.isEmpty) return;
    await widget.onOpenLocation?.call(cfi);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('人物关系图')),
        body: FutureBuilder<FictionStoryAtlas>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('无法读取故事档案：${snapshot.error}'));
            }
            final atlas = snapshot.requireData;
            _atlas = atlas;
            _fullMode ??= _savedOrDefaultMode(atlas);
            if (atlas.characters.isEmpty) {
              return _emptyState(atlas);
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 840;
                final visibleAtlas =
                    _fullMode == true ? atlas : _compactAtlas(atlas);
                final graph = _graph(
                  visibleAtlas,
                  wide ? constraints.maxWidth - 320 : constraints.maxWidth,
                );
                if (!wide) return graph;
                return Row(
                  children: [
                    Expanded(child: graph),
                    SizedBox(width: 320, child: _details(_selected)),
                  ],
                );
              },
            );
          },
        ),
      );

  Widget _emptyState(FictionStoryAtlas atlas) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hub_outlined,
                  size: 52, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 14),
              Text(
                atlas.characters.isEmpty ? '还没有人物档案' : '还没有人物关系',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('这里只显示当前阅读进度以内的内容，不会自动读取后文。', textAlign: TextAlign.center),
              if (widget.onRequestOrganize != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: widget.onRequestOrganize,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('整理已读部分'),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _graph(FictionStoryAtlas atlas, double width) {
    final centerId = _protagonistId(atlas);
    final layout = _buildRadialGraphLayout(atlas, centerId, width);
    return Column(
      children: [
        _modeSelector(),
        if (_fullMode != true && atlas.relationships.isEmpty)
          _instantRecall(atlas),
        _boundaryBanner(atlas),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            alignment: Alignment.center,
            boundaryMargin: const EdgeInsets.all(240),
            minScale: 0.55,
            maxScale: 2.5,
            panEnabled: true,
            scaleEnabled: true,
            child: SizedBox(
              width: layout.size.width,
              height: layout.size.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _StoryGraphPainter(
                        atlas: atlas,
                        positions: layout.positions,
                        colorScheme: Theme.of(context).colorScheme,
                      ),
                    ),
                  ),
                  for (var index = 0;
                      index < atlas.relationships.length;
                      index++)
                    if (layout.relationPositions[index] != null)
                      _positionedRelationship(
                        atlas.relationships[index],
                        layout.relationPositions[index]!,
                      ),
                  // Nodes stay above lines and labels as the final visual and
                  // hit-test layer; relationship labels are already placed
                  // outside their bounds by the layout engine.
                  for (final character in atlas.characters)
                    _positionedCharacter(
                      character,
                      layout.positions[character.id]!,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_selected != null && width >= 840)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('点击人物查看摘要与来源；关系变化以来源章节为准。',
                style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }

  Widget _modeSelector() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
        child: Row(
          children: [
            const Icon(Icons.account_tree_outlined, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('故事人物档案 · 人物关系图'),
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('简洁模式')),
                ButtonSegment(value: true, label: Text('完整模式')),
              ],
              selected: {_fullMode ?? false},
              onSelectionChanged: (value) {
                final mode = value.first;
                setState(() => _fullMode = mode);
                Prefs().setFictionCharacterArchiveMode(
                  widget.book.id,
                  mode ? 'full' : 'compact',
                );
              },
            ),
          ],
        ),
      );

  Widget _instantRecall(FictionStoryAtlas atlas) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前人物回忆 · ${atlas.characters.length} 人',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final character in atlas.characters)
                  ActionChip(
                    avatar: _InitialAvatar(name: character.name),
                    label: Text(character.name),
                    onPressed: () => _select(character),
                  ),
              ],
            ),
          ],
        ),
      );

  bool _savedOrDefaultMode(FictionStoryAtlas atlas) {
    String? saved;
    // Widget tests and early startup can build this page before preferences
    // have finished loading; fall back to the complexity heuristic then.
    try {
      saved = Prefs().fictionCharacterArchiveMode(widget.book.id);
    } on Error {
      saved = null;
    }
    if (saved == 'full') return true;
    if (saved == 'compact') return false;
    // Small casts are better served by the low-distraction local archive.
    return atlas.characters.length > 8 || atlas.relationships.length > 12;
  }

  FictionStoryAtlas _compactAtlas(FictionStoryAtlas atlas) {
    if (atlas.characters.length <= 8 && atlas.relationships.length <= 12) {
      return atlas;
    }
    final protagonist = _protagonistId(atlas);
    final selected = <String>{protagonist};
    for (final edge in atlas.relationships) {
      if (edge.from == protagonist) selected.add(edge.to);
      if (edge.to == protagonist) selected.add(edge.from);
    }
    // Keep a small set of recently encountered people as context, while the
    // full network remains available through the explicit mode switch.
    final recent = atlas.characters.reversed
        .where((character) => selected.contains(character.id) == false)
        .take(4)
        .map((character) => character.id);
    selected.addAll(recent);
    final characters = atlas.characters
        .where((character) => selected.contains(character.id))
        .toList(growable: false);
    final relationships = atlas.relationships
        .where((edge) =>
            selected.contains(edge.from) && selected.contains(edge.to))
        .toList(growable: false);
    return FictionStoryAtlas(
      characters: characters,
      relationships: relationships,
      timeline: atlas.timeline,
      visibleProgress: atlas.visibleProgress,
      coverageStart: atlas.coverageStart,
      coverageEnd: atlas.coverageEnd,
      lastOrganizedProgress: atlas.lastOrganizedProgress,
      lastIngestedAt: atlas.lastIngestedAt,
      arcId: atlas.arcId,
    );
  }

  Widget _positionedCharacter(FictionCharacterNode character, Offset center) =>
      Positioned(
        left: center.dx - 56,
        top: center.dy - 30,
        width: 112,
        height: 84,
        child: Semantics(
          button: true,
          label: '查看${character.name}的人物详情',
          child: InkWell(
            key: ValueKey('fiction-character-${character.id}'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => _select(character),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _CharacterNode(
                character: character,
                selected: _selected?.id == character.id,
              ),
            ),
          ),
        ),
      );

  Widget _positionedRelationship(
          FictionRelationshipEdge relationship, Offset center) =>
      Positioned(
        left: center.dx - 34,
        top: center.dy - 12,
        width: 68,
        height: 24,
        child: Semantics(
          key: ValueKey(
            'fiction-relationship-${relationship.from}-${relationship.to}',
          ),
          button: true,
          label: '查看${_localizedRelation(relationship.relation)}关系',
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            shape: StadiumBorder(
              side: BorderSide(
                color: relationship.isChanged
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary,
                width: 1.2,
              ),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => _showRelationship(relationship),
              child: Center(
                child: Text(
                  _localizedRelation(relationship.relation),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  String _protagonistId(FictionStoryAtlas atlas) {
    final explicit = atlas.characters.where((character) {
      final role = character.source.payload['role']?.toString().toLowerCase();
      return role == 'protagonist' || role == 'main' || role == '主角';
    });
    if (explicit.isNotEmpty) return explicit.first.id;
    final scores = <String, int>{for (final c in atlas.characters) c.id: 0};
    for (final edge in atlas.relationships) {
      scores[edge.from] = (scores[edge.from] ?? 0) + 1;
      scores[edge.to] = (scores[edge.to] ?? 0) + 1;
    }
    return atlas.characters.reduce((a, b) {
      final scoreA = scores[a.id] ?? 0;
      final scoreB = scores[b.id] ?? 0;
      if (scoreA != scoreB) return scoreA > scoreB ? a : b;
      return a.source.sourceProgress <= b.source.sourceProgress ? a : b;
    }).id;
  }

  Widget _boundaryBanner(FictionStoryAtlas atlas) => Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '安全边界 ${(atlas.visibleProgress * 100).round()}% · '
                  '${atlas.characters.length} 人物 · '
                  '${atlas.relationships.length} 关系',
                ),
              ),
              if (widget.onRequestOrganize != null)
                TextButton(
                  onPressed: widget.onRequestOrganize,
                  child: const Text('补充人物'),
                ),
            ],
          ),
        ),
      );

  Widget _details(FictionCharacterNode? node) {
    if (node == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('选择一个人物查看详情。'),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(children: [
            _InitialAvatar(name: node.name, large: true),
            const SizedBox(width: 12),
            Expanded(
                child: Text(node.name,
                    style: Theme.of(context).textTheme.titleLarge)),
          ]),
          if (node.summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(node.summary),
          ],
          if (node.aliases.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('别名：${node.aliases.join('、')}'),
          ],
          if (node.courtesyNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('字：${node.courtesyNames.join('、')}'),
          ],
          if (node.artNames.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('号：${node.artNames.join('、')}'),
          ],
          if (node.titles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('称谓：${node.titles.join('、')}'),
          ],
          const SizedBox(height: 12),
          _sourceStatus(node.source),
          const SizedBox(height: 16),
          Text('已知关系', style: Theme.of(context).textTheme.titleMedium),
          for (final edge in _relationshipsFor(node))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${_otherName(edge, node)} · ${_localizedRelation(edge.relation)}',
              ),
              subtitle: Text(edge.summary.isEmpty ? edge.state : edge.summary),
              trailing: edge.isChanged ? const Icon(Icons.history) : null,
              onTap: () => _showRelationship(edge),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () =>
                _openSource(ReadingArtifactSource.fromArtifact(node.source)),
            icon: const Icon(Icons.short_text),
            label: const Text('返回来源'),
          ),
        ],
      ),
    );
  }

  List<FictionRelationshipEdge> _relationshipsFor(FictionCharacterNode node) {
    final atlas = _atlas;
    if (atlas == null) return const [];
    return atlas.relationships
        .where((edge) => edge.from == node.id || edge.to == node.id)
        .toList(growable: false);
  }

  String _otherName(FictionRelationshipEdge edge, FictionCharacterNode node) {
    final id = edge.from == node.id ? edge.to : edge.from;
    final atlas = _atlas;
    if (atlas == null) return id;
    for (final character in atlas.characters) {
      if (character.id == id) return character.name;
    }
    return id;
  }

  void _showRelationship(FictionRelationshipEdge edge) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_localizedRelation(edge.relation)}关系'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(edge.summary.isEmpty ? '当前位置没有更多描述。' : edge.summary),
              const SizedBox(height: 8),
              _sourceStatus(edge.source),
              const Divider(height: 28),
              Text('关系变化记录', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              for (final artifact in edge.history)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    '${_localizedRelation(artifact.payload['relation']?.toString() ?? '其他')} · ${_localizedRelationshipState(artifact.payload['state']?.toString() ?? 'active')}',
                  ),
                  subtitle: Text(
                    '${artifact.chapterTitle ?? '未知章节'} · ${(artifact.sourceProgress * 100).round()}%',
                  ),
                  trailing: const Icon(Icons.short_text, size: 20),
                  onTap: _sourceTarget(artifact).isEmpty
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          await widget.onOpenLocation
                              ?.call(_sourceTarget(artifact));
                        },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('关闭'))
        ],
      ),
    );
  }

  Widget _sourceStatus(ReadingArtifact artifact) => Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          visualDensity: VisualDensity.compact,
          avatar: Icon(
            artifact.epistemicStatus ==
                    ReadingArtifactEpistemicStatus.agentInference
                ? Icons.auto_awesome_outlined
                : Icons.menu_book_outlined,
            size: 16,
          ),
          label: Text(
            artifact.epistemicStatus ==
                    ReadingArtifactEpistemicStatus.agentInference
                ? 'AI 推测'
                : '文本事实',
          ),
        ),
      );

  String _sourceTarget(ReadingArtifact source) =>
      source.sourceStartCfi ??
      source.discoveredAtCfi ??
      source.chapterHref ??
      '';
}

class _StoryGraphPainter extends CustomPainter {
  const _StoryGraphPainter({
    required this.atlas,
    required this.positions,
    required this.colorScheme,
  });

  final FictionStoryAtlas atlas;
  final Map<String, Offset> positions;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < atlas.relationships.length; index++) {
      final edge = atlas.relationships[index];
      final from = positions[edge.from];
      final to = positions[edge.to];
      if (from == null || to == null) continue;
      final vector = to - from;
      final distance = vector.distance;
      if (distance <= 60) continue;
      final unit = vector / distance;
      final start = from + unit * 28;
      final end = to - unit * 28;
      final halo = Paint()
        ..color = colorScheme.surface
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final paint = Paint()
        ..color = edge.isChanged ? colorScheme.outline : colorScheme.primary
        ..strokeWidth = edge.isChanged ? 1.6 : 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(start, end, halo);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StoryGraphPainter oldDelegate) =>
      oldDelegate.atlas != atlas ||
      oldDelegate.positions != positions ||
      oldDelegate.colorScheme != colorScheme;
}

class _GraphLayout {
  const _GraphLayout({
    required this.size,
    required this.positions,
    required this.relationPositions,
  });

  final Size size;
  final Map<String, Offset> positions;
  final Map<int, Offset> relationPositions;
}

_GraphLayout _buildRadialGraphLayout(
  FictionStoryAtlas atlas,
  String centerId,
  double viewportWidth,
) {
  final byId = {
    for (final character in atlas.characters) character.id: character
  };
  final adjacency = <String, Set<String>>{
    for (final character in atlas.characters) character.id: <String>{},
  };
  for (final edge in atlas.relationships) {
    if (!adjacency.containsKey(edge.from) || !adjacency.containsKey(edge.to)) {
      continue;
    }
    adjacency[edge.from]!.add(edge.to);
    adjacency[edge.to]!.add(edge.from);
  }

  final distance = <String, int>{centerId: 0};
  final queue = <String>[centerId];
  for (var offset = 0; offset < queue.length; offset++) {
    final current = queue[offset];
    for (final next in adjacency[current] ?? const <String>{}) {
      if (distance.containsKey(next)) continue;
      distance[next] = distance[current]! + 1;
      queue.add(next);
    }
  }

  int compareNodes(String left, String right) {
    final degree =
        (adjacency[right]?.length ?? 0).compareTo(adjacency[left]?.length ?? 0);
    if (degree != 0) return degree;
    final progress = byId[left]!
        .source
        .sourceProgress
        .compareTo(byId[right]!.source.sourceProgress);
    if (progress != 0) return progress;
    return byId[left]!.name.compareTo(byId[right]!.name);
  }

  final groups = <int, List<String>>{};
  for (final id in byId.keys.where((id) => id != centerId)) {
    groups.putIfAbsent(distance[id] ?? -1, () => []).add(id);
  }
  for (final nodes in groups.values) {
    nodes.sort(compareNodes);
  }

  final ringNodes = <List<String>>[];
  final connectedDistances = groups.keys.where((value) => value > 0).toList()
    ..sort();
  final orderedGroups = [
    for (final value in connectedDistances) groups[value]!,
    if (groups[-1]?.isNotEmpty == true) groups[-1]!,
  ];
  for (final group in orderedGroups) {
    var offset = 0;
    while (offset < group.length) {
      final capacity = math.min(20, 8 + ringNodes.length * 4);
      ringNodes.add(group.skip(offset).take(capacity).toList(growable: false));
      offset += capacity;
    }
  }

  final radii = <double>[];
  var previousRadius = 0.0;
  for (var ring = 0; ring < ringNodes.length; ring++) {
    final count = ringNodes[ring].length;
    final byCircumference = count <= 1 ? 0.0 : count * 132 / (2 * math.pi);
    final radius = math.max(
      math.max(250.0 + ring * 160, byCircumference),
      previousRadius + 155,
    );
    radii.add(radius);
    previousRadius = radius;
  }
  final maxRadius = radii.isEmpty ? 0.0 : radii.last;
  final canvasWidth =
      math.max(viewportWidth, math.max(720.0, maxRadius * 2 + 220));
  final canvasHeight = math.max(620.0, maxRadius * 2 + 220);
  final origin = Offset(canvasWidth / 2, canvasHeight / 2);
  final positions = <String, Offset>{centerId: origin};
  for (var ring = 0; ring < ringNodes.length; ring++) {
    final nodes = ringNodes[ring];
    final phase = -math.pi / 2 + (ring.isOdd ? math.pi / nodes.length : 0);
    for (var index = 0; index < nodes.length; index++) {
      final angle = nodes.length == 1
          ? phase
          : phase + 2 * math.pi * index / nodes.length;
      positions[nodes[index]] = origin +
          Offset(radii[ring] * math.cos(angle), radii[ring] * math.sin(angle));
    }
  }

  final nodeBounds = [
    for (final center in positions.values)
      Rect.fromLTWH(center.dx - 56, center.dy - 30, 112, 84).inflate(8),
  ];
  final occupiedLabels = <Rect>[];
  final relationPositions = <int, Offset>{};
  for (var index = 0; index < atlas.relationships.length; index++) {
    final edge = atlas.relationships[index];
    final from = positions[edge.from];
    final to = positions[edge.to];
    if (from == null || to == null) continue;
    final vector = to - from;
    if (vector.distance == 0) continue;
    final normal = Offset(-vector.dy, vector.dx) / vector.distance;
    Offset? selected;
    for (final progress in const [.5, .42, .58, .34, .66, .26, .74]) {
      for (final shift in const [
        0.0,
        22.0,
        -22.0,
        44.0,
        -44.0,
        66.0,
        -66.0,
        88.0,
        -88.0,
      ]) {
        final candidate = from + vector * progress + normal * shift;
        final bounds = Rect.fromCenter(
          center: candidate,
          width: 76,
          height: 32,
        );
        final hitsNode = nodeBounds.any((rect) => rect.overlaps(bounds));
        final hitsLabel = occupiedLabels.any((rect) => rect.overlaps(bounds));
        if (!hitsNode && !hitsLabel) {
          selected = candidate;
          occupiedLabels.add(bounds);
          break;
        }
      }
      if (selected != null) break;
    }
    final fallback = selected ?? from + vector * .5 + normal * 22;
    relationPositions[index] = fallback;
    if (selected == null) {
      occupiedLabels.add(
        Rect.fromCenter(center: fallback, width: 76, height: 32),
      );
    }
  }
  return _GraphLayout(
    size: Size(canvasWidth, canvasHeight),
    positions: Map.unmodifiable(positions),
    relationPositions: Map.unmodifiable(relationPositions),
  );
}

class _CharacterNode extends StatelessWidget {
  const _CharacterNode({required this.character, required this.selected});
  final FictionCharacterNode character;
  final bool selected;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InitialAvatar(name: character.name, selected: selected),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 104),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface,
                width: 1.2,
              ),
            ),
            child: Text(
              character.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, height: 1.05),
            ),
          ),
        ],
      );
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar(
      {required this.name, this.large = false, this.selected = false});
  final String name;
  final bool large;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final diameter = (large ? 28.0 : 22.0) * 2;
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.primary : colors.surface,
        border: Border.all(
          color: selected ? colors.primary : colors.onSurface,
          width: selected ? 3 : 2,
        ),
      ),
      child: Text(
        _avatarInitial(name),
        style: TextStyle(
          color: selected ? colors.onPrimary : colors.onSurface,
          fontSize: large ? 24 : 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Returns the first character of a person's given name rather than the
/// family name. This keeps Chinese character avatars useful: 张三 -> 三,
/// 王小明 -> 小, 诸葛亮 -> 亮. For non-Chinese names we use the initial of
/// the final whitespace-delimited name part (John Doe -> D).
String _avatarInitial(String rawName) {
  final name = rawName.trim();
  if (name.isEmpty) return '?';

  final parts = name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  final lastPart = parts.isEmpty ? name : parts.last;
  final runes = lastPart.runes.toList(growable: false);
  if (runes.isEmpty) return '?';

  final isChineseName = runes.every((rune) =>
      (rune >= 0x3400 && rune <= 0x4DBF) || (rune >= 0x4E00 && rune <= 0x9FFF));
  if (!isChineseName || runes.length == 1) {
    return String.fromCharCode(runes.first);
  }

  // The common compound surnames need two characters skipped. Unknown
  // surnames default to a one-character surname, which covers the vast
  // majority of Chinese names without maintaining a large surname database.
  const compoundSurnames = {
    '欧阳',
    '司马',
    '上官',
    '诸葛',
    '东方',
    '独孤',
    '南宫',
    '夏侯',
    '皇甫',
    '尉迟',
    '公孙',
    '慕容',
    '令狐',
    '长孙',
    '宇文',
    '闻人',
    '赫连',
    '澹台',
    '端木',
    '拓跋',
    '百里',
    '钟离',
    '完颜',
    '呼延',
    '鲜于',
    '第五',
    '第八',
  };
  final surnameLength = runes.length >= 3 &&
          compoundSurnames.contains(String.fromCharCodes(runes.take(2)))
      ? 2
      : 1;
  return String.fromCharCode(
      runes[surnameLength < runes.length ? surnameLength : 0]);
}

String _localizedRelation(String raw) {
  const labels = {
    'parent': '亲子',
    'family': '家人',
    'colleague': '同事',
    'rival': '对手',
    'enemy': '敌对',
    'friend': '朋友',
    'spouse': '夫妻',
    'teacher': '师徒',
    'student': '师徒',
    'mentor': '师徒',
    '相识': '相识',
    'unknown': '其他',
    'active': '其他',
  };
  final value = raw.trim();
  return labels[value.toLowerCase()] ?? (value.isEmpty ? '其他' : value);
}

String _localizedRelationshipState(String raw) {
  const labels = {'active': '当前', 'changed': '已变化', 'ended': '已结束'};
  return labels[raw.trim().toLowerCase()] ?? '当前';
}

class ReadingArtifactSource {
  const ReadingArtifactSource({required this.cfi});
  final String cfi;
  factory ReadingArtifactSource.fromArtifact(ReadingArtifact artifact) =>
      ReadingArtifactSource(
        cfi: artifact.sourceStartCfi ??
            artifact.discoveredAtCfi ??
            artifact.chapterHref ??
            '',
      );
}
