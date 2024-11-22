import 'package:anx_reader/utils/get_path/get_base_path.dart';

class Book {
  int id;
  String title;
  String coverPath;
  String filePath;
  String lastReadPosition;
  double readingPercentage;
  String author;
  bool isDeleted;
  String? description;
  double rating;
  int groupId;
  DateTime createTime;
  DateTime updateTime;

  Book(
      {required this.id,
      required this.title,
      required this.coverPath,
      required this.filePath,
      required this.lastReadPosition,
      required this.readingPercentage,
      required this.author,
      required this.isDeleted,
      this.description,
      required this.rating,
      this.groupId = 0,
      required this.createTime,
      required this.updateTime});

  String get coverFullPath {
    return getBasePath(coverPath);
  }
  String get fileFullPath {
    return getBasePath(filePath);
  }


  Map<String, Object?> toMap() {
    return {
      'title': title,
      'cover_path': coverPath,
      'file_path': filePath,
      'last_read_position': lastReadPosition,
      'reading_percentage': readingPercentage,
      'author': author,
      'is_deleted': isDeleted ? 1 : 0,
      'description': description,
      'rating': rating,
      'group_id': groupId,
      'create_time': createTime.toIso8601String(),
      'update_time': updateTime.toIso8601String(),
    };
  }

  Book copyWith({
    int? id,
    String? title,
    String? coverPath,
    String? filePath,
    String? lastReadPosition,
    double? readingPercentage,
    String? author,
    bool? isDeleted,
    String? description,
    double? rating,
    int? groupId,
    DateTime? createTime,
    DateTime? updateTime,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      coverPath: coverPath ?? this.coverPath,
      filePath: filePath ?? this.filePath,
      lastReadPosition: lastReadPosition ?? this.lastReadPosition,
      readingPercentage: readingPercentage ?? this.readingPercentage,
      author: author ?? this.author,
      isDeleted: isDeleted ?? this.isDeleted,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      groupId: groupId ?? this.groupId,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
    );
  }
}
