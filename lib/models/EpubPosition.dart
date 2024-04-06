// import 'dart:convert';
//
// class String {
//   String? chapterTitle;
//   int? chapterIndex;
//   int? chapterPageIndex;
//   int? chapterLength;
//
//   String(
//       {this.chapterTitle,
//       this.chapterIndex,
//       this.chapterPageIndex,
//       this.chapterLength});
//
//   String.fromMap(Map<String, dynamic> map)
//       : chapterTitle = map['chapter_title'],
//         chapterIndex = map['chapter_index'],
//         chapterPageIndex = map['chapter_pos'],
//         chapterLength = map['chapter_length'];
//
//   String toJson(){
//     return jsonEncode(toMap());
//   }
//
//   Map<String, Object?> toMap() {
//     return {
//       'chapter_title': chapterTitle,
//       'chapter_index': chapterIndex,
//       'chapter_pos': chapterPageIndex,
//       'chapter_length': chapterLength,
//     };
//   }
//
//   @override
//   String toString() {
//     return 'Chapter: $chapterTitle, Index: $chapterIndex, Pos: $chapterPageIndex, Length: $chapterLength';
//   }
// }
