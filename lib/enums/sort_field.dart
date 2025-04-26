import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:flutter/material.dart';

enum SortFieldEnum {
  title,
  author,
  lastReadTime,
  progress,
  importTime,
}

extension SortFieldExtension on SortFieldEnum {
  String getL10n(BuildContext context) {
    return switch (this) {
      SortFieldEnum.title => L10n.of(context).bookshelf_title,
      SortFieldEnum.author => L10n.of(context).bookshelf_author,
      SortFieldEnum.lastReadTime => L10n.of(context).bookshelf_lastReadTime,
      SortFieldEnum.progress => L10n.of(context).bookshelf_progress,
      SortFieldEnum.importTime => L10n.of(context).bookshelf_importTime,
    };
  }
}

