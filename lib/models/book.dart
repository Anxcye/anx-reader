class Book {
  late int id;
  late String title;
  late String coverPath;
  late String filePath;
  late String lastReadPosition;
  late String author;
  String? description;

  Book(
      {required this.id,
      required this.title,
      required this.coverPath,
      required this.filePath,
      required this.lastReadPosition,
      required this.author,
      this.description});

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'cover_path': coverPath,
      'file_path': filePath,
      'last_read_position': lastReadPosition,
      'author': author,
      'description': description,
    };
  }
}
