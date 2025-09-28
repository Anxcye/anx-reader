import 'package:anx_reader/models/chapter_split_rule.dart';

const String kDefaultChapterSplitRuleId = 'default_chapter_rule';

final List<ChapterSplitRule> builtinChapterSplitRules = [
  ChapterSplitRule(
    id: kDefaultChapterSplitRuleId,
    name: 'Default (mixed languages)',
    pattern:
        r'^(?:(.+ +)|())(第[一二三四五六七八九十零〇百千万两0123456789]+[章卷]|卷[一二三四五六七八九十零〇百千万两0123456789]+|chap(?:ter)\.?|vol(?:ume)?\.?|book|bk)(?:(?: +.+)?|(?:\S.*)?)$',
    samples: [
      '第一章 起始之地',
      '第十二卷 风云再起',
      'Chapter 12: The Journey',
      'chap 3. another life',
      'Book 1 - Dawn of Era',
      'Vol.2 A new world',
      'bk 4 - outside sample',
    ],
    isBuiltin: true,
    caseSensitive: false,
    multiLine: true,
  ),
  ChapterSplitRule(
    id: 'cn_only_numeric',
    name: 'Chinese (第X章)',
    pattern: r'^\s*第[一二三四五六七八九十零〇百千万两0123456789]+章(?:[ ：:.-].*)?$',
    samples: [
      '第一章 少年出山',
      '第二十章 ：终极之战',
      '第3章- 遗失的记忆',
      '第四卷 序章',
    ],
    isBuiltin: true,
    caseSensitive: false,
    multiLine: true,
  ),
  ChapterSplitRule(
    id: 'en_chapter_number',
    name: 'English (Chapter N)',
    pattern: r'^\s*chapter\s+\d+(?:[ .:-].*)?$',
    samples: [
      'Chapter 1: Beginning',
      'chapter 23 - A twist',
      'CHAPTER 99. Finale',
      'chapter one',
    ],
    isBuiltin: true,
    caseSensitive: false,
    multiLine: true,
  ),
  ChapterSplitRule(
    id: 'en_volume_number',
    name: 'English (Volume/Book)',
    pattern: r'^\s*(volume|book)\s+\d+(?:[ .:-].*)?$',
    samples: [
      'Volume 1: Arrival',
      'Book 2 - Secrets',
      'volume 03 introduction',
      'vol. 4',
    ],
    isBuiltin: true,
    caseSensitive: false,
    multiLine: true,
  ),
];

ChapterSplitRule getDefaultChapterSplitRule() {
  return builtinChapterSplitRules.firstWhere(
    (rule) => rule.id == kDefaultChapterSplitRuleId,
  );
}

ChapterSplitRule? findBuiltinChapterSplitRuleById(String id) {
  try {
    return builtinChapterSplitRules.firstWhere((rule) => rule.id == id);
  } catch (_) {
    return null;
  }
}
