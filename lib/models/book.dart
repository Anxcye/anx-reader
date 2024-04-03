import 'package:anx_reader/models/EpubPosition.dart';

class Book {
  int id;
  String title;
  String coverPath;
  String filePath;
  EpubPosition lastReadPosition;
  String author;
  String? description;
  DateTime createTime;
  DateTime updateTime;

  Book(
      {required this.id,
      required this.title,
      required this.coverPath,
      required this.filePath,
      required this.lastReadPosition,
      required this.author,
      this.description,
      required this.createTime,
      required this.updateTime});

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'cover_path': coverPath,
      'file_path': filePath,
      'last_read_position': lastReadPosition.toJson(),
      'author': author,
      'description': description,
      'create_time': createTime.toIso8601String(),
      'update_time': updateTime.toIso8601String(),
    };
  }

}