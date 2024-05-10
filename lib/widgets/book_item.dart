import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/service/book.dart';
import 'package:flutter/material.dart';

import '../models/book.dart';
import '../page/book_detail.dart';

class BookItem extends StatelessWidget {
  const BookItem({
    super.key,
    required this.book,
    required this.onRefresh,
  });

  final Book book;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openBook(context, book, onRefresh);
      },
      onLongPress: () {
        handleLongPress(context);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  width: 0.3,
                  color: Colors.grey,
                ),
                image: DecorationImage(
                  image:
                      Image.memory(File(book.coverFullPath).readAsBytesSync())
                          .image,
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            book.author,
            style: const TextStyle(
                fontWeight: FontWeight.w300,
                fontSize: 9,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Future<dynamic> handleLongPress(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.all(20),
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    handleDetail(context);
                  },
                  child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.details),
                      const Spacer(),
                      Text(context.notesPageDetail),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    handleDelete(context);
                  },
                  child: Column(
                    // mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete),
                      Spacer(),
                      Text(context.commonDelete),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  void handleDelete(BuildContext context) {
    Navigator.pop(context);
    updateBook(Book(
      id: book.id,
      title: book.title,
      coverPath: book.coverPath,
      filePath: book.filePath,
      lastReadPosition: book.lastReadPosition,
      readingPercentage: book.readingPercentage,
      author: '',
      isDeleted: true,
      description: book.description,
      rating: 0.0,
      createTime: book.createTime,
      updateTime: DateTime.now(),
    ));
    onRefresh();
    File(book.fileFullPath).delete();
  }

  void handleDetail(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetail(book: book, onRefresh: onRefresh),
      ),
    );
  }
}
