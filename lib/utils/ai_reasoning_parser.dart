import 'dart:convert';

import 'package:anx_reader/service/ai/tools/ai_tool_registry.dart';
import 'package:langchain_core/chat_models.dart';

class ReasoningEnvelope {
  const ReasoningEnvelope({
    required this.reasoningContent,
    required this.answerContent,
  });

  final String reasoningContent;
  final String answerContent;
}

class ParsedReasoning {
  const ParsedReasoning({
    required this.timeline,
  });

  final List<ParsedReasoningEntry> timeline;

  List<ParsedReasoningEntry> get reasoningTimeline => timeline
      .where((entry) => entry.section == ParsedReasoningSection.reasoning)
      .toList(growable: false);

  List<ParsedReasoningEntry> get answerTimeline => timeline
      .where((entry) => entry.section == ParsedReasoningSection.answer)
      .toList(growable: false);

  bool get hasReplies =>
      timeline.any((entry) => entry.type == ParsedReasoningEntryType.reply);

  bool get hasToolSteps =>
      timeline.any((entry) => entry.type == ParsedReasoningEntryType.tool);

  List<ParsedToolStep> get toolSteps => timeline
      .where((entry) => entry.type == ParsedReasoningEntryType.tool)
      .map((entry) => entry.toolStep!)
      .toList(growable: false);
}

String cleanAiDisplayText(String content, {bool answerOnly = false}) {
  final normalized = content.replaceAll(
    RegExp(
      r'<(?:think|thinking)>[\s\S]*?</(?:think|thinking)>',
      caseSensitive: false,
    ),
    '',
  );
  final parsed = parseReasoningContent(normalized);
  final entries = answerOnly ? parsed.answerTimeline : parsed.timeline;
  final text = entries
      .where((entry) => entry.type == ParsedReasoningEntryType.reply)
      .map((entry) => entry.text ?? '')
      .where((value) => value.trim().isNotEmpty)
      .join('\n');
  final source = text.trim().isEmpty ? normalized : text;
  return source
      .replaceAll(
        RegExp(
          r'</?(?:think|thinking|text|reply|answer|reasoning)[^>]*>',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll(RegExp(r'^\s*#{1,6}\s*', multiLine: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

enum ParsedReasoningEntryType { reply, tool }

enum ParsedReasoningSection { reasoning, answer }

class ParsedReasoningEntry {
  const ParsedReasoningEntry.reply(this.text, {required this.section})
      : toolStep = null,
        type = ParsedReasoningEntryType.reply;

  const ParsedReasoningEntry.tool(this.toolStep, {required this.section})
      : text = null,
        type = ParsedReasoningEntryType.tool;

  final String? text;
  final ParsedToolStep? toolStep;
  final ParsedReasoningEntryType type;
  final ParsedReasoningSection section;
}

class ParsedToolStep {
  const ParsedToolStep({
    required this.name,
    required this.status,
    this.input,
    this.output,
    this.error,
  });

  final String name;
  final String status;
  final String? input;
  final String? output;
  final String? error;
}

ParsedReasoning parseReasoningContent(String content) {
  final timeline = <ParsedReasoningEntry>[];
  final thinkRegex = RegExp(r'<think>([\s\S]*?)<\/think>');
  var remaining = content;

  final matches = thinkRegex.allMatches(content).toList(growable: false);
  if (matches.isNotEmpty) {
    for (final match in matches) {
      final inner = match.group(1);
      if (inner != null && inner.isNotEmpty) {
        _parseTimeline(
          inner,
          timeline,
          section: ParsedReasoningSection.reasoning,
        );
      }
    }
    remaining = content.replaceAll(thinkRegex, '');
  }

  if (remaining.isNotEmpty) {
    _parseTimeline(
      remaining,
      timeline,
      section: ParsedReasoningSection.answer,
    );
  }

  return ParsedReasoning(timeline: timeline);
}

ReasoningEnvelope splitReasoningEnvelope(String content) {
  final thinkRegex = RegExp(r'<think>([\s\S]*?)<\/think>');
  final matches = thinkRegex.allMatches(content).toList(growable: false);
  if (matches.isEmpty) {
    return ReasoningEnvelope(reasoningContent: '', answerContent: content);
  }

  final reasoning = matches
      .map((match) => match.group(1) ?? '')
      .where((part) => part.isNotEmpty)
      .join('\n');
  var answer = content.replaceAll(thinkRegex, '');
  answer = answer.replaceFirst(RegExp(r'^\r?\n'), '');

  return ReasoningEnvelope(
    reasoningContent: reasoning,
    answerContent: answer,
  );
}

String composeReasoningEnvelope({
  required String answerContent,
  required String reasoningContent,
}) {
  if (reasoningContent.isEmpty) {
    return answerContent;
  }
  if (answerContent.isEmpty) {
    return '<think>$reasoningContent</think>';
  }
  return '<think>$reasoningContent</think>\n$answerContent';
}

String chatMessageDisplayContent(ChatMessage message) {
  if (message is AIChatMessage && message.reasoningContent.isNotEmpty) {
    return composeReasoningEnvelope(
      answerContent: message.content,
      reasoningContent: message.reasoningContent,
    );
  }
  return message.contentAsString;
}

AIChatMessage assistantMessageFromDisplayContent(
  String content, {
  List<AIChatMessageToolCall> toolCalls = const [],
}) {
  final envelope = splitReasoningEnvelope(content);
  return AIChatMessage(
    content: envelope.answerContent,
    reasoningContent: envelope.reasoningContent,
    toolCalls: toolCalls,
  );
}

Map<String, String> _parseAttributes(String raw) {
  final attrs = <String, String>{};
  final attrRegex = RegExp(r"(\w+)='([^']*)'");
  for (final match in attrRegex.allMatches(raw)) {
    attrs[match.group(1)!] = match.group(2)!;
  }
  return attrs;
}

String? _decodeAttrValue(Map<String, String> attrs, String key) {
  final direct = attrs[key];
  if (direct != null) {
    return _unescapeAttr(direct);
  }
  final encoded = attrs['${key}_b64'];
  if (encoded != null) {
    final decoded = utf8.decode(base64Decode(_unescapeAttr(encoded)));
    return decoded;
  }
  return null;
}

String _unescapeAttr(String value) {
  return Uri.decodeComponent(value);
}

void _parseTimeline(
  String source,
  List<ParsedReasoningEntry> timeline, {
  required ParsedReasoningSection section,
}) {
  if (source.isEmpty) {
    return;
  }

  final tagRegex = RegExp(r'<(tool-step|reply|think-block)\s+([^/>]+?)\s*/>');
  var currentIndex = 0;
  var buffer = StringBuffer();

  void flushBuffer() {
    final chunk = buffer.toString();
    buffer = StringBuffer();
    if (chunk.isEmpty) {
      return;
    }
    timeline.add(ParsedReasoningEntry.reply(chunk, section: section));
  }

  for (final match in tagRegex.allMatches(source)) {
    final preceding = source.substring(currentIndex, match.start);
    if (preceding.isNotEmpty) {
      buffer.write(preceding);
    }

    final tagName = match.group(1)!;
    final attrs = _parseAttributes(match.group(2)!);

    if (tagName == 'tool-step') {
      flushBuffer();
      timeline.add(
        ParsedReasoningEntry.tool(
          ParsedToolStep(
            name: _unescapeAttr(attrs['name'] ?? ''),
            status: (attrs['status'] ?? 'pending').toLowerCase(),
            input: _decodeAttrValue(attrs, 'input'),
            output: _decodeAttrValue(attrs, 'output'),
            error: _decodeAttrValue(attrs, 'error'),
          ),
          section: section,
        ),
      );
    } else {
      final decoded = _decodeAttrValue(attrs, 'text');
      final text = decoded ?? _unescapeAttr(attrs['text'] ?? '');
      if (text.isNotEmpty) {
        flushBuffer();
        timeline.add(
          ParsedReasoningEntry.reply(
            text,
            section: tagName == 'think-block'
                ? ParsedReasoningSection.reasoning
                : section,
          ),
        );
      }
    }

    currentIndex = match.end;
  }

  final trailing = source.substring(currentIndex);
  if (trailing.isNotEmpty) {
    buffer.write(trailing);
  }
  flushBuffer();
}

String reasoningContentToPlainText(String content) {
  final parsed = parseReasoningContent(content);
  if (parsed.timeline.isEmpty) {
    return content;
  }

  final sections = <String>[];

  for (final entry in parsed.timeline) {
    switch (entry.type) {
      case ParsedReasoningEntryType.reply:
        final text = entry.text;
        if (text != null && text.isNotEmpty) {
          sections.add(text);
        }
        break;
      case ParsedReasoningEntryType.tool:
        final step = entry.toolStep;
        if (step != null) {
          final toolName = AiToolRegistry.displayNameForId(step.name);
          final lines = <String>['[Tool $toolName ${step.status}]'];
          final output = step.output?.trim();
          if (output != null && output.isNotEmpty) {
            lines.add(output);
          }
          final error = step.error?.trim();
          if (error != null && error.isNotEmpty) {
            lines.add('Error: $error');
          }
          final input = step.input?.trim();
          if (input != null && input.isNotEmpty) {
            lines.add('Input: $input');
          }
          final section = lines.join('\n').trim();
          if (section.isNotEmpty) {
            sections.add(section);
          }
        }
        break;
    }
  }

  final result = sections.join('\n\n').trim();
  return result.isEmpty ? content : result;
}
