class MD5CalculationResult {
  final int totalBooks;
  final int calculated;
  final int skipped;
  final int failed;
  final List<String> missingFiles;

  MD5CalculationResult({
    required this.totalBooks,
    required this.calculated,
    required this.skipped,
    required this.failed,
    required this.missingFiles,
  });
}