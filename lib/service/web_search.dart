enum WebSearchEngine {
  google('google', 'Google'),
  baidu('baidu', '百度'),
  sogou('sogou', '搜狗'),
  sohu('sohu', '搜狐'),
  bing('bing', 'Bing');

  const WebSearchEngine(this.code, this.label);

  final String code;
  final String label;

  Uri buildSearchUri(String query) {
    return switch (this) {
      WebSearchEngine.google =>
        Uri.https('www.google.com', '/search', {'q': query}),
      WebSearchEngine.baidu => Uri.https('www.baidu.com', '/s', {'wd': query}),
      WebSearchEngine.sogou =>
        Uri.https('www.sogou.com', '/web', {'query': query}),
      WebSearchEngine.sohu =>
        Uri.https('search.sohu.com', '/', {'keyword': query}),
      WebSearchEngine.bing =>
        Uri.https('www.bing.com', '/search', {'q': query}),
    };
  }

  static WebSearchEngine fromCode(String? code) {
    return WebSearchEngine.values.firstWhere(
      (engine) => engine.code == code,
      orElse: () => WebSearchEngine.bing,
    );
  }
}
