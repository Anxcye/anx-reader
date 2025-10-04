import 'dart:async';

import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/prompts.dart';

class CancelableLangchainRunner {
  static const String thinkTag = '<think/>';
  StreamSubscription<ChatResult>? _subscription;

  void cancel() {
    _subscription?.cancel();
    _subscription = null;
  }

  Stream<String> stream({
    required BaseChatModel model,
    required PromptValue prompt,
  }) {
    String thinkBuffer = '';
    String answerBuffer = '';
    bool reasoningDetected = false;
    bool answerPhaseStarted = false;

    late StreamController<String> controller;
    controller = StreamController<String>(
      onListen: () {
        final source = model.stream(prompt);
        _subscription = source.listen(
          (event) {
            final rawChunk = event.output.content;
            if (rawChunk.isEmpty) {
              return;
            }

            if (_isThinkChunk(rawChunk)) {
              reasoningDetected = true;
              final cleaned = _cleanThinkChunk(rawChunk);
              if (cleaned.isNotEmpty) {
                thinkBuffer += cleaned;
              }
            } else {
              if (reasoningDetected && !answerPhaseStarted) {
                if (rawChunk.trim().isEmpty) {
                  thinkBuffer += rawChunk;
                } else {
                  answerPhaseStarted = true;
                  answerBuffer += rawChunk;
                }
              } else {
                answerBuffer += rawChunk;
              }
            }

            final aggregated = reasoningDetected
                ? '<think>${thinkBuffer.trim()}</think>\n$answerBuffer'
                : answerBuffer;

            if (!controller.isClosed) {
              controller.add(aggregated);
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) {
              controller.addError(error, stackTrace);
            }
          },
          onDone: () async {
            await _closeModel(model);
            if (!controller.isClosed) {
              await controller.close();
            }
            _subscription = null;
          },
          cancelOnError: false,
        );
      },
      onCancel: () async {
        await _subscription?.cancel();
        _subscription = null;
        await _closeModel(model);
        if (!controller.isClosed) {
          await controller.close();
        }
      },
    );

    return controller.stream;
  }

  bool _isThinkChunk(String chunk) {
    return chunk.startsWith(thinkTag);
  }

  String _cleanThinkChunk(String chunk) {
    return chunk.substring(thinkTag.length);
  }

  Future<void> _closeModel(BaseChatModel model) async {
    try {
      model.close();
    } catch (_) {
      // ignore close errors
    }
  }
}
