import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_skills.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/language_models.dart';
import 'package:uuid/uuid.dart';

enum AiProviderRole {
  general,
  localExtraction,
  cloudExtraction,
  cloudVerification,
}

enum AiFallbackPolicy { none, configuredProvider, confirmBeforeFullTextCloud }

enum AiOutputKind { text, json }

class AiOutputContract {
  const AiOutputContract({
    this.kind = AiOutputKind.text,
    this.schemaVersion = 1,
  });

  const AiOutputContract.text() : this();

  const AiOutputContract.json({int schemaVersion = 1})
    : this(kind: AiOutputKind.json, schemaVersion: schemaVersion);

  final AiOutputKind kind;
  final int schemaVersion;
}

class AiSourceScope {
  const AiSourceScope({
    this.bookId,
    this.chapterHref,
    this.chapterRefs = const [],
    this.safeBoundary,
  });

  final int? bookId;
  final String? chapterHref;
  final List<String> chapterRefs;
  final double? safeBoundary;
}

class AiTraceContext {
  AiTraceContext({
    String? requestId,
    required this.workloadId,
    this.taskId,
    this.sessionId,
    this.bookId,
  }) : requestId = requestId ?? const Uuid().v4();

  final String requestId;
  final String workloadId;
  final String? taskId;
  final String? sessionId;
  final int? bookId;
}

class AiRequest {
  AiRequest({
    required this.messages,
    String? workloadId,
    AiTraceContext? trace,
    this.contextTask = AiContextTask.general,
    this.providerId,
    this.providerRole = AiProviderRole.general,
    this.sourceScope,
    this.outputContract = const AiOutputContract.text(),
    this.fallbackPolicy = AiFallbackPolicy.configuredProvider,
    this.overrideConfig,
    this.regenerate = false,
    this.useAgent = false,
    this.ref,
    this.readingMode,
    this.readingSkill,
  }) : workloadId = workloadId ?? _defaultWorkload(contextTask),
       trace =
           trace ??
           AiTraceContext(
             workloadId: workloadId ?? _defaultWorkload(contextTask),
             bookId: sourceScope?.bookId,
           );

  final List<ChatMessage> messages;
  final String workloadId;
  final AiTraceContext trace;
  final AiContextTask contextTask;
  final String? providerId;
  final AiProviderRole providerRole;
  final AiSourceScope? sourceScope;
  final AiOutputContract outputContract;
  final AiFallbackPolicy fallbackPolicy;
  final Map<String, String>? overrideConfig;
  final bool regenerate;
  final bool useAgent;
  final WidgetRef? ref;
  final ReadingAiMode? readingMode;
  final ReadingSkillSelection? readingSkill;

  bool get allowAutomaticFallback =>
      fallbackPolicy == AiFallbackPolicy.configuredProvider;

  static String _defaultWorkload(AiContextTask task) => switch (task) {
    AiContextTask.readingChat => 'reading.chat',
    AiContextTask.translation => 'translation.selection',
    AiContextTask.chapterReview => 'reading.chapter_review',
    AiContextTask.fictionBackfill => 'fiction.story_atlas',
    AiContextTask.noteOrganizer => 'reading_note.organize',
    AiContextTask.expertAnalysis => 'reading.analysis',
    AiContextTask.lightweightExtraction => 'extraction.lightweight',
    AiContextTask.cloudVerification => 'extraction.cloud_verification',
    AiContextTask.internalSummary => 'context.rolling_summary',
    AiContextTask.bookContext => 'context.book_pack_generate',
    AiContextTask.general => 'ai.general',
  };
}

class AiResponseMetadata {
  const AiResponseMetadata({
    required this.requestId,
    required this.workloadId,
    this.providerId,
    this.model,
    this.deployment,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.usageEstimated = false,
    this.elapsed = Duration.zero,
    this.retryCount = 0,
    this.usedFallback = false,
    this.validationErrors = const [],
    this.finishReason,
  });

  final String requestId;
  final String workloadId;
  final String? providerId;
  final String? model;
  final AiProviderDeployment? deployment;
  final int inputTokens;
  final int outputTokens;
  final bool usageEstimated;
  final Duration elapsed;
  final int retryCount;
  final bool usedFallback;
  final List<String> validationErrors;
  final FinishReason? finishReason;
}

class AiRequestMetrics {
  int inputTokens = 0;
  int outputTokens = 0;
  bool usageEstimated = false;
  int retryCount = 0;
  FinishReason? finishReason;

  void addUsage({
    required int inputTokens,
    required int outputTokens,
    required bool estimated,
  }) {
    this.inputTokens += inputTokens;
    this.outputTokens += outputTokens;
    usageEstimated = usageEstimated || estimated;
  }
}

class AiStreamResult {
  const AiStreamResult({required this.stream, required this.metadata});

  final Stream<String> stream;
  final Future<AiResponseMetadata> metadata;
}

class AiWorkloadDescriptor {
  const AiWorkloadDescriptor({
    required this.id,
    required this.contextTask,
    this.providerRole = AiProviderRole.general,
    this.outputContract = const AiOutputContract.text(),
    this.fallbackPolicy = AiFallbackPolicy.configuredProvider,
    this.allowsTools = false,
    this.allowsWebSearch = false,
    this.pipelineVersion = 1,
  });

  final String id;
  final AiContextTask contextTask;
  final AiProviderRole providerRole;
  final AiOutputContract outputContract;
  final AiFallbackPolicy fallbackPolicy;
  final bool allowsTools;
  final bool allowsWebSearch;
  final int pipelineVersion;
}

abstract final class AiWorkloadDescriptorRegistry {
  static const descriptors = <String, AiWorkloadDescriptor>{
    'reading.chat': AiWorkloadDescriptor(
      id: 'reading.chat',
      contextTask: AiContextTask.readingChat,
      allowsTools: true,
    ),
    'reading.analysis': AiWorkloadDescriptor(
      id: 'reading.analysis',
      contextTask: AiContextTask.expertAnalysis,
      allowsWebSearch: true,
    ),
    'translation.selection': AiWorkloadDescriptor(
      id: 'translation.selection',
      contextTask: AiContextTask.translation,
    ),
    'fiction.story_atlas': AiWorkloadDescriptor(
      id: 'fiction.story_atlas',
      contextTask: AiContextTask.fictionBackfill,
      outputContract: AiOutputContract.json(),
      fallbackPolicy: AiFallbackPolicy.confirmBeforeFullTextCloud,
    ),
    'wiki.book_generate': AiWorkloadDescriptor(
      id: 'wiki.book_generate',
      contextTask: AiContextTask.fictionBackfill,
      outputContract: AiOutputContract.json(),
      fallbackPolicy: AiFallbackPolicy.confirmBeforeFullTextCloud,
    ),
    'context.rolling_summary': AiWorkloadDescriptor(
      id: 'context.rolling_summary',
      contextTask: AiContextTask.internalSummary,
      providerRole: AiProviderRole.localExtraction,
      fallbackPolicy: AiFallbackPolicy.none,
    ),
    'context.book_pack_generate': AiWorkloadDescriptor(
      id: 'context.book_pack_generate',
      contextTask: AiContextTask.bookContext,
      outputContract: AiOutputContract.json(),
      fallbackPolicy: AiFallbackPolicy.confirmBeforeFullTextCloud,
      pipelineVersion: 1,
    ),
    'reading_memory.topic_extraction': AiWorkloadDescriptor(
      id: 'reading_memory.topic_extraction',
      contextTask: AiContextTask.lightweightExtraction,
      providerRole: AiProviderRole.localExtraction,
      outputContract: AiOutputContract.json(),
      fallbackPolicy: AiFallbackPolicy.none,
    ),
    'reading_note.organize': AiWorkloadDescriptor(
      id: 'reading_note.organize',
      contextTask: AiContextTask.noteOrganizer,
      outputContract: AiOutputContract.json(),
    ),
  };

  static AiWorkloadDescriptor? find(String id) => descriptors[id];
}
