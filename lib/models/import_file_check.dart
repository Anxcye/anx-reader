import 'package:anx_reader/models/book.dart';

class ImportFileCheck {
  final String filePath;
  final String? md5;
  final bool isDuplicate;
  final Book? duplicateBook;

  ImportFileCheck({
    required this.filePath,
    required this.md5,
    required this.isDuplicate,
    this.duplicateBook,
  });
}
