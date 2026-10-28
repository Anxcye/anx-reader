import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/utils/log/common.dart';
import 'package:archive/archive.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as path;

class EpubMetadata {
  const EpubMetadata({
    required this.title,
    required this.author,
    required this.description,
    required this.cover,
  });

  final String title;
  final String author;
  final String description;
  final String cover;
}

Future<EpubMetadata> readEpubMetadata(File file) async {
  final extension = path.extension(file.path).toLowerCase();
  if (extension != '.epub') {
    return _fallbackMetadata(file);
  }

  try {
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final container = archive.findFile('META-INF/container.xml');
    if (container == null) {
      throw const FormatException('Missing EPUB container.xml');
    }

    final containerDoc = html_parser.parse(_archiveText(container));
    final opfPath =
        containerDoc.querySelector('rootfile')?.attributes['full-path'];
    if (opfPath == null || opfPath.isEmpty) {
      throw const FormatException('Missing EPUB package path');
    }

    final opfFile = archive.findFile(opfPath);
    if (opfFile == null) {
      throw FormatException('Missing EPUB package file: $opfPath');
    }

    final opfDoc = html_parser.parse(_archiveText(opfFile));
    final title = opfDoc.querySelector('dc\\:title, title')?.text.trim();
    final author = opfDoc.querySelector('dc\\:creator, creator')?.text.trim();
    final description =
        opfDoc.querySelector('dc\\:description, description')?.text.trim();

    return EpubMetadata(
      title: _metadataValue(title, path.basenameWithoutExtension(file.path)),
      author: _metadataValue(author, 'Unknown'),
      description: description ?? '',
      cover: _findEpubCoverDataUri(archive, opfDoc, opfPath) ?? '',
    );
  } catch (e) {
    AnxLog.warning('EPUB metadata fallback failed: $e');
    return _fallbackMetadata(file);
  }
}

EpubMetadata _fallbackMetadata(File file) {
  return EpubMetadata(
    title: path.basenameWithoutExtension(file.path),
    author: 'Unknown',
    description: '',
    cover: '',
  );
}

String _metadataValue(String? value, String fallback) {
  if (value == null || value.isEmpty) {
    return fallback;
  }
  return value;
}

String _archiveText(ArchiveFile file) {
  final content = file.content;
  if (content is String) {
    return content;
  }
  return utf8.decode(content as List<int>, allowMalformed: true);
}

String? _findEpubCoverDataUri(
  Archive archive,
  dom.Document opfDoc,
  String opfPath,
) {
  final manifestItems = opfDoc.querySelectorAll('manifest item');
  final coverId = opfDoc
      .querySelector('metadata meta[name="cover"]')
      ?.attributes['content'];

  dom.Element? coverItem;
  if (coverId != null && coverId.isNotEmpty) {
    coverItem = manifestItems
        .where((item) => item.attributes['id'] == coverId)
        .firstOrNull;
  }

  coverItem ??= manifestItems.where((item) {
    final properties = item.attributes['properties'] ?? '';
    return properties.split(RegExp(r'\s+')).contains('cover-image');
  }).firstOrNull;

  coverItem ??= manifestItems.where((item) {
    final mediaType = item.attributes['media-type'] ?? '';
    final href = item.attributes['href'] ?? '';
    return mediaType.startsWith('image/') &&
        path.basename(href).toLowerCase().contains('cover');
  }).firstOrNull;

  final href = coverItem?.attributes['href'];
  if (href == null || href.isEmpty) {
    return null;
  }

  final opfDir = path.posix.dirname(opfPath);
  final coverPath = path.posix
      .normalize(opfDir == '.' ? href : path.posix.join(opfDir, href));
  final coverFile = archive.findFile(coverPath);
  if (coverFile == null) {
    return null;
  }

  final mediaType = coverItem?.attributes['media-type'] ?? 'image/jpeg';
  final bytes = coverFile.content as List<int>;
  return 'data:$mediaType;base64,${base64Encode(bytes)}';
}
