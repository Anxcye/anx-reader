String? deriveOpenAiBaseUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return url.trim();
  }

  final removableSegments = {
    'chat',
    'messages',
    'completions',
    'responses',
    'invoke',
    'openai',
  };

  final segments = uri.pathSegments.toList(growable: true);
  while (segments.isNotEmpty &&
      removableSegments.contains(segments.last.toLowerCase())) {
    segments.removeLast();
  }

  final cleaned = uri.replace(pathSegments: segments);
  final base = cleaned.toString();
  if (base.endsWith('/')) {
    return base.substring(0, base.length - 1);
  }
  return base;
}

Uri buildOpenAiModelsUrl(String url) {
  final base = deriveOpenAiBaseUrl(url) ?? url.trim();
  return Uri.parse(base.endsWith('/') ? '${base}models' : '$base/models');
}
