import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/utils/ai_reasoning_parser.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:langchain/langchain.dart';

typedef AiTokenUsageRecorder = void Function({
  required int inputTokens,
  required int outputTokens,
  required bool estimated,
});

class CancelableLangchainRunner {
  CancelableLangchainRunner({this.onTokenUsage});

  static const String thinkTag = '<think/>';
  final AiTokenUsageRecorder? onTokenUsage;
  StreamSubscription<ChatResult>? _subscription;
  StreamController<String>? _controller;
  BaseChatModel? _activeModel;
  Completer<void>? _activeIteration;

  void cancel() {
    final subscription = _subscription;
    final controller = _controller;
    final model = _activeModel;
    final iteration = _activeIteration;
    _subscription = null;
    _controller = null;
    _activeModel = null;
    _activeIteration = null;
    if (iteration != null && !iteration.isCompleted) iteration.complete();
    unawaited(() async {
      await subscription?.cancel();
      if (model != null) await _closeModel(model);
      if (controller != null && !controller.isClosed) {
        await controller.close();
      }
    }());
  }

  Stream<String> stream({
    required BaseChatModel model,
    required PromptValue prompt,
  }) {
    String thinkBuffer = '';
    String answerBuffer = '';
    bool reasoningDetected = false;
    bool answerPhaseStarted = false;
    LanguageModelUsage? usage;

    late StreamController<String> controller;
    controller = StreamController<String>(
      onListen: () {
        final source = model.stream(prompt);
        _subscription = source.listen(
          (event) {
            usage = _mergeUsage(usage, event.usage);
            final rawChunk = event.output.content;
            final reasoningChunk = event.output.reasoningContent;
            if (rawChunk.isEmpty && reasoningChunk.isEmpty) {
              return;
            }

            if (reasoningChunk.isNotEmpty) {
              reasoningDetected = true;
              thinkBuffer += reasoningChunk;
            }

            var contentChunk = rawChunk;
            if (contentChunk.isNotEmpty && _isThinkChunk(contentChunk)) {
              reasoningDetected = true;
              thinkBuffer += _cleanThinkChunk(contentChunk);
              contentChunk = '';
            }

            if (contentChunk.isNotEmpty) {
              if (reasoningDetected && !answerPhaseStarted) {
                if (contentChunk.trim().isEmpty) {
                  thinkBuffer += contentChunk;
                } else {
                  answerPhaseStarted = true;
                  answerBuffer += contentChunk;
                }
              } else {
                answerBuffer += contentChunk;
              }
            }

            final aggregated = reasoningDetected
                ? composeReasoningEnvelope(
                    answerContent: answerBuffer,
                    reasoningContent: thinkBuffer.trim(),
                  )
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
            _recordUsage(
              usage,
              prompt: prompt.toChatMessages(),
              response: '$thinkBuffer$answerBuffer',
            );
            await _closeModel(model);
            if (!controller.isClosed) {
              await controller.close();
            }
            _subscription = null;
            if (identical(_controller, controller)) _controller = null;
            if (identical(_activeModel, model)) _activeModel = null;
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
        if (identical(_controller, controller)) _controller = null;
        if (identical(_activeModel, model)) _activeModel = null;
      },
    );
    _controller = controller;
    _activeModel = model;

    return controller.stream;
  }

  Stream<String> streamAgent({
    required BaseChatModel model,
    required List<Tool> tools,
    required List<ChatMessage> history,
    required String input,
    ChatMessage? systemMessage,
    int maxIterations = 120,
  }) {
    final controller = StreamController<String>();
    _controller = controller;
    _activeModel = model;

    Future<void>(() async {
      final parser = const ToolsAgentOutputParser();
      final toolMap = <String, Tool>{
        for (final tool in tools) tool.name: tool,
        ExceptionTool.toolName: ExceptionTool(),
      };
      final toolSpecs = tools.cast<ToolSpec>().toList(growable: false);
      final steps = <AgentStep>[];
      final timeline = <_ReasoningItem>[];
      // String? pendingThought;
      var iterations = 0;

      void emit() {
        if (controller.isClosed) return;
        controller.add(
          _composeAgentPayload(
            timeline: timeline,
          ),
        );
      }

      void appendThinkingChunk(String text) {
        if (timeline.isNotEmpty &&
            timeline.last.type == _ReasoningItemType.think) {
          timeline.last.appendText(text);
        } else {
          timeline.add(_ReasoningItem.think(text));
        }
      }

      void appendReplyChunk(String text) {
        if (timeline.isNotEmpty &&
            timeline.last.type == _ReasoningItemType.reply) {
          timeline.last.appendText(text);
        } else {
          timeline.add(_ReasoningItem.reply(text));
        }
      }

      List<ChatMessage> buildScratchpad() {
        final scratchpad = <ChatMessage>[];
        final seenLogs = <int>{};

        for (final step in steps) {
          for (final logMessage in step.action.messageLog) {
            final key = identityHashCode(logMessage);
            if (seenLogs.add(key)) {
              scratchpad.add(logMessage);
            }
          }

          scratchpad.add(
            ChatMessage.tool(
              toolCallId: step.action.id,
              content: step.observation,
            ),
          );
        }

        return scratchpad;
      }

      List<ChatMessage> buildConversation() {
        return <ChatMessage>[
          if (systemMessage != null) systemMessage,
          ...history,
          ChatMessage.humanText(input),
          ...buildScratchpad(),
        ];
      }

      var streamFailed = false;

      try {
        while (iterations < maxIterations && !controller.isClosed) {
          final promptMessages = buildConversation();
          if (promptMessages.isEmpty) {
            throw StateError('Agent prompt messages cannot be empty');
          }

          final prompt = PromptValue.chat(promptMessages);
          final options = model.defaultOptions.copyWith(tools: toolSpecs);

          ChatResult? aggregated;
          final completer = Completer<void>();
          _activeIteration = completer;
          _subscription = model.stream(prompt, options: options).listen(
            (chunk) {
              final normalizedChunk = _normalizeThinkChunk(chunk);

              aggregated = aggregated == null
                  ? normalizedChunk
                  : aggregated!.concat(normalizedChunk);
              final output = aggregated!.output;
              final reasoningChunk = normalizedChunk.output.reasoningContent;

              if (reasoningChunk.isNotEmpty) {
                appendThinkingChunk(reasoningChunk);
                emit();
              }

              if (output.toolCalls.isEmpty) {
                final textChunk = normalizedChunk.output.content;
                if (textChunk.isNotEmpty) {
                  appendReplyChunk(textChunk);
                  emit();
                }
              }
            },
            onError: (Object error, StackTrace stack) {
              streamFailed = true;
              if (!controller.isClosed) {
                controller.addError(error, stack);
              }
              if (!completer.isCompleted) {
                completer.completeError(error, stack);
              }
            },
            onDone: () {
              _subscription = null;
              if (identical(_activeIteration, completer)) {
                _activeIteration = null;
              }
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
            cancelOnError: true,
          );

          await completer.future;

          if (aggregated == null) {
            throw StateError('Model returned no output');
          }

          final message = aggregated!.output;
          _recordUsage(
            aggregated!.usage,
            prompt: promptMessages,
            response:
                '${message.reasoningContent}${message.content}${message.toolCalls}',
          );
          final hydratedMessage = _hydrateToolArguments(message);
          final actions = await parser.parseChatMessage(hydratedMessage);

          // if (message.toolCalls.isNotEmpty || pendingThought != null) {
          //   // pendingThought = null;
          // }

          var shouldStop = false;
          for (final action in actions) {
            if (action is AgentFinish) {
              shouldStop = true;
              break;
            }

            final agentAction = action as AgentAction;

            final tool = toolMap[agentAction.tool];
            if (tool == null) {
              throw Exception('Tool ${agentAction.tool} not found');
            }

            final toolStep = _ToolStep(
              action: agentAction,
              status: ToolStepStatus.pending,
            );
            timeline.add(_ReasoningItem.tool(toolStep));
            emit();

            try {
              final inputJson = agentAction.toolInput;
              String? message;
              late final dynamic toolInput;
              try {
                toolInput = tool.getInputFromJson(inputJson);
              } catch (e) {
                message = 'Invalid tool input: $e';
              }
              final observation = message == null
                  ? await tool.invoke(toolInput)
                  : 'Error: $message';
              final observationText = observation.toString();
              toolStep.status = ToolStepStatus.success;
              toolStep.output = observationText;
              toolStep.observation = observationText;
              emit();
              steps.add(
                AgentStep(
                  action: agentAction,
                  observation: observationText,
                ),
              );
            } catch (error) {
              AnxLog.severe(
                  'Tool ${agentAction.tool} execution failed: $error');
              final message = error.toString();
              toolStep.status = ToolStepStatus.failed;
              toolStep.error = message;
              toolStep.observation = message;
              appendReplyChunk('Tool ${agentAction.tool} failed: $message');
              emit();
              shouldStop = true;
              break;
            }

            if (tool.returnDirect) {
              final direct = toolStep.output ?? '';
              appendReplyChunk(direct);
              emit();
              shouldStop = true;
              break;
            }
          }

          if (shouldStop) {
            break;
          }

          iterations += 1;
        }
      } catch (error, stack) {
        if (!controller.isClosed && !streamFailed) {
          controller.addError(error, stack);
        }
      } finally {
        _activeIteration = null;
        await _subscription?.cancel();
        _subscription = null;
        await _closeModel(model);
        if (!controller.isClosed) {
          await controller.close();
        }
        if (identical(_controller, controller)) _controller = null;
        if (identical(_activeModel, model)) _activeModel = null;
      }
    });

    return controller.stream;
  }

  LanguageModelUsage? _mergeUsage(
    LanguageModelUsage? current,
    LanguageModelUsage next,
  ) {
    if (!_hasUsage(next)) return current;
    return current == null ? next : current.concat(next);
  }

  bool _hasUsage(LanguageModelUsage usage) =>
      (usage.promptTokens ?? 0) > 0 ||
      (usage.responseTokens ?? 0) > 0 ||
      (usage.totalTokens ?? 0) > 0;

  void _recordUsage(
    LanguageModelUsage? usage, {
    required List<ChatMessage> prompt,
    required String response,
  }) {
    final recorder = onTokenUsage;
    if (recorder == null) return;
    if (usage != null && _hasUsage(usage)) {
      final reportedInput = usage.promptTokens;
      final reportedOutput = usage.responseTokens;
      if (reportedInput != null || reportedOutput != null) {
        // A few providers expose only response_tokens, or expose a zero
        // prompt_tokens value while streaming. Treat zero as missing here:
        // otherwise the settings page permanently reports input usage as 0.
        // The prompt is available locally, so estimate only the missing side.
        final estimatedInput = _estimateTokens(
          prompt.map((message) => message.contentAsString).join('\n'),
        );
        final estimatedOutput = _estimateTokens(response);
        final hasReportedInput = reportedInput != null && reportedInput > 0;
        final hasReportedOutput = reportedOutput != null && reportedOutput > 0;
        final input = hasReportedInput ? reportedInput : estimatedInput;
        final output = hasReportedOutput ? reportedOutput : estimatedOutput;
        recorder(
          inputTokens: input,
          outputTokens: output,
          estimated: !hasReportedInput || !hasReportedOutput,
        );
        return;
      }
    }
    recorder(
      inputTokens: _estimateTokens(
        prompt.map((message) => message.contentAsString).join('\n'),
      ),
      outputTokens: _estimateTokens(response),
      estimated: true,
    );
  }

  int _estimateTokens(String text) {
    if (text.isEmpty) return 0;
    var cjk = 0;
    var other = 0;
    for (final rune in text.runes) {
      if ((rune >= 0x3400 && rune <= 0x9fff) ||
          (rune >= 0xf900 && rune <= 0xfaff)) {
        cjk++;
      } else {
        other++;
      }
    }
    return cjk + (other / 4).ceil();
  }

  ChatResult _normalizeThinkChunk(ChatResult chunk) {
    final content = _normalizeThinkText(chunk.output.content);
    final reasoningContent = _normalizeThinkText(chunk.output.reasoningContent);
    final output = AIChatMessage(
      content: content,
      reasoningContent: reasoningContent,
      toolCalls: chunk.output.toolCalls,
    );

    return ChatResult(
      output: output,
      usage: chunk.usage,
      id: chunk.id,
      finishReason: chunk.finishReason,
      metadata: chunk.metadata,
    );
  }

  String _normalizeThinkText(String text) {
    if (text.isEmpty || !_isThinkChunk(text)) {
      return text;
    }
    return _cleanThinkChunk(text);
  }

  String _composeAgentPayload({
    required List<_ReasoningItem> timeline,
  }) {
    final buffer = StringBuffer();
    for (final item in timeline) {
      final tag = item.toTag();
      if (tag.isNotEmpty) {
        buffer.write(tag);
      }
    }
    return buffer.toString();
  }

  bool _isThinkChunk(String chunk) {
    return chunk.startsWith(thinkTag);
  }

  String _cleanThinkChunk(String chunk) {
    return chunk.substring(thinkTag.length);
  }

  AIChatMessage _hydrateToolArguments(AIChatMessage message) {
    if (message.toolCalls.isEmpty) {
      return message;
    }

    var mutated = false;
    final enrichedToolCalls = <AIChatMessageToolCall>[];

    for (final toolCall in message.toolCalls) {
      if (toolCall.arguments.isNotEmpty ||
          toolCall.argumentsRaw.trim().isEmpty) {
        enrichedToolCalls.add(toolCall);
        continue;
      }

      try {
        final decoded = jsonDecode(toolCall.argumentsRaw);
        if (decoded is Map<String, dynamic>) {
          enrichedToolCalls.add(
            AIChatMessageToolCall(
              id: toolCall.id,
              name: toolCall.name,
              argumentsRaw: toolCall.argumentsRaw,
              arguments: decoded,
            ),
          );
          mutated = true;
          continue;
        }
      } catch (_) {
        // Keep original tool call if decoding fails.
      }

      enrichedToolCalls.add(toolCall);
    }

    if (!mutated) {
      return message;
    }

    return AIChatMessage(
      content: message.content,
      reasoningContent: message.reasoningContent,
      toolCalls: enrichedToolCalls,
    );
  }

  Future<void> _closeModel(BaseChatModel model) async {
    try {
      model.close();
    } catch (_) {
      // ignore close errors
    }
  }
}

class _ToolStep {
  _ToolStep({
    required this.action,
    required this.status,
  }) : observation = '';

  final AgentAction action;
  ToolStepStatus status;
  String observation;
  String? output;
  String? error;

  AgentStep toAgentStep() =>
      AgentStep(action: action, observation: observation);

  String toTag() {
    String? encode(String? value) {
      if (value == null || value.isEmpty) {
        return null;
      }
      final encoded = base64Encode(utf8.encode(value));
      return _escapeAttr(encoded);
    }

    final buffer = StringBuffer(
      '<tool-step name=\'${_escapeAttr(action.tool)}\' '
      "status='${status.name}'",
    );
    final inputEncoded = encode(jsonEncode(action.toolInput));
    if (inputEncoded != null) {
      buffer.write(" input_b64='$inputEncoded'");
    }
    final outputEncoded = encode(output);
    if (outputEncoded != null) {
      buffer.write(" output_b64='$outputEncoded'");
    }
    final errorEncoded = encode(error);
    if (errorEncoded != null) {
      buffer.write(" error_b64='$errorEncoded'");
    }
    buffer.write('/>');
    return buffer.toString();
  }
}

enum ToolStepStatus { pending, success, failed }

String _escapeAttr(String value) {
  return Uri.encodeComponent(value);
}

enum _ReasoningItemType { think, reply, tool }

class _ReasoningItem {
  _ReasoningItem.think(String text)
      : reply = text,
        toolStep = null,
        type = _ReasoningItemType.think;

  _ReasoningItem.reply(String text)
      : reply = text,
        toolStep = null,
        type = _ReasoningItemType.reply;

  _ReasoningItem.tool(this.toolStep)
      : reply = null,
        type = _ReasoningItemType.tool;

  String? reply;
  final _ToolStep? toolStep;
  final _ReasoningItemType type;

  void appendText(String text) {
    if (type != _ReasoningItemType.reply && type != _ReasoningItemType.think) {
      return;
    }
    reply = (reply ?? '') + text;
  }

  String toTag() {
    switch (type) {
      case _ReasoningItemType.think:
        final text = reply;
        if (text == null || text.isEmpty) {
          return '';
        }
        final encoded = base64Encode(utf8.encode(text));
        return "<think-block text_b64='${_escapeAttr(encoded)}'/>";
      case _ReasoningItemType.reply:
        final text = reply;
        if (text == null || text.isEmpty) {
          return '';
        }
        final encoded = base64Encode(utf8.encode(text));
        return "<reply text_b64='${_escapeAttr(encoded)}'/>";
      case _ReasoningItemType.tool:
        if (toolStep == null) {
          return '';
        }
        return toolStep!.toTag();
    }
  }
}
