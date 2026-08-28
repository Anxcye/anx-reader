import 'dart:convert';

import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/ai_extraction_engine.dart';
import 'package:anx_reader/service/ai/ai_token_usage_service.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/reading_evidence_resolver.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/chat_models.dart';

class FictionHybridExtractionService {
  FictionHybridExtractionService({required this.ref});

  final WidgetRef ref;
  int _baselineInputTokens = 0;
  int _cloudVerificationInputTokens = 0;
  final Set<String> _baselineFingerprints = {};

  static const maxCloudVerificationRatio = .20;

  static bool withinCloudVerificationBudget({
    required int baselineInputTokens,
    required int usedCloudInputTokens,
    required int nextCloudInputTokens,
  }) =>
      usedCloudInputTokens + nextCloudInputTokens <=
      (baselineInputTokens * maxCloudVerificationRatio).floor();

  AiProvider? get provider => aiExtractionEngine.resolveProvider(ref);

  Map<String, dynamic> get artifactMetadata => {
        'pipelineVersion': AiExtractionEngine.pipelineVersion,
        if (provider case final value?) ...{
          'extractorProvider': value.id,
          'extractorModel': value.model,
          'extractorDeployment': value.deployment.name,
        },
      };

  Future<String> generate(String prompt) async {
    final baseline = aiContextAssembler.estimateTokens(prompt);
    final fingerprint = sha256.convert(utf8.encode(prompt)).toString();
    if (_baselineFingerprints.add(fingerprint)) {
      _baselineInputTokens += baseline;
      aiTokenUsageService.recordStorySavings(
        baselineInputTokens: baseline,
        cloudInputTokens: 0,
      );
    }
    final result = await aiExtractionEngine.extract(
      taskId: AiExtractionTaskIds.fictionStoryAtlas,
      prompt: prompt,
      ref: ref,
    );
    if (!result.isValid) {
      throw FormatException(result.validationErrors.join('；'));
    }
    return result.raw;
  }

  Future<Map<String, dynamic>?> validate({
    required String kind,
    required Map<String, dynamic> payload,
    required String chapterContent,
  }) async {
    final normalized = FictionCandidateRuleValidator.normalizePayload(
      kind,
      payload,
    );
    final verdict = const FictionCandidateRuleValidator().validate(
      kind: kind,
      payload: normalized,
      chapterContent: chapterContent,
    );
    if (verdict.status == FictionCandidateRuleStatus.rejected) return null;
    if (verdict.status == FictionCandidateRuleStatus.accepted) {
      return verdict.payload;
    }
    return _verifyAmbiguous(
      verdict.payload,
      verdict.payload['evidence']?.toString() ?? '',
    );
  }

  /// Deterministic-only validation for the regular cloud model path. Cloud
  /// generation may be used when no local extractor is configured, but its
  /// candidates must still prove an exact source substring before persistence.
  Future<Map<String, dynamic>?> validateDirect({
    required String kind,
    required Map<String, dynamic> payload,
    required String chapterContent,
  }) async {
    final normalized = FictionCandidateRuleValidator.normalizePayload(
      kind,
      payload,
    );
    final verdict = const FictionCandidateRuleValidator().validate(
      kind: kind,
      payload: normalized,
      chapterContent: chapterContent,
    );
    if (verdict.status != FictionCandidateRuleStatus.accepted) return null;
    return verdict.payload;
  }

  Future<Map<String, dynamic>?> _verifyAmbiguous(
    Map<String, dynamic> payload,
    String evidence,
  ) async {
    final prompt = '''你只复核一条小说人物关系候选，不得使用证据之外的知识。
候选：${jsonEncode(payload)}
原文证据：${jsonEncode(evidence)}
只返回 JSON：{"decision":"accept|reject|normalize","relation":"必要时的简短中文关系"}。
不得新增人物、证据或关系事实。''';
    try {
      final cloudInput = aiContextAssembler.estimateTokens(prompt);
      if (!withinCloudVerificationBudget(
        baselineInputTokens: _baselineInputTokens,
        usedCloudInputTokens: _cloudVerificationInputTokens,
        nextCloudInputTokens: cloudInput,
      )) {
        return null;
      }
      _cloudVerificationInputTokens += cloudInput;
      aiTokenUsageService.recordStorySavings(
        baselineInputTokens: 0,
        cloudInputTokens: cloudInput,
      );
      final generated = await aiTokenUsageService.runWithRole(
        AiTokenUsageRole.cloudVerification,
        () => aiGenerateTextWithMetadata(
          [ChatMessage.humanText(prompt)],
          ref: ref,
          task: AiContextTask.cloudVerification,
        ),
      );
      final decoded = _decodeObject(generated.value);
      final decision = decoded['decision']?.toString();
      if (decision == 'reject') return null;
      if (decision != 'accept' && decision != 'normalize') return null;
      final normalized = decoded['relation']?.toString().trim() ?? '';
      return {
        ...payload,
        if (decision == 'normalize' && normalized.isNotEmpty)
          'relation': normalized,
        'confidenceSource': 'cloudVerified',
        'reviewStatus': decision,
        if (generated.providerId != null)
          'reviewProvider': generated.providerId,
        if (generated.model != null) 'reviewModel': generated.model,
      };
    } catch (_) {
      // Keep an ambiguous item pending instead of weakening privacy or
      // silently accepting it after the verifier failed.
      return null;
    }
  }

  Map<String, dynamic> _decodeObject(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) throw const FormatException('Invalid JSON');
    return Map<String, dynamic>.from(
      jsonDecode(raw.substring(start, end + 1)) as Map,
    );
  }
}

enum FictionCandidateRuleStatus { accepted, ambiguous, rejected }

class FictionCandidateRuleVerdict {
  const FictionCandidateRuleVerdict(this.status, this.payload);
  final FictionCandidateRuleStatus status;
  final Map<String, dynamic> payload;
}

class FictionCandidateRuleValidator {
  const FictionCandidateRuleValidator();

  /// Normalizes model references without inventing a real-world identity.
  /// The narrator is a stable entity even when the EPUB only says “我”.
  static Map<String, dynamic> normalizePayload(
    String kind,
    Map<String, dynamic> payload,
  ) {
    final result = Map<String, dynamic>.from(payload);
    final narrativeLayer =
        FictionNarrativeLayerIds.normalize(result['narrativeLayer']);
    String normalizePerson(Object? value) {
      final text = value?.toString().trim() ?? '';
      if ({'我', '叙述者', 'narrator', '采歌人', '讲故事的人'}.contains(text)) {
        return narrativeLayer == FictionNarrativeLayerIds.inner ? text : '叙述者';
      }
      return text;
    }

    if (kind == ReadingArtifactKinds.character) {
      result['entityType'] = FictionEntityTypeIds.normalize(
        result['entityType'],
      );
      final name = normalizePerson(result['name']);
      final aliases = (result['aliases'] as List?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toSet() ??
          <String>{};
      if (narrativeLayer != FictionNarrativeLayerIds.inner &&
          (name == '叙述者' || aliases.contains('我'))) {
        if (name != '叙述者' && name.isNotEmpty) {
          result['titles'] = {
            ...((result['titles'] as List?)?.map((e) => e.toString()) ??
                const <String>[]),
            name,
          }.toList();
        }
        result['name'] = '叙述者';
        result['entityId'] = 'narrator.outer';
        result['narrativeLayer'] = FictionNarrativeLayerIds.outer;
        result['role'] = result['role'] ?? 'protagonist';
        result['namingSystem'] = result['namingSystem'] ?? 'chinese';
        result['aliases'] = {...aliases, '我'}.toList();
      } else if (narrativeLayer == FictionNarrativeLayerIds.inner) {
        result['narrativeLayer'] = FictionNarrativeLayerIds.inner;
        result['narratorRole'] ??= 'first_person';
      }
    } else if (kind == ReadingArtifactKinds.relationship) {
      // Accept the common subject/predicate/object spelling emitted by
      // OpenAI-compatible models, while keeping the canonical Atlas schema.
      result['from'] ??= result['subject'];
      result['to'] ??= result['object'];
      result['relation'] ??= result['predicate'];
      result['from'] = normalizePerson(result['from']);
      result['to'] = normalizePerson(result['to']);
      if (result['from'] == '叙述者') result['fromEntityId'] = 'narrator.outer';
      if (result['to'] == '叙述者') result['toEntityId'] = 'narrator.outer';
      final relation = result['relation']?.toString().trim() ?? '';
      result['relationType'] = FictionRelationTypeIds.normalize(
        result['relationType'] ?? _relationTypeFor(relation),
      );
      if (result['fromEntityType'] != null) {
        result['fromEntityType'] =
            FictionEntityTypeIds.normalize(result['fromEntityType']);
      }
      if (result['toEntityType'] != null) {
        result['toEntityType'] =
            FictionEntityTypeIds.normalize(result['toEntityType']);
      }
    } else if (kind == ReadingArtifactKinds.event) {
      final type = result['eventType']?.toString().trim() ?? '';
      if ((result['title']?.toString().trim().isEmpty ?? true) &&
          type.isNotEmpty) {
        result['title'] = type;
      }
      final participants = result['participants'];
      if (participants is List) {
        result['participants'] = participants.map(normalizePerson).toList();
      }
      final inferredTrack = RegExp(r'宇宙|文明|技术|科学|星际|外星|行星|物理规律')
              .hasMatch('${result['title']} ${result['summary']} $type')
          ? FictionEventTrackIds.worldbuilding
          : FictionEventTrackIds.caseInvestigation;
      result['track'] = FictionEventTrackIds.normalize(
        result['track'] ?? inferredTrack,
      );
      result['stage'] = _normalizeStage(result['stage'], type);
    }
    return result;
  }

  static String _relationTypeFor(String relation) {
    if (relation.contains('师') ||
        relation.contains('导师') ||
        relation.contains('老师')) {
      return FictionRelationTypeIds.mentor;
    }
    if (relation.contains('搭档') || relation.contains('队友')) {
      return FictionRelationTypeIds.partner;
    }
    if (relation.contains('同桌') || relation.contains('同学')) {
      return FictionRelationTypeIds.schoolmate;
    }
    if (relation.contains('同事') || relation.contains('同僚')) {
      return FictionRelationTypeIds.colleague;
    }
    if (relation.contains('战友')) return FictionRelationTypeIds.comrade;
    if (RegExp(r'夫妻|婚|丈夫|妻子|配偶').hasMatch(relation)) {
      return FictionRelationTypeIds.spouse;
    }
    if (RegExp(r'恋人|恋爱|情侣').hasMatch(relation)) {
      return FictionRelationTypeIds.romantic;
    }
    if (RegExp(r'父|母|子|女').hasMatch(relation)) {
      return FictionRelationTypeIds.parentChild;
    }
    if (RegExp(r'父|母|子|女|兄|弟|姐|妹|祖|孙|夫妻|婚|亲属').hasMatch(relation)) {
      return FictionRelationTypeIds.family;
    }
    if (relation.contains('盟友') || relation.contains('朋友')) {
      return FictionRelationTypeIds.ally;
    }
    if (relation.contains('敌') || relation.contains('对手')) {
      return FictionRelationTypeIds.rival;
    }
    return FictionRelationTypeIds.other;
  }

  static String _stageForEvent(String eventType) => switch (eventType) {
        '冲突' => FictionEventStageIds.conflict,
        '揭示' => FictionEventStageIds.revelation,
        '转折' => FictionEventStageIds.turningPoint,
        _ => FictionEventStageIds.other,
      };

  static String _normalizeStage(Object? value, String eventType) {
    final stage = value?.toString().trim() ?? '';
    if (stage.isNotEmpty) {
      return FictionEventStageIds.normalize(stage);
    }
    return _stageForEvent(eventType);
  }

  FictionCandidateRuleVerdict validate({
    required String kind,
    required Map<String, dynamic> payload,
    required String chapterContent,
  }) {
    FictionCandidateRuleVerdict reject() => FictionCandidateRuleVerdict(
        FictionCandidateRuleStatus.rejected, payload);
    final evidence = payload['evidence']?.toString().trim() ?? '';
    if (evidence.isEmpty ||
        evidence.length > 80 ||
        !_evidenceMatches(chapterContent, evidence)) {
      return reject();
    }
    if (kind == ReadingArtifactKinds.character) {
      final name = payload['name']?.toString().trim() ?? '';
      final entityType = FictionEntityTypeIds.normalize(payload['entityType']);
      if (!_characterEntityTypes.contains(entityType)) return reject();
      if ((name != '叙述者' && _isGenericPerson(name)) || name.length < 2) {
        return reject();
      }
      if (_looksLikeBackgroundReference(evidence)) return reject();
      return FictionCandidateRuleVerdict(
        FictionCandidateRuleStatus.accepted,
        {...payload, 'confidenceSource': 'evidenceValidated'},
      );
    }
    if (kind == ReadingArtifactKinds.event) {
      return FictionCandidateRuleVerdict(
        FictionCandidateRuleStatus.accepted,
        {...payload, 'confidenceSource': 'evidenceValidated'},
      );
    }
    if (kind != ReadingArtifactKinds.relationship) return reject();
    final relation = payload['relation']?.toString().trim() ?? '';
    final from = payload['from']?.toString().trim() ?? '';
    final to = payload['to']?.toString().trim() ?? '';
    final fromType = payload['fromEntityType'];
    final toType = payload['toEntityType'];
    if ((fromType != null &&
            !_characterEntityTypes.contains(
              FictionEntityTypeIds.normalize(fromType),
            )) ||
        (toType != null &&
            !_characterEntityTypes.contains(
              FictionEntityTypeIds.normalize(toType),
            ))) {
      return reject();
    }
    if ((from != '叙述者' && _isGenericPerson(from)) ||
        (to != '叙述者' && _isGenericPerson(to)) ||
        _invalidRelationLabels.contains(relation)) {
      return reject();
    }
    if (_transientRelations.any(relation.contains) ||
        !_durableRelations.any(relation.contains)) {
      return reject();
    }
    if (_explicitRelationTerms.any(evidence.contains)) {
      return FictionCandidateRuleVerdict(
        FictionCandidateRuleStatus.accepted,
        {
          ...payload,
          'confidenceSource': 'explicitText',
          'reviewStatus': 'ruleAccepted',
        },
      );
    }
    return FictionCandidateRuleVerdict(
      FictionCandidateRuleStatus.ambiguous,
      payload,
    );
  }

  bool _evidenceMatches(String content, String evidence) {
    return readingEvidenceResolver.resolve(
          sourceText: content,
          evidence: evidence,
        ) !=
        null;
  }

  bool _looksLikeBackgroundReference(String evidence) => const [
        '曾言',
        '两百年前',
        '之后',
        '被称为',
        '典故',
        '书中记载',
      ].any(evidence.contains);

  static const _genericNames = {
    '我',
    '他',
    '她',
    '它',
    '自己',
    '死者',
    '尸体',
    '被害人',
    '受害者',
    '丈夫',
    '妻子',
    '儿子',
    '女儿',
    '父亲',
    '母亲',
    '男人',
    '女人',
    '男孩',
    '女孩',
    '孩子',
    '工人',
    '清淤工人',
    '警员',
    '民警',
    '警察',
    '法医',
    '检验对象',
    '县宰',
    '长平县宰',
    '诸生',
    '吏卒',
    '士卒',
    '百姓',
    '少年',
    '侍从',
    '众人',
  };
  static const _invalidRelationLabels = {
    '检验对象',
    '无明确持久关系',
    '无明确关系',
    '关系不明',
  };
  static const _characterEntityTypes = {
    FictionEntityTypeIds.person,
    FictionEntityTypeIds.intelligentNonhuman,
  };

  bool _isGenericPerson(String value) {
    if (_genericNames.contains(value)) return true;
    return RegExp(r'^(一名|一位|某|这个|那个)').hasMatch(value);
  }

  static const _transientRelations = ['对话', '问', '看', '同行', '点头', '相遇'];
  static const _durableRelations = [
    '父',
    '母',
    '子',
    '女',
    '兄',
    '弟',
    '姐',
    '妹',
    '祖',
    '孙',
    '夫妻',
    '恋人',
    '恋爱',
    '情侣',
    '婚',
    '亲属',
    '同宗',
    '师生',
    '师徒',
    '主从',
    '君臣',
    '同僚',
    '朋友',
    '盟友',
    '对手',
    '敌对',
    '雇佣',
    '上下级',
    '同学',
    '同桌',
    '同事',
    '搭档',
    '队友',
    '导师',
    '老师',
    '启蒙老师',
    '战友',
    '师兄',
    '师姐',
    '战友',
  ];
  static const _explicitRelationTerms = [
    '父亲',
    '母亲',
    '儿子',
    '女儿',
    '兄长',
    '兄弟',
    '姐妹',
    '祖父',
    '孙儿',
    '夫妻',
    '恋人',
    '恋爱',
    '情侣',
    '妻子',
    '丈夫',
    '同宗',
    '师父',
    '弟子',
    '同僚',
    '盟友',
    '敌人',
    '对手',
    '仇人',
    '上司',
    '下属',
    '主人',
    '仆从',
    '同学',
    '同桌',
    '同事',
    '搭档',
    '队友',
    '老师',
    '导师',
    '启蒙老师',
    '师兄',
    '师姐',
  ];
}
