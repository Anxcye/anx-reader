import 'dart:convert';

import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:anx_reader/service/ai/web_search.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const financeSources = TrustedSourcePack(
    id: 'finance-test',
    mode: ReadingAiMode.finance,
    domains: <String>['sec.gov'],
  );

  test('is disabled by default and does not send a request', () async {
    var requested = false;
    final service = WebSearchService(
      config: const WebSearchProviderConfig.tavily(),
      client: MockClient((_) async {
        requested = true;
        return http.Response('{}', 200);
      }),
    );

    final response = await service.search('market risk');

    expect(response.status, WebSearchStatus.disabled);
    expect(requested, isFalse);
  });

  test('adapts Tavily and strictly filters result domains', () async {
    late http.Request captured;
    final service = WebSearchService(
      config: const WebSearchProviderConfig.tavily(
        enabled: true,
        apiKey: 'tavily-key',
        trustedSources: financeSources,
      ),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'results': <Map<String, dynamic>>[
              <String, dynamic>{
                'title': 'Filing',
                'url': 'https://www.sec.gov/Archives/filing',
                'content': 'Official filing',
                'score': 0.9,
              },
              <String, dynamic>{
                'title': 'Lookalike',
                'url': 'https://sec.gov.attacker.example/phishing',
                'content': 'Untrusted',
              },
              <String, dynamic>{
                'title': 'Insecure',
                'url': 'http://sec.gov/plain-http',
                'content': 'Untrusted transport',
              },
            ],
          }),
          200,
        );
      }),
    );

    final response = await service.search('latest filing');
    final requestBody = jsonDecode(captured.body) as Map<String, dynamic>;

    expect(captured.method, 'POST');
    expect(captured.url.host, 'api.tavily.com');
    expect(requestBody['api_key'], 'tavily-key');
    expect(requestBody['query'], 'latest filing');
    expect(response.status, WebSearchStatus.success);
    expect(response.results, hasLength(1));
    expect(response.results.single.url.host, 'www.sec.gov');
  });

  test('adapts Brave headers and response shape', () async {
    late http.Request captured;
    final service = WebSearchService(
      config: const WebSearchProviderConfig.brave(
        enabled: true,
        apiKey: 'brave-key',
        trustedSources: financeSources,
      ),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'web': <String, dynamic>{
              'results': <Map<String, dynamic>>[
                <String, dynamic>{
                  'title': 'SEC result',
                  'url': 'https://sec.gov/report',
                  'description': 'Official report',
                },
              ],
            },
          }),
          200,
        );
      }),
    );

    final response = await service.search('company report');

    expect(captured.method, 'GET');
    expect(captured.headers['x-subscription-token'], 'brave-key');
    expect(captured.url.queryParameters['q'], 'company report');
    expect(response.results.single.snippet, 'Official report');
  });

  test('built-in providers ignore a stale custom endpoint', () async {
    late http.Request captured;
    final service = WebSearchService(
      config: WebSearchProviderConfig(
        provider: WebSearchProvider.tavily,
        enabled: true,
        apiKey: 'tavily-key',
        endpoint: Uri.parse('https://search.attacker.example/collect'),
        trustedSources: financeSources,
      ),
      client: MockClient((request) async {
        captured = request;
        return http.Response('{"results":[]}', 200);
      }),
    );

    await service.search('sensitive query');

    expect(captured.url, Uri.parse('https://api.tavily.com/search'));
    expect(captured.body, contains('tavily-key'));
  });

  test('adapts a custom HTTP endpoint', () async {
    late http.Request captured;
    final service = WebSearchService(
      config: WebSearchProviderConfig.custom(
        enabled: true,
        endpoint: Uri.parse('https://search.example/api?locale=en'),
        queryParameter: 'query',
        headers: const <String, String>{'x-client': 'anx'},
        trustedSources: financeSources,
      ),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'Investor bulletin',
                'link': 'https://sec.gov/bulletin',
                'snippet': 'Bulletin text',
              },
            ],
          }),
          200,
        );
      }),
    );

    final response = await service.search('fund fees');

    expect(captured.url.queryParameters['locale'], 'en');
    expect(captured.url.queryParameters['query'], 'fund fees');
    expect(captured.headers['x-client'], 'anx');
    expect(response.results.single.title, 'Investor bulletin');
  });

  test('returns explicit degradation instead of throwing', () async {
    final failingService = WebSearchService(
      config: const WebSearchProviderConfig.brave(
        enabled: true,
        apiKey: 'brave-key',
        trustedSources: financeSources,
      ),
      client: MockClient((_) async => throw Exception('offline')),
    );
    final untrustedService = WebSearchService(
      config: const WebSearchProviderConfig.brave(
        enabled: true,
        apiKey: 'brave-key',
        trustedSources: financeSources,
      ),
      client: MockClient((_) async => http.Response(
            jsonEncode(<String, dynamic>{
              'web': <String, dynamic>{
                'results': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'title': 'Unknown blog',
                    'url': 'https://example.com/post',
                  },
                ],
              },
            }),
            200,
          )),
    );

    final failed = await failingService.search('query');
    final untrusted = await untrustedService.search('query');

    expect(failed.status, WebSearchStatus.degraded);
    expect(
      failed.degradationReason,
      WebSearchDegradationReason.networkError,
    );
    expect(untrusted.status, WebSearchStatus.degraded);
    expect(
      untrusted.degradationReason,
      WebSearchDegradationReason.noTrustedResults,
    );
    expect(untrusted.results, isEmpty);
  });

  test('degrades when a provider response has no result list', () async {
    final service = WebSearchService(
      config: const WebSearchProviderConfig.tavily(
        enabled: true,
        apiKey: 'tavily-key',
        trustedSources: financeSources,
      ),
      client: MockClient((_) async => http.Response('{"answer":"none"}', 200)),
    );

    final response = await service.search('query');

    expect(response.status, WebSearchStatus.degraded);
    expect(
      response.degradationReason,
      WebSearchDegradationReason.invalidResponse,
    );
  });
}
