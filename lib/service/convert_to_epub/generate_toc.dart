import 'package:anx_reader/service/convert_to_epub/section.dart';

String generateNestedToc(List<Section> sections) {
  final tocItems = sections
      .map((s) => _TocItem(
            title: s.title.isNotEmpty ? s.title : s.content.trim().split('\n').first,
            index: sections.indexOf(s),
            level: s.level,
          ))
      .toList();

  while (tocItems.every((item) => item.level > 1 || item.level == 0) &&
      tocItems.any((item) => item.level != 0)) {
    for (int i = 0; i < tocItems.length; i++) {
      tocItems[i].level = tocItems[i].level == 0 ? 0 : tocItems[i].level - 1;
    }
  }

  String buildNavPoints(
    List<_TocItem> items,
    int currentLevel,
    int startIndex,
  ) {
    StringBuffer result = StringBuffer();

    for (int i = startIndex; i < items.length; i++) {
      var item = items[i];

      if (item.level == 0) {
        result.writeln('''
    <navPoint id="${item.index}" playOrder="${item.index}">
      <navLabel><text>${item.title}</text></navLabel>
      <content src="xhtml/${item.index}.xhtml"/>
    </navPoint>''');
        continue;
      }

      if (item.level == currentLevel) {
        result.writeln('''
    <navPoint id="${item.index}" playOrder="${item.index}">
      <navLabel><text>${item.title}</text></navLabel>
      <content src="xhtml/${item.index}.xhtml"/>''');

        int nextIndex = i + 1;
        if (nextIndex < items.length && items[nextIndex].level > currentLevel) {
          result.writeln(buildNavPoints(items, currentLevel + 1, nextIndex));
        }

        result.writeln('    </navPoint>');
      } else if (item.level < currentLevel) {
        break;
      }
    }

    return result.toString();
  }

  return buildNavPoints(tocItems, 1, 0);
}

class _TocItem {
  final String title;
  final int index;
  int level;

  _TocItem({
    required this.title,
    required this.index,
    required this.level,
  });
}
