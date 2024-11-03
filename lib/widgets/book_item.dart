import 'dart:io';

import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/widgets/book_cover.dart';
import 'package:anx_reader/widgets/delete_confirm.dart';
import 'package:anx_reader/widgets/icon_and_text.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

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
            child: Hero(
              tag: book.coverFullPath,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: bookCover(context, book)),
                  ],
                ),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  book.author,
                  style: const TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 9,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              Text(
                '${(book.readingPercentage * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 9,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
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
            padding: const EdgeInsets.all(20),
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconAndText(
                  icon: const Icon(EvaIcons.more_vertical),
                  text: L10n.of(context).notes_page_detail,
                  onTap: () {
                    handleDetail(context);
                  },
                ),
                const Spacer(),
                DeleteConfirm(
                  delete: () {
                    handleDelete(context);
                  },
                  deleteIcon: iconAndText(
                    icon: const Icon(EvaIcons.trash),
                    text: L10n.of(context).common_delete,
                  ),
                  confirmIcon: iconAndText(
                    icon: const Icon(
                      EvaIcons.checkmark_circle_2,
                      color: Colors.red,
                    ),
                    text: L10n.of(context).common_confirm,
                  ),
                )
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
      author: book.author,
      isDeleted: true,
      description: book.description,
      rating: book.rating,
      createTime: book.createTime,
      updateTime: DateTime.now(),
    ));
    onRefresh();
    File(book.fileFullPath).delete();
    File(book.coverFullPath).delete();
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
