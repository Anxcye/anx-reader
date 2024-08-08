class BookNote{
  int? id;
  int bookId;
  String content;
  String cfi;
  String chapter;
  String type;
  String color;
  DateTime? createTime;
  DateTime updateTime;

  void setId(int id) {
    this.id = id;
  }

  BookNote({
    this.id,
    required this.bookId,
    required this.content,
    required this.cfi,
    required this.chapter,
    required this.type,
    required this.color,
    this.createTime,
    required this.updateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'content': content,
      'cfi': cfi,
      'chapter': chapter,
      'type': type,
      'color': color,
      'create_time': createTime?.toIso8601String(),
      'update_time': updateTime.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note': content,
      'value': cfi,
      'type': type,
      'color': '#$color',
    };
  }

}