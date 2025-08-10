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
        return L10n.of(context).readingPageShareTemplateClassic;
      case ExcerptShareTemplateEnum.simpleTemplate:
        return L10n.of(context).readingPageShareTemplateSimple;
      case ExcerptShareTemplateEnum.elegantTemplate:
        return L10n.of(context).readingPageShareTemplateElegant;
      case ExcerptShareTemplateEnum.verticalTemplate:
        return L10n.of(context).readingPageShareTemplateModern;
    }
  }
}

