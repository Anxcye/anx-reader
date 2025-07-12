class MD5Statistics {
  final int totalBooks;
  final int booksWithMd5;
  final int booksWithoutMd5;
  final int localFilesCount;
  final int localFilesWithoutMd5;

  MD5Statistics({
    required this.totalBooks,
    required this.booksWithMd5,
    required this.booksWithoutMd5,
    required this.localFilesCount,
    required this.localFilesWithoutMd5,
  });
}