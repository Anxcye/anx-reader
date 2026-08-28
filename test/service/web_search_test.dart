import 'package:anx_reader/service/web_search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds an encoded search URL for every engine', () {
    for (final engine in WebSearchEngine.values) {
      final uri = engine.buildSearchUri('role self & identity');

      expect(uri.scheme, 'https');
      expect(uri.query, isNot(contains(' ')));
      expect(uri.queryParameters.values, contains('role self & identity'));
    }
  });

  test('restores a saved engine and falls back to Bing', () {
    expect(WebSearchEngine.fromCode('baidu'), WebSearchEngine.baidu);
    expect(WebSearchEngine.fromCode('unknown'), WebSearchEngine.bing);
    expect(WebSearchEngine.fromCode(null), WebSearchEngine.bing);
  });
}
