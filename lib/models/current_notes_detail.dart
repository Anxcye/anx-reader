import 'package:anx_reader/models/book.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'current_notes_detail.freezed.dart';

@freezed
abstract class CurrentNotesDetail with _$CurrentNotesDetail {
  const factory CurrentNotesDetail({
    required Book book,
    required int numberOfNotes,
  }) = _CurrentNotesDetail;
}
