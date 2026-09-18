import 'package:flutter_test/flutter_test.dart';
import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/reading_experts.dart';

void main() {
  const registry = ReadingExpertRegistry();

  test('built-in experts use stable ids and are discoverable by mode', () {
    expect(ReadingExpertRegistry.definitions.length, greaterThanOrEqualTo(10));
    expect(
        ReadingExpertRegistry.definitions.map((item) => item.id).toSet().length,
        ReadingExpertRegistry.definitions.length);
    expect(registry.forMode(ReadingAiMode.history), isNotEmpty);
    expect(registry.get('expert.fiction.narrative')?.title, '小说叙事与人物');
  });

  test('unknown expert ids are safely ignored', () {
    expect(registry.get('expert.unknown'), isNull);
    expect(registry.search('科幻').map((item) => item.id),
        contains('expert.scifi.worldbuilding'));
  });
}
