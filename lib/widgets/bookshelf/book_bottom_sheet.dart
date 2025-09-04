import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/providers/sync_status.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/delete_confirm.dart';
import 'package:anx_reader/widgets/icon_and_text.dart';
import 'package:anx_reader/widgets/show_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

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
        md5: book.md5,
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
      Future<void> core() async {
        await ref.read(syncProvider.notifier).releaseBook(book);
        ref.read(syncStatusProvider.notifier).refresh();
      }

      if (Prefs().notShowReleaseLocalSpaceDialog) {
        ref.read(syncProvider.notifier).releaseBook(book);
      } else {
        SmartDialog.show(
          builder: (context) => AlertDialog(
            title: Text(L10n.of(context).bookSyncStatusReleaseSpaceDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(L10n.of(context).bookSyncStatusReleaseSpaceDialogContent),
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
                    Text(L10n.of(context).bookSyncStatusDoNotShowAgain),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  SmartDialog.dismiss();
                },
                child: Text(L10n.of(context).commonCancel),
              ),
              TextButton(
                onPressed: () {
                  SmartDialog.dismiss();
                  core();
                },
                child: Text(L10n.of(context).commonConfirm),
              ),
            ],
          ),
        );
      }
    }

    Future<void> handleShare() async {
      showLoading();
      await SharePlus.instance.share(ShareParams(
        title: '${book.title}.${book.filePath.split('.').last}',
        files: [XFile(book.fileFullPath)],
      ));
      SmartDialog.dismiss();
    }

    final actions = [
      {
        "icon": EvaIcons.share,
        "text": "Share File",
        "onTap": () => handleShare()
      },
      {
        "icon": EvaIcons.cloud_upload,
        "text": L10n.of(context).bookSyncStatusReleaseSpace,
        "onTap": () => handleUpload(context)
      },
      {
        "icon": EvaIcons.more_vertical,
        "text": L10n.of(context).notesPageDetail,
        "onTap": () => handleDetail(context)
      },
    ];

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
          DeleteConfirm(
            delete: () {
              handleDelete(context);
            },
            deleteIcon: IconAndText(
              icon: const Icon(EvaIcons.trash),
              text: L10n.of(context).commonDelete,
            ),
            confirmIcon: IconAndText(
              icon: const Icon(
                EvaIcons.checkmark_circle_2,
                color: Colors.red,
              ),
              text: L10n.of(context).commonConfirm,
            ),
          ),
          PopupMenuButton(
              itemBuilder: (context) {
                return actions.map((action) {
                  return PopupMenuItem(
                    child: TextButton.icon(
                      icon: Icon(action["icon"] as IconData),
                      label: Text(action["text"] as String),
                      onPressed: () {
                        Navigator.pop(context);
                        (action["onTap"] as Function())();
                      },
                    ),
                  );
                }).toList();
              },
              child: IconAndText(
                icon: const Icon(EvaIcons.more_vertical),
                text: L10n.of(context).more,
              ))
        ],
      ),
    );
  }
}
