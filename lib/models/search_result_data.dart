import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/search_note_group.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result_data.freezed.dart';

@freezed
abstract class SearchResultData with _$SearchResultData {
  const factory SearchResultData({
    required List<Book> books,
    required List<SearchNoteGroup> noteGroups,
  }) = _SearchResultData;
  static const empty = SearchResultData(books: [], noteGroups: []);
}