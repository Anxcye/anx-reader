String generateNestedToc(List<String> chapters) {
  List<_TocItem> tocItems = [];

  for (int i = 0; i < chapters.length; i++) {
    String title = chapters[i].split('\n').first;
    int level = title.indexOf(RegExp(r'[^#]'));
    String cleanTitle = title.replaceAll(RegExp(r'^[#]+\s*'), '');
    if (cleanTitle.isEmpty) {
      cleanTitle = title.length > 10 ? title.substring(0, 10) : title;
    }
    tocItems.add(_TocItem(i, level, cleanTitle));
  }

  while (tocItems.every((item) => item.level > 1 || item.level == 0)) {
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
  final int index;
  int level;
  final String title;

  _TocItem(this.index, this.level, this.title);
}
