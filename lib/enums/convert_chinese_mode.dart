enum ConvertChineseMode {
  none,
  s2t,
  t2s,
}

ConvertChineseMode getConvertChineseMode(String name) {
  return ConvertChineseMode.values.firstWhere((e) => e.name == name);
}
