import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/widgets/book_item.dart';
import 'package:flutter/material.dart';

class BookList extends StatelessWidget {
  const BookList({
    super.key,
    required List<Book> books,
    required this.onRefresh,
  }) : _books = books;

  final List<Book> _books;
  final Future<void> Function() onRefresh;
  // import 'package:flutter/material.dart';

// class Book {
//   final String id;
//   final String title;
//   Color color;

//   Book({required this.id, required this.title, required this.color});
// }

// class Folder {
//   final String id;
//   final List<Book> books;

//   Folder({required this.id, required this.books});
// }

// class DraggableBookGrid extends StatefulWidget {
//   @override
//   _DraggableBookGridState createState() => _DraggableBookGridState();
// }

// class _DraggableBookGridState extends State<DraggableBookGrid> {
//   List<dynamic> items = [];

//   @override
//   void initState() {
//     super.initState();
//     // 初始化一些书籍
//     items = [
//       Book(id: '1', title: '书籍 1', color: Colors.red),
//       Book(id: '2', title: '书籍 2', color: Colors.blue),
//       Book(id: '3', title: '书籍 3', color: Colors.green),
//       Book(id: '4', title: '书籍 4', color: Colors.yellow),
//     ];
//   }

//   void _mergeBooks(int targetIndex, Book draggedBook) {
//     setState(() {
//       if (items[targetIndex] is Book) {
//         Book targetBook = items[targetIndex] as Book;
//         Folder newFolder = Folder(
//           id: '${targetBook.id}_${draggedBook.id}',
//           books: [targetBook, draggedBook],
//         );
//         items[targetIndex] = newFolder;
//         items.removeWhere((item) => item.id == draggedBook.id);
//       } else if (items[targetIndex] is Folder) {
//         Folder targetFolder = items[targetIndex] as Folder;
//         targetFolder.books.add(draggedBook);
//         items.removeWhere((item) => item.id == draggedBook.id);
//       }
//     });
//   }

Widget _buildDragbleBook(Book item) {
  return LongPressDraggable<Book>(
    data: item,
    feedback: BookItem(book: item, onRefresh: onRefresh, height: 200),
    child: BookItem(book: item, onRefresh: onRefresh, height: 200),
  );
}

  Widget _buildDragTarget(dynamic item, int index) {
    Widget bookItem = _buildDragbleBook(item);
    Widget folderItem = Container();
    return DragTarget<Book>(
      builder: (context, candidateData, rejectedData) {
        return item is Book ? bookItem : folderItem;
      },
    );
  }

//   Widget _buildGridItem(dynamic item, {bool isDragging = false}) {
//     if (item is Book) {
//       return Container(
//         margin: EdgeInsets.all(4),
//         decoration: BoxDecoration(
//           color: item.color.withOpacity(isDragging ? 0.5 : 1.0),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Center(
//           child: Text(item.title, style: TextStyle(color: Colors.white)),
//         ),
//       );
//     } else if (item is Folder) {
//       return Container(
//         margin: EdgeInsets.all(4),
//         decoration: BoxDecoration(
//           color: Colors.brown.withOpacity(isDragging ? 0.5 : 1.0),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Center(
//           child: Text('文件夹 (${item.books.length})', style: TextStyle(color: Colors.white)),
//         ),
//       );
//     }
//     return Container();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GridView.builder(
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         childAspectRatio: 1.0,
//       ),
//       itemCount: items.length,
//       itemBuilder: (context, index) {
//         return DragTarget<Book>(
//           builder: (context, candidateData, rejectedData) {
//             return _buildDraggable(items[index], index);
//           },
//           onWillAccept: (data) => data != null && data != items[index],
//           onAccept: (data) {
//             _mergeBooks(index, data);
//           },
//         );
//       },
//     );
//   }
// }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        itemCount: _books.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.maxWidth ~/ 110,
          childAspectRatio: 0.55,
          mainAxisSpacing: 30,
          crossAxisSpacing: 20,
        ),
        itemBuilder: (BuildContext context, int index) {
          Book book = _books[index];
          final item = book;
          // return BookItem(book: book, onRefresh: onRefresh);\
          return  _buildDragTarget(item, index);
        },
      );
    });
  }
}
