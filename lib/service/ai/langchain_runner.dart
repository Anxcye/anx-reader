import 'dart:async';

import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/prompts.dart';

class CancelableLangchainRunner {
  StreamSubscription<ChatResult>? _subscription;

  void cancel() {
    _subscription?.cancel();
    _subscription = null;
  }

  Stream<String> stream({
    required BaseChatModel model,
    required PromptValue prompt,
  }) {
    String buffer = '';
    late StreamController<String> controller;
    controller = StreamController<String>(
      onListen: () {
        final source = model.stream(prompt);
        _subscription = source.listen(
          (event) {
            final chunk = event.output.content;
            if (chunk.isEmpty) {
              return;
            }
            buffer += chunk;
            if (!controller.isClosed) {
              controller.add(buffer);
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

  Future<void> _closeModel(BaseChatModel model) async {
    try {
      model.close();
    } catch (_) {
      // ignore close errors
    }
  }
}
