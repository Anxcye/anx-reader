import 'package:anx_reader/service/book_player/book_open_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('warns above platform thresholds for memory-loaded formats', () {
    expect(
      BookOpenPolicy.shouldWarn(
        extension: 'epub',
        fileSize: BookOpenPolicy.mobileWarningBytes,
        isMobile: true,
      ),
      isFalse,
    );
    expect(
      BookOpenPolicy.shouldWarn(
        extension: 'AZW3',
        fileSize: BookOpenPolicy.mobileWarningBytes + 1,
        isMobile: true,
      ),
      isTrue,
    );
    expect(
      BookOpenPolicy.shouldWarn(
        extension: 'mobi',
        fileSize: BookOpenPolicy.desktopWarningBytes + 1,
        isMobile: false,
      ),
      isTrue,
    );
  });

  test('does not warn for range-loaded PDF files', () {
    expect(
      BookOpenPolicy.shouldWarn(
        extension: 'pdf',
        fileSize: 1024 * 1024 * 1024,
        isMobile: true,
      ),
      isFalse,
    );
  });
}
