import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/providers/anx_webdav.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/delete_confirm.dart';
import 'package:anx_reader/widgets/icon_and_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:icons_plus/icons_plus.dart';

class BookBottomSheet extends ConsumerWidget {
  const BookBottomSheet({
    super.key,
    required this.book,
  });

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> handleDelete(BuildContext context) async {
      Navigator.pop(context);
      await updateBook(Book(
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
      ref.read(bookListProvider.notifier).refresh();
      File(book.fileFullPath).delete();
      File(book.coverFullPath).delete();
    }

    void handleDetail(BuildContext context) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetail(book: book),
        ),
      );
    }

    void handleUpload(BuildContext context) {
      void core() {
        ref.read(anxWebdavProvider.notifier).uploadBook(book);
      }

      if (Prefs().notShowReleaseLocalSpaceDialog) {
        ref.read(anxWebdavProvider.notifier).uploadBook(book);
      } else {
        SmartDialog.show(
          builder: (context) => AlertDialog(
            title: Text('释放空间'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('将把本书上传到云端，并删除本地文件，这有助于节省本地存储空间，在需要时可以随时下载。'),
                Row(
                  children: [
                    StatefulBuilder(builder: (context, setState) {
                      return Checkbox(
                          value: Prefs().notShowReleaseLocalSpaceDialog,
                          onChanged: (value) {
                            Prefs().notShowReleaseLocalSpaceDialog =
                                value ?? false;
                            setState(() {});
                          });
                    }),
                    Text('不再提示'),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  SmartDialog.dismiss();
                },
                child: Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  SmartDialog.dismiss();
                  core();
                },
                child: Text('确认'),
              ),
            ],
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          bookCover(context, book, width: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Text(book.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ),
          IconAndText(
              icon: const Icon(EvaIcons.cloud_upload),
              text: '释放空间',
              onTap: () {
                handleUpload(context);
              }),
          IconAndText(
            icon: const Icon(EvaIcons.more_vertical),
            text: L10n.of(context).notes_page_detail,
            onTap: () {
              handleDetail(context);
            },
          ),
          DeleteConfirm(
            delete: () {
              handleDelete(context);
            },
            deleteIcon: IconAndText(
              icon: const Icon(EvaIcons.trash),
              text: L10n.of(context).common_delete,
            ),
            confirmIcon: IconAndText(
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
  }
}
