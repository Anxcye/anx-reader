import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Prefs().prefs = await SharedPreferences.getInstance();
  });

  test('deep-reading preferences use safe defaults and persist', () {
    expect(
      Prefs().defaultReadingAnalysisDepth,
      ReadingAnalysisDepth.standard,
    );
    expect(
      Prefs().defaultReadingOutputTemplate,
      ReadingOutputTemplate.learningNote,
    );
    expect(Prefs().readingAnalysisConfirmBeforeSend, isTrue);
    expect(Prefs().readingResearchWebSearch, isFalse);

    Prefs().defaultReadingAnalysisDepth = ReadingAnalysisDepth.deep;
    Prefs().defaultReadingOutputTemplate = ReadingOutputTemplate.conceptMap;
    Prefs().readingAnalysisMaxFrameworks = 7;

    expect(Prefs().defaultReadingAnalysisDepth, ReadingAnalysisDepth.deep);
    expect(
      Prefs().defaultReadingOutputTemplate,
      ReadingOutputTemplate.conceptMap,
    );
    expect(Prefs().readingAnalysisMaxFrameworks, 2);
  });

  test('reading agent beta is opt-in', () {
    expect(Prefs().readingAgentBetaEnabled, isFalse);
    Prefs().readingAgentBetaEnabled = true;
    expect(Prefs().readingAgentBetaEnabled, isTrue);
  });

  test('book override can be applied and removed without changing globals', () {
    Prefs().defaultReadingAnalysisDepth = ReadingAnalysisDepth.standard;
    Prefs().defaultReadingOutputTemplate = ReadingOutputTemplate.learningNote;

    Prefs().setReadingAnalysisConfigForBook(
      9,
      depth: ReadingAnalysisDepth.research,
      outputTemplate: ReadingOutputTemplate.argumentAnalysis,
    );

    expect(Prefs().hasReadingAnalysisConfigForBook(9), isTrue);
    expect(
      Prefs().readingAnalysisDepthForBook(9),
      ReadingAnalysisDepth.research,
    );
    expect(
      Prefs().readingOutputTemplateForBook(9),
      ReadingOutputTemplate.argumentAnalysis,
    );

    Prefs().clearReadingAnalysisConfigForBook(9);

    expect(Prefs().hasReadingAnalysisConfigForBook(9), isFalse);
    expect(
      Prefs().readingAnalysisDepthForBook(9),
      ReadingAnalysisDepth.standard,
    );
  });
}
