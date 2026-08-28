import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/service/ai/reading_ai_models.dart';
import 'package:http/http.dart' as http;

enum WebSearchProvider { tavily, brave, custom }

class WebSearchProviderConfig {
  const WebSearchProviderConfig({
    required this.provider,
    this.enabled = false,
    this.apiKey,
    this.endpoint,
    this.headers = const <String, String>{},
    this.queryParameter = 'q',
    this.maxResults = 5,
    this.timeout = const Duration(seconds: 12),
    this.trustedSources = TrustedSourcePack.general,
  });

  const WebSearchProviderConfig.tavily({
    this.enabled = false,
    this.apiKey,
    this.endpoint,
    this.headers = const <String, String>{},
    this.maxResults = 5,
    this.timeout = const Duration(seconds: 12),
    this.trustedSources = TrustedSourcePack.general,
  })  : provider = WebSearchProvider.tavily,
        queryParameter = 'query';

  const WebSearchProviderConfig.brave({
    this.enabled = false,
    this.apiKey,
    this.endpoint,
    this.headers = const <String, String>{},
    this.maxResults = 5,
    this.timeout = const Duration(seconds: 12),
    this.trustedSources = TrustedSourcePack.general,
  })  : provider = WebSearchProvider.brave,
        queryParameter = 'q';

  const WebSearchProviderConfig.custom({
    this.enabled = false,
    this.apiKey,
    required this.endpoint,
    this.headers = const <String, String>{},
    this.queryParameter = 'q',
    this.maxResults = 5,
    this.timeout = const Duration(seconds: 12),
    this.trustedSources = TrustedSourcePack.general,
  }) : provider = WebSearchProvider.custom;

  final WebSearchProvider provider;
  final bool enabled;
  final String? apiKey;
  final Uri? endpoint;
  final Map<String, String> headers;
  final String queryParameter;
  final int maxResults;
  final Duration timeout;
  final TrustedSourcePack trustedSources;

  Uri? get effectiveEndpoint {
    switch (provider) {
      case WebSearchProvider.tavily:
        return Uri.parse('https://api.tavily.com/search');
      case WebSearchProvider.brave:
        return Uri.parse('https://api.search.brave.com/res/v1/web/search');
      case WebSearchProvider.custom:
        return endpoint;
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'provider': provider.name,
        'enabled': enabled,
        if (apiKey != null) 'apiKey': apiKey,
        if (endpoint != null) 'endpoint': endpoint.toString(),
        if (headers.isNotEmpty) 'headers': headers,
        'queryParameter': queryParameter,
        'maxResults': maxResults,
        'timeoutMs': timeout.inMilliseconds,
        'trustedSources': trustedSources.toJson(),
      };

  factory WebSearchProviderConfig.fromJson(Map<String, dynamic> json) {
    final providerName = json['provider']?.toString();
    final provider = WebSearchProvider.values.firstWhere(
      (item) => item.name == providerName,
      orElse: () => WebSearchProvider.custom,
    );
    final rawHeaders = json['headers'];
    final headers = <String, String>{};
    if (rawHeaders is Map) {
      for (final entry in rawHeaders.entries) {
        headers[entry.key.toString()] = entry.value.toString();
      }
    }
    final rawSources = json['trustedSources'];

    return WebSearchProviderConfig(
      provider: provider,
      enabled: json['enabled'] == true,
      apiKey: _textOrNull(json['apiKey']),
      endpoint: Uri.tryParse(json['endpoint']?.toString() ?? ''),
      headers: headers,
      queryParameter: _textOrNull(json['queryParameter']) ?? 'q',
      maxResults: _positiveInt(json['maxResults'], fallback: 5),
      timeout: Duration(
        milliseconds: _positiveInt(json['timeoutMs'], fallback: 12000),
      ),
      trustedSources: rawSources is Map
          ? TrustedSourcePack.fromJson(_stringKeyedMap(rawSources))
          : TrustedSourcePack.general,
    );
  }
}

class WebSearchResult {
  const WebSearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.score,
    this.publishedAt,
    this.accessedAt,
  });

  final String title;
  final Uri url;
  final String snippet;
  final double? score;
  final String? publishedAt;
  final int? accessedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'url': url.toString(),
        'snippet': snippet,
        if (score != null) 'score': score,
        if (publishedAt != null) 'publishedAt': publishedAt,
        if (accessedAt != null) 'accessedAt': accessedAt,
      };
}

enum WebSearchStatus { disabled, success, degraded }

enum WebSearchDegradationReason {
  missingConfiguration,
  invalidQuery,
  networkError,
  httpError,
  invalidResponse,
  noTrustedResults,
}

class WebSearchResponse {
  const WebSearchResponse({
    required this.status,
    required this.provider,
    this.results = const <WebSearchResult>[],
    this.degradationReason,
    this.detail,
  });

  final WebSearchStatus status;
  final WebSearchProvider provider;
  final List<WebSearchResult> results;
  final WebSearchDegradationReason? degradationReason;
  final String? detail;

  bool get isSuccess => status == WebSearchStatus.success;
  bool get isDegraded => status == WebSearchStatus.degraded;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'status': status.name,
        'provider': provider.name,
        'results': results.map((result) => result.toJson()).toList(),
        if (degradationReason != null)
          'degradationReason': degradationReason!.name,
        if (detail != null) 'detail': detail,
      };
}

class WebSearchService {
  WebSearchService({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final WebSearchProviderConfig config;
  final http.Client _client;

  Future<WebSearchResponse> search(String query) async {
    if (!config.enabled) {
      return WebSearchResponse(
        status: WebSearchStatus.disabled,
        provider: config.provider,
        detail: 'Web search is disabled.',
      );
    }

    if (query.trim().isEmpty) {
      return _degraded(
        WebSearchDegradationReason.invalidQuery,
        'Search query is empty.',
      );
    }

    if (config.effectiveEndpoint == null ||
        config.effectiveEndpoint!.scheme != 'https' ||
        config.trustedSources.domains.isEmpty) {
      return _degraded(
        WebSearchDegradationReason.missingConfiguration,
        'An HTTPS search endpoint and trusted domains must be configured.',
      );
    }

    if (config.provider != WebSearchProvider.custom &&
        (config.apiKey == null || config.apiKey!.trim().isEmpty)) {
      return _degraded(
        WebSearchDegradationReason.missingConfiguration,
        'The selected search provider requires an API key.',
      );
    }

    try {
      final response = await _send(query.trim()).timeout(config.timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _degraded(
          WebSearchDegradationReason.httpError,
          'Search provider returned HTTP ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final candidates = _extractCandidates(decoded);
      if (candidates == null) {
        return _degraded(
          WebSearchDegradationReason.invalidResponse,
          'Search provider response did not contain a result list.',
        );
      }
      final trustedResults = _trustedResults(candidates);
      if (candidates.isNotEmpty && trustedResults.isEmpty) {
        return _degraded(
          WebSearchDegradationReason.noTrustedResults,
          'The provider returned no results from trusted domains.',
        );
      }

      return WebSearchResponse(
        status: WebSearchStatus.success,
        provider: config.provider,
        results: trustedResults,
      );
    } on TimeoutException {
      return _degraded(
        WebSearchDegradationReason.networkError,
        'Search request timed out.',
      );
    } on FormatException {
      return _degraded(
        WebSearchDegradationReason.invalidResponse,
        'Search provider returned invalid JSON.',
      );
    } catch (_) {
      return _degraded(
        WebSearchDegradationReason.networkError,
        'Search provider request failed.',
      );
    }
  }

  Future<http.Response> _send(String query) {
    final endpoint = config.effectiveEndpoint!;
    switch (config.provider) {
      case WebSearchProvider.tavily:
        return _client.post(
          endpoint,
          headers: <String, String>{
            'content-type': 'application/json',
            ...config.headers,
          },
          body: jsonEncode(<String, dynamic>{
            'api_key': config.apiKey,
            'query': query,
            'max_results': config.maxResults,
          }),
        );
      case WebSearchProvider.brave:
        final uri = endpoint.replace(queryParameters: <String, String>{
          ...endpoint.queryParameters,
          'q': query,
          'count': config.maxResults.toString(),
        });
        return _client.get(
          uri,
          headers: <String, String>{
            'accept': 'application/json',
            'x-subscription-token': config.apiKey!,
            ...config.headers,
          },
        );
      case WebSearchProvider.custom:
        final uri = endpoint.replace(queryParameters: <String, String>{
          ...endpoint.queryParameters,
          config.queryParameter: query,
        });
        final headers = <String, String>{
          'accept': 'application/json',
          if (config.apiKey != null && config.apiKey!.trim().isNotEmpty)
            'authorization': 'Bearer ${config.apiKey}',
          ...config.headers,
        };
        return _client.get(uri, headers: headers);
    }
  }

  List<Map<String, dynamic>>? _extractCandidates(Object? decoded) {
    Object? rawResults;
    if (decoded is List) {
      rawResults = decoded;
    } else if (decoded is Map) {
      final root = _stringKeyedMap(decoded);
      if (config.provider == WebSearchProvider.brave && root['web'] is Map) {
        rawResults = _stringKeyedMap(root['web'])['results'];
      } else {
        rawResults = root['results'] ?? root['items'] ?? root['data'];
      }
    }

    if (rawResults is! List) return null;
    return rawResults
        .whereType<Map>()
        .map(_stringKeyedMap)
        .toList(growable: false);
  }

  List<WebSearchResult> _trustedResults(
    List<Map<String, dynamic>> candidates,
  ) {
    final results = <WebSearchResult>[];
    final seen = <String>{};
    for (final candidate in candidates) {
      final rawUrl = candidate['url'] ?? candidate['link'] ?? candidate['href'];
      final uri = Uri.tryParse(rawUrl?.toString() ?? '');
      if (uri == null || !config.trustedSources.trusts(uri)) continue;

      final normalizedUrl = uri.replace(fragment: '').toString();
      if (!seen.add(normalizedUrl)) continue;
      final title =
          _textOrNull(candidate['title'] ?? candidate['name']) ?? uri.host;
      final snippet = _textOrNull(
            candidate['content'] ??
                candidate['description'] ??
                candidate['snippet'],
          ) ??
          '';
      final rawScore = candidate['score'];
      results.add(WebSearchResult(
        title: title,
        url: uri,
        snippet: snippet,
        score: rawScore is num
            ? rawScore.toDouble()
            : double.tryParse(rawScore?.toString() ?? ''),
        publishedAt: _textOrNull(
          candidate['published_date'] ??
              candidate['publishedAt'] ??
              candidate['date'],
        ),
        accessedAt: DateTime.now().millisecondsSinceEpoch,
      ));
      if (results.length >= config.maxResults) break;
    }
    return results;
  }

  WebSearchResponse _degraded(
    WebSearchDegradationReason reason,
    String detail,
  ) {
    return WebSearchResponse(
      status: WebSearchStatus.degraded,
      provider: config.provider,
      degradationReason: reason,
      detail: detail,
    );
  }
}

class TrustedWebSearchService extends WebSearchService {
  TrustedWebSearchService({
    required super.config,
    super.client,
  });
}

Map<String, dynamic> _stringKeyedMap(Object? value) {
  if (value is! Map) return <String, dynamic>{};
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String? _textOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int _positiveInt(Object? value, {required int fallback}) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  return parsed != null && parsed > 0 ? parsed : fallback;
}
