import 'dart:convert';

import 'package:anx_reader/enums/convert_chinese_mode.dart';

class ReadingRules {
  late ConvertChineseMode convertChineseMode;
  late bool bionicReading;

  ReadingRules({required this.convertChineseMode, required this.bionicReading});

  ReadingRules.fromJson(String json) {
    Map<String, dynamic> data = jsonDecode(json);
    convertChineseMode = getConvertChineseMode(data['convertChineseMode']);
    bionicReading = data['bionicReading'];
  }

  String toJson() {
    return '''
    {
      "convertChineseMode": "${convertChineseMode.name}",
      "bionicReading": $bionicReading
    }
    ''';
  }

  ReadingRules copyWith({
    ConvertChineseMode? convertChineseMode,
    bool? bionicReading,
  }) {
    return ReadingRules(
      convertChineseMode: convertChineseMode ?? this.convertChineseMode,
      bionicReading: bionicReading ?? this.bionicReading,
    );
  }
}
