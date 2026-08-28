import 'package:anx_reader/config/feature_flags.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/ai/ai_history.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_frameworks.dart';
import 'package:anx_reader/service/ai/reading_experience_profile_service.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/reading_skills.dart';
import 'package:flutter/foundation.dart';

enum AiWorkspaceView { chat, coach, history, sessionDetail, agentsAndSources }

class AiWorkspaceController extends ChangeNotifier {
  AiWorkspaceController({
    required this.bookId,
    this.onClosureModuleChanged,
  })  : mode = Prefs().readingAiModeForBook(bookId),
        analysisDepth = Prefs().readingAnalysisDepthForBook(bookId),
        outputTemplate = Prefs().readingOutputTemplateForBook(bookId),
        readingProfile = readingExperienceProfileService.cached(bookId);

  final int bookId;
  final Future<void> Function(String? moduleId)? onClosureModuleChanged;
  AiWorkspaceView view = AiWorkspaceView.chat;
  ReadingAiMode mode;
  ReadingAnalysisDepth analysisDepth;
  ReadingOutputTemplate outputTemplate;
  ReadingAiMode? suggestedMode;
  ReadingSkillId? get pinnedReadingSkill => Prefs().readingSkillForBook(bookId);
  BookReadingProfile? readingProfile;
  String? get pinnedClosureId =>
      readingProfile?.pinned == true ? readingProfile!.primaryModuleId : null;
  ReadingContextSnapshot? pendingSelection;
  ReadingContextSnapshot? lastSelection;
  AiChatHistoryEntry? selectedSession;
  bool showAllHistory = false;
  String draft = '';
  double chatScrollOffset = 0;
  bool visible = false;
  bool mobileFullscreen = false;

  void show({required bool fullscreen}) {
    visible = true;
    mobileFullscreen = fullscreen;
    notifyListeners();
  }

  void hide() {
    if (!visible) return;
    visible = false;
    mobileFullscreen = false;
    notifyListeners();
  }

  void showChat() => _setView(AiWorkspaceView.chat);
  void showCoach() => _setView(
        FeatureFlags.readingCoach
            ? AiWorkspaceView.coach
            : AiWorkspaceView.chat,
      );
  void showHistory() => _setView(AiWorkspaceView.history);
  void showAgentsAndSources() => _setView(AiWorkspaceView.agentsAndSources);

  void showSessionDetail(AiChatHistoryEntry entry) {
    selectedSession = entry;
    _setView(AiWorkspaceView.sessionDetail);
  }

  void setHistoryScope(bool all) {
    if (showAllHistory == all) return;
    showAllHistory = all;
    notifyListeners();
  }

  void setMode(ReadingAiMode value, {bool persist = true}) {
    if (mode == value &&
        (!persist || Prefs().hasReadingAiModeForBook(bookId))) {
      return;
    }
    mode = value;
    suggestedMode = null;
    if (persist) Prefs().setReadingAiModeForBook(bookId, value);
    notifyListeners();
  }

  void setAnalysisDefaults({
    required ReadingAnalysisDepth depth,
    required ReadingOutputTemplate output,
    bool persist = true,
  }) {
    analysisDepth = depth;
    outputTemplate = output;
    if (persist) {
      Prefs().setReadingAnalysisConfigForBook(
        bookId,
        depth: depth,
        outputTemplate: output,
      );
    }
    notifyListeners();
  }

  void resetAnalysisDefaults() {
    Prefs().clearReadingAnalysisConfigForBook(bookId);
    analysisDepth = Prefs().defaultReadingAnalysisDepth;
    outputTemplate = Prefs().defaultReadingOutputTemplate;
    notifyListeners();
  }

  void setReadingSkill(ReadingSkillId? value) {
    Prefs().setReadingSkillForBook(bookId, value);
    notifyListeners();
  }

  void setReadingProfile(BookReadingProfile value) {
    readingProfile = value;
    notifyListeners();
  }

  Future<void> setClosureModule(String? value) async {
    await onClosureModuleChanged?.call(value);
    readingProfile = readingExperienceProfileService.cached(bookId);
    notifyListeners();
  }

  ReadingAnalysisRequest buildAnalysisRequest({
    ReadingAnalysisDepth? depth,
    ReadingOutputTemplate? output,
    List<ReadingFramework>? frameworks,
    String? readingGoal,
    bool? recommendedAutomatically,
  }) {
    final selectedDepth = depth ?? analysisDepth;
    final snapshot = pendingSelection ?? lastSelection;
    final selectedFrameworks = frameworks ??
        const ReadingFrameworkRecommender().recommend(
          depth: selectedDepth,
          mode: mode,
          readingGoal: readingGoal,
          text: snapshot?.selectedText,
          maxFrameworks: Prefs().readingAnalysisMaxFrameworks,
        );
    return ReadingAnalysisRequest(
      depth: selectedDepth,
      frameworks: selectedFrameworks,
      outputTemplate: output ?? outputTemplate,
      readingGoal: readingGoal?.trim(),
      allowWebSearch: selectedDepth == ReadingAnalysisDepth.research &&
          Prefs().readingResearchWebSearch &&
          Prefs().readingWebSearchConfig.enabled,
      recommendedAutomatically:
          recommendedAutomatically ?? (frameworks == null),
    );
  }

  void suggestMode({
    required String title,
    String? description,
    String? chapterTitle,
    String? excerpt,
  }) {
    final text = '$title ${description ?? ''} ${chapterTitle ?? ''} '
            '${excerpt ?? ''}'
        .toLowerCase();
    ReadingAiMode value = ReadingAiMode.general;
    if (RegExp(r'历史|史记|帝国|王朝|战争|history|dynasty|war').hasMatch(text)) {
      value = ReadingAiMode.history;
    } else if (RegExp(r'心理|情绪|认知|人格|psychology|therapy|emotion')
        .hasMatch(text)) {
      value = ReadingAiMode.psychology;
    } else if (RegExp(r'投资|理财|金融|股票|财务|finance|invest|money').hasMatch(text)) {
      value = ReadingAiMode.finance;
    }
    suggestedMode = value;
    notifyListeners();
  }

  void setSuggestedMode(ReadingAiMode value) {
    if (Prefs().hasReadingAiModeForBook(bookId)) return;
    suggestedMode = value;
    notifyListeners();
  }

  void setPendingSelection(ReadingContextSnapshot snapshot) {
    pendingSelection = snapshot;
    lastSelection = snapshot;
    view = AiWorkspaceView.chat;
    notifyListeners();
  }

  void clearPendingSelection() {
    if (pendingSelection == null) return;
    pendingSelection = null;
    notifyListeners();
  }

  void setDraft(String value) {
    draft = value;
  }

  void setChatScrollOffset(double value) {
    chatScrollOffset = value;
  }

  String buildActionPrompt(SelectionAiAction action) {
    final snapshot = pendingSelection;
    if (snapshot == null) return '';
    final profile = mode.agentProfile;
    final actionInstruction = switch (action) {
      SelectionAiAction.explain => '解释这段内容中的关键概念和论证。',
      SelectionAiAction.summarize => '提炼这段内容的核心观点和结构。',
      SelectionAiAction.contextualize => mode == ReadingAiMode.history
          ? '补充事件时间线、人物关系、时代背景，并联系本书上下文。'
          : '联系本章和全书脉络解释这段内容。',
      SelectionAiAction.factCheck => mode == ReadingAiMode.history
          ? '核查史料出处、时间与相互冲突的说法；没有联网证据时明确说明。'
          : '核查这段内容中的事实、数字和假设；区分证据与观点。',
      SelectionAiAction.analyze => mode == ReadingAiMode.psychology
          ? '解释相关心理学概念，并给出不涉及诊断的反思问题或练习。'
          : mode == ReadingAiMode.finance
              ? '拆解关键假设、计算逻辑、收益与风险，不提供个性化投资指令。'
              : '分析作者的观点、依据、隐含假设与可能反例。',
      SelectionAiAction.translate => '准确翻译并解释难以直译的术语。',
      SelectionAiAction.connectToBook => '联系本章、目录和全书核心观点解释这段内容。',
      SelectionAiAction.addNote => '把这段划线整理为一条简洁笔记。',
      SelectionAiAction.sourceLookup => '查找典籍或可信史料出处，区分原始史料与后世解释。',
      SelectionAiAction.timeline => '生成与这段内容直接相关的事件时间线和人物关系。',
      SelectionAiAction.reflection => '围绕相关心理概念进行不诊断、不评判的反思对话。',
      SelectionAiAction.exercise => '基于这段内容生成安全、可选、可停止的自我练习。',
      SelectionAiAction.validateAssumption => '逐项验证作者的财务假设、数据口径和时效性。',
      SelectionAiAction.calculate => '列出变量、公式和单位，复核这段内容中的计算。',
      SelectionAiAction.riskCheck => '识别下行风险、遗漏情景、利益冲突和适用边界。',
      SelectionAiAction.deepAnalyze => '使用已确认的深度、框架和输出模板分析这段内容。',
    };
    return '''[阅读模式：${mode.name}]
$actionInstruction

书籍：${snapshot.bookTitle ?? ''}${snapshot.author == null ? '' : ' / ${snapshot.author}'}
章节：${snapshot.chapterTitle ?? ''}
阅读位置：${snapshot.progress == null ? '' : '${(snapshot.progress! * 100).toStringAsFixed(1)}%'}
划线：
${snapshot.selectedText ?? ''}

相邻上下文：
${snapshot.surroundingText ?? ''}

回答约束：${profile.safetyPrompt}
优先使用本书工具读取必要信息；不要假装已读取整本书或已完成联网核查。''';
  }

  String buildDeepAnalysisPrompt(ReadingAnalysisRequest request) {
    final snapshot = pendingSelection ?? lastSelection;
    if (snapshot == null) return '';
    final profile = mode.agentProfile;
    return '''[阅读模式：${mode.name}]
${readingAnalysisPrompt(request)}

书籍：${snapshot.bookTitle ?? ''}${snapshot.author == null ? '' : ' / ${snapshot.author}'}
章节：${snapshot.chapterTitle ?? ''}
阅读位置：${snapshot.progress == null ? '' : '${(snapshot.progress! * 100).toStringAsFixed(1)}%'}
划线：
${snapshot.selectedText ?? ''}

相邻上下文：
${snapshot.surroundingText ?? ''}

回答约束：${profile.safetyPrompt}
优先使用本书工具读取必要信息；不要假装已读取整本书。''';
  }

  void _setView(AiWorkspaceView value) {
    if (view == value) return;
    view = value;
    notifyListeners();
  }
}
