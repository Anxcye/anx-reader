import 'dart:io';

import 'package:anx_reader/l10n/generated/L10n_zh.dart';
import 'package:anx_reader/service/ai/ai_services.dart';
import 'package:anx_reader/service/ai/langchain_ai_config.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('selected PR regressions', () {
    tearDown(() {
      AnxLog.logFile = null;
    });

    test('file logging tolerates null destination and restores after clear', () {
      AnxLog.logFile = null;
      expect(() => AnxLog.writeToFile('ignored\n'), returnsNormally);
      expect(AnxLog.clear, returnsNormally);

      final directory = Directory.systemTemp.createTempSync('anx-log-test-');
      final target = File('${directory.path}/log.txt');
      try {
        AnxLog.logFile = target;
        AnxLog.writeToFile('initial\n');
        expect(target.readAsStringSync(), 'initial\n');

        AnxLog.logFile = File(directory.path); // Directory path is not a file.
        for (var attempt = 0; attempt < 5; attempt++) {
          expect(() => AnxLog.writeToFile('bad\n'), returnsNormally);
        }

        AnxLog.logFile = target;
        AnxLog.writeToFile('after failures\n');
        expect(target.readAsStringSync(), 'initial\n');

        // Successful clear resets the consecutive-failure disable counter.
        expect(AnxLog.clear, returnsNormally);
        expect(target.readAsStringSync(), isEmpty);
        AnxLog.writeToFile('after clear\n');
        expect(target.readAsStringSync(), 'after clear\n');

        AnxLog.logFile = File('/proc/anx-reader-selected-pr.log');
        for (var attempt = 0; attempt < 5; attempt++) {
          expect(() => AnxLog.writeToFile('proc failure\n'), returnsNormally);
        }
        expect(AnxLog.clear, returnsNormally);
      } finally {
        AnxLog.logFile = null;
        directory.deleteSync(recursive: true);
      }
    });

    test('Requesty is present with expected provider defaults and config mapping', () {
      final requesty = buildDefaultAiServices().singleWhere(
        (service) => service.identifier == 'requesty',
      );
      expect(requesty.title, 'Requesty');
      expect(requesty.defaultUrl,
          'https://router.requesty.ai/v1/chat/completions');
      expect(requesty.defaultModel, 'openai/gpt-4o-mini');

      final config = LangchainAiConfig.fromProvider(
        providerId: requesty.identifier,
        model: requesty.defaultModel,
        apiKey: '  test-key  ',
        url: requesty.defaultUrl,
      );
      expect(config.identifier, 'requesty');
      expect(config.apiKey, 'test-key');
      expect(config.model, 'openai/gpt-4o-mini');
      expect(config.baseUrl, 'https://router.requesty.ai/v1');
    });

    test('zh-TW statisticYesterday renders singular and other counts', () {
      final l10n = L10nZhTw();
      expect(l10n.statisticYesterday(1), '昨天');
      expect(l10n.statisticYesterday(2), '2天前');
      expect(l10n.statisticYesterday(7), '7天前');
    });
  });
}
