import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark.freezed.dart';
part 'bookmark.g.dart';

@freezed
abstract class BookmarkModel with _$BookmarkModel {
  const factory BookmarkModel({
    int? id,
    required int bookId,
    required String content,
    required String cfi,
    required String chapter,
    required double percentage,
    DateTime? createTime,
    required DateTime updateTime,
  }) = _BookmarkModel;

  factory BookmarkModel.fromJson(Map<String, dynamic> json) =>
      _$BookmarkModelFromJson(json);
}

extension BookmarkModelExtension on BookmarkModel {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'content': content,
      'cfi': cfi,
      'chapter': chapter,
      'type': 'bookmark',
      'color': percentage,
      'reader_note': 'None',
      'create_time': createTime?.toIso8601String(),
      'update_time': updateTime.toIso8601String(),
    };
  }
}