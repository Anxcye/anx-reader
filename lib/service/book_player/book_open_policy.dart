class BookOpenPolicy {
  BookOpenPolicy._();

  static const int mobileWarningBytes = 100 * 1024 * 1024;
  static const int desktopWarningBytes = 300 * 1024 * 1024;
  static const Set<String> memoryLoadedExtensions = {
    'epub',
    'mobi',
    'azw3',
    'fb2',
  };

  static bool shouldWarn({
    required String extension,
    required int fileSize,
    required bool isMobile,
  }) {
    if (!memoryLoadedExtensions.contains(extension.toLowerCase())) return false;
    final threshold = isMobile ? mobileWarningBytes : desktopWarningBytes;
    return fileSize > threshold;
  }

  static String formatMiB(int bytes) =>
      (bytes / (1024 * 1024)).toStringAsFixed(1);
}
