import 'package:flutter/material.dart';
import 'package:anx_reader/widgets/book_share/excerpt_share_bottom_sheet.dart';

class ExcerptShareService {
  /// 显示分享书摘底部弹窗
  ///
  /// [context] 上下文
  /// [bookTitle] 书名
  /// [author] 作者
  /// [excerpt] 书摘内容
  /// [chapter] 章节名（可选）
  static Future<void> showShareExcerpt({
    required BuildContext context,
    required String bookTitle,
    required String author,
    required String excerpt,
    String? chapter,
  }) async {
    await showExcerptShareBottomSheet(
      context: context,
      bookTitle: bookTitle,
      author: author,
      excerpt: excerpt,
      chapter: chapter,
    );
  }
}
