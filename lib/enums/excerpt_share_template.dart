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
        return '默认模板';
      case ExcerptShareTemplateEnum.simpleTemplate:
        return '简约模板';
      case ExcerptShareTemplateEnum.elegantTemplate:
        return '优雅模板';
      case ExcerptShareTemplateEnum.verticalTemplate:
        return '垂直模板';
    }
  }
}

