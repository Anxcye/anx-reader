import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/service/ai/book_wiki_service.dart';

class BookWikiExportService {
  const BookWikiExportService();

  String toMarkdown(Book book, BookWikiSnapshot snapshot) {
    final buffer = StringBuffer('# ${book.title}\n\n');
    if (book.author.trim().isNotEmpty) buffer.writeln('作者：${book.author}\n');
    const order = <String, String>{
      BookWikiEntryKinds.overview: '简介',
      BookWikiEntryKinds.part: '篇章',
      BookWikiEntryKinds.chapter: '章节',
      BookWikiEntryKinds.concept: '核心概念',
      BookWikiEntryKinds.method: '阅读方法',
      BookWikiEntryKinds.argument: '主要观点',
      BookWikiEntryKinds.character: '主要人物',
      BookWikiEntryKinds.relationship: '人物关系',
      BookWikiEntryKinds.event: '重要事件',
      BookWikiEntryKinds.theme: '核心主题',
      BookWikiEntryKinds.question: '未解决问题',
      BookWikiEntryKinds.memory: '阅读成果',
    };
    for (final section in order.entries) {
      final entries = snapshot.sections[section.key] ?? const [];
      if (entries.isEmpty) continue;
      buffer.writeln('## ${section.value}\n');
      for (final entry in entries) {
        buffer.writeln('### ${entry.title}\n');
        buffer.writeln(
            '${entry.contentMarkdown.isEmpty ? entry.summary : entry.contentMarkdown}\n');
        buffer.writeln(
            '> ${entry.epistemicStatus == 'agentInference' ? 'AI 推断' : '文本事实/用户内容'}');
        for (final source in entry.sources) {
          final title = source.chapterTitle?.trim();
          if (title?.isNotEmpty == true) buffer.writeln('> 来源：$title');
        }
        buffer.writeln();
      }
    }
    return buffer.toString().trimRight();
  }
}

const bookWikiExportService = BookWikiExportService();
