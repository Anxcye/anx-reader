import 'dart:math';

class StorageInfoModel {
  late int databaseSize;
  late int booksSize;
  late int fontSize;
  late int cacheSize;
  late int logSize;
  late int coverSize;

  StorageInfoModel({
    required this.databaseSize,
    required this.booksSize,
    required this.fontSize,
    required this.cacheSize,
    required this.logSize,
    required this.coverSize,
  });

  String get databaseSizeStr => formatSize(databaseSize);
  String get booksSizeStr => formatSize(booksSize);
  String get fontSizeStr => formatSize(fontSize);
  String get cacheSizeStr => formatSize(cacheSize);
  String get logSizeStr => formatSize(logSize);
  String get coverSizeStr => formatSize(coverSize);

  String get totalSizeStr => formatSize(
      databaseSize + booksSize + fontSize + cacheSize + logSize + coverSize);
  String get dataFilesSizeStr => formatSize(booksSize + fontSize + coverSize);

  String formatSize(int bytes) {
    if (bytes <= 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }
}
