class ReadingTime{
  int? id;
  int bookId;
  String? date;
  int readingTime;

  ReadingTime({
    this.id,
    required this.bookId,
    this.date,
    required this.readingTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'book_id': bookId,
      'date': date,
      'reading_time': readingTime,
    };
  }

}