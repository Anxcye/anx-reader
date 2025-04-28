import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:flutter/material.dart';

enum ExcerptShareTemplateEnum {
  defaultTemplate,
  simpleTemplate,
  elegantTemplate,
  verticalTemplate,
}

extension ExcerptShareTemplateEnumExtension on ExcerptShareTemplateEnum {
  String getL10n(BuildContext context) {
    switch (this) {
      case ExcerptShareTemplateEnum.defaultTemplate:
        return L10n.of(context).reading_page_share_template_classic;
      case ExcerptShareTemplateEnum.simpleTemplate:
        return L10n.of(context).reading_page_share_template_simple;
      case ExcerptShareTemplateEnum.elegantTemplate:
        return L10n.of(context).reading_page_share_template_elegant;
      case ExcerptShareTemplateEnum.verticalTemplate:
        return L10n.of(context).reading_page_share_template_modern;
    }
  }
}

