import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/build_chinese_dictionary.dart '
      '<chinese-xinhua/data> <output-directory>',
    );
    exitCode = 64;
    return;
  }

  final source = Directory(args[0]);
  final output = Directory(args[1])..createSync(recursive: true);
  final entries = <String, Map<String, dynamic>>{};

  void addSense(
    String word,
    String definition, {
    String? pinyin,
    String? example,
  }) {
    word = word.trim();
    definition = definition.trim();
    if (word.isEmpty || definition.isEmpty) return;
    final entry = entries.putIfAbsent(
        word,
        () => <String, dynamic>{
              'w': word,
              's': <Map<String, String>>[],
            });
    if (pinyin?.trim().isNotEmpty ?? false) entry['p'] ??= pinyin!.trim();
    final senses = entry['s'] as List<Map<String, String>>;
    for (final part in _splitDefinitions(definition)) {
      if (senses.any((sense) => sense['d'] == part)) continue;
      senses.add({
        'd': part,
        if (example?.trim().isNotEmpty ?? false) 'e': example!.trim(),
      });
    }
  }

  final words = jsonDecode(File('${source.path}/word.json').readAsStringSync());
  for (final item in words as List) {
    addSense(
      item['word']?.toString() ?? '',
      item['explanation']?.toString() ?? '',
      pinyin: item['pinyin']?.toString(),
    );
  }

  final phrases = jsonDecode(File('${source.path}/ci.json').readAsStringSync());
  for (final item in phrases as List) {
    addSense(
      item['ci']?.toString() ?? '',
      item['explanation']?.toString() ?? '',
    );
  }

  final idioms =
      jsonDecode(File('${source.path}/idiom.json').readAsStringSync());
  for (final item in idioms as List) {
    addSense(
      item['word']?.toString() ?? '',
      item['explanation']?.toString() ?? '',
      pinyin: item['pinyin']?.toString(),
      example: item['example']?.toString(),
    );
  }

  final buckets = <String, Map<String, dynamic>>{};
  for (final entry in entries.values) {
    final word = entry['w'] as String;
    final bucket = (word.runes.first >> 8).toRadixString(16).padLeft(2, '0');
    buckets.putIfAbsent(bucket, () => <String, dynamic>{})[word] = entry;
  }

  for (final bucket in buckets.entries) {
    final bytes = utf8.encode(jsonEncode(bucket.value));
    File('${output.path}/${bucket.key}.json.gz')
        .writeAsBytesSync(gzip.encode(bytes));
  }

  stdout.writeln(
    'Built ${entries.length} entries in ${buckets.length} buckets.',
  );
}

List<String> _splitDefinitions(String value) {
  return value
      .replaceAll('\r', '')
      .split(RegExp(r'\n+\s*(?=\d+[.．、])'))
      .map((part) => part.replaceFirst(RegExp(r'^\d+[.．、]\s*'), '').trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}
