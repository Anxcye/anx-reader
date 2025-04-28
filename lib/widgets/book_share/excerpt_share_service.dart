import 'package:flutter/material.dart';
import 'package:anx_reader/widgets/book_share/excerpt_share_bottom_sheet.dart';

class ExcerptShareService {
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
