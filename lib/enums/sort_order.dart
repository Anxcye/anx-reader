import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:flutter/material.dart';

enum SortOrderEnum {
  ascending,
  descending,
}

extension SortOrderExtension on SortOrderEnum {
  String getL10n(BuildContext context) {
    return switch (this) {
      SortOrderEnum.ascending => L10n.of(context).commonAscending,
      SortOrderEnum.descending => L10n.of(context).commonDescending,
    };
  }
}
