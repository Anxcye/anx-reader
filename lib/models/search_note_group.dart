import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_note_group.freezed.dart';

@freezed
abstract class SearchNoteGroup with _$SearchNoteGroup {
  const factory SearchNoteGroup({
    required Book book,
    required List<BookNote> notes,
  }) = _SearchNoteGroup;
}

