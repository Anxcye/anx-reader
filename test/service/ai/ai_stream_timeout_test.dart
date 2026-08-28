import 'package:anx_reader/service/ai/index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI stream uses a bounded default timeout', () {
    expect(effectiveAiStreamTimeout(0), const Duration(seconds: 60));
  });

  test('AI stream honors a provider-specific timeout', () {
    expect(effectiveAiStreamTimeout(15), const Duration(seconds: 15));
  });
}
