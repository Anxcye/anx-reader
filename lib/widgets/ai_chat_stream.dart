import 'package:anx_reader/enums/ai_role.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/ai_message.dart';
import 'package:anx_reader/providers/ai_chat.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class AiChatStream extends ConsumerStatefulWidget {
  const AiChatStream(
      {super.key, this.initialMessage, this.sendImmediate = false});

  final String? initialMessage;
  final bool sendImmediate;

  @override
  ConsumerState<AiChatStream> createState() => AiChatStreamState();
}

class AiChatStreamState extends ConsumerState<AiChatStream> {
  final TextEditingController inputController = TextEditingController();
  Stream<List<AiMessage>>? _messageStream;
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> _getQuickPrompts(BuildContext context) {
    return [
      {
        'label': L10n.of(context).aiQuickPromptExplain,
        'prompt': L10n.of(context).aiQuickPromptExplainText
      },
      {
        'label': L10n.of(context).aiQuickPromptOpinion,
        'prompt': L10n.of(context).aiQuickPromptOpinionText
      },
      {
        'label': L10n.of(context).aiQuickPromptSummary,
        'prompt': L10n.of(context).aiQuickPromptSummaryText
      },
      {
        'label': L10n.of(context).aiQuickPromptAnalyze,
        'prompt': L10n.of(context).aiQuickPromptAnalyzeText
      },
      {
        'label': L10n.of(context).aiQuickPromptSuggest,
        'prompt': L10n.of(context).aiQuickPromptSuggestText
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    inputController.text = widget.initialMessage ?? '';
    if (widget.sendImmediate) {
      _sendMessage();
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({bool isRegenerate = false}) {
    if (inputController.text.trim().isEmpty) return;

    final message = inputController.text.trim();
    inputController.clear();

    setState(() {
      _messageStream = ref.read(aiChatProvider.notifier).sendMessageStream(
            message,
            ref,
            isRegenerate,
          );
    });
  }

  void _useQuickPrompt(String prompt) {
    inputController.text = '$prompt ${inputController.text}';
    _sendMessage();
  }

  void _clearMessage() {
    setState(() {
      ref.read(aiChatProvider.notifier).clear();
      _messageStream = null;
    });
  }

  void _regenerateLastMessage() {
    final messages = ref.read(aiChatProvider).value;
    if (messages != null && messages.isNotEmpty) {
      for (int i = messages.length - 1; i >= 0; i--) {
        if (messages[i].role == AiRole.user) {
          final userMessage = messages[i].content;
          ref.read(aiChatProvider.notifier).clear();
          for (int j = 0; j < i; j++) {
            ref.read(aiChatProvider.notifier).sendMessage(messages[j].content);
          }
          setState(() {
            inputController.text = userMessage;
            _sendMessage(isRegenerate: true);
          });
          break;
        }
      }
    }
  }

  void _copyMessageContent(String content) {
    Clipboard.setData(ClipboardData(text: content));
    AnxToast.show(L10n.of(context).notesPageCopied);
  }

  AiMessage? _getLastAssistantMessage() {
    final messages = ref.watch(aiChatProvider).asData?.value;
    if (messages == null || messages.isEmpty) return null;

    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == AiRole.assistant) {
        return messages[i];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final quickPrompts = _getQuickPrompts(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
              child: _messageStream != null
                  ? StreamBuilder<List<AiMessage>>(
                      stream: _messageStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(color: Colors.red,));
                        }

                        final messages = snapshot.data!;
                        // _scrollToBottom();

                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return _buildMessageItem(message);
                          },
                        );
                      },
                    )
                  : ref.watch(aiChatProvider).when(
                        data: (messages) {
                          if (messages.isEmpty) {
                            return Center(
                              child: Text(L10n.of(context).aiHintText),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              return _buildMessageItem(message);
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) =>
                            Center(child: Text('error: $error')),
                      )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(prompt['label']!),
                      onPressed: () => _useQuickPrompt(prompt['prompt']!),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearMessage,
                ),
                Expanded(
                  child: TextField(
                    controller: inputController,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: L10n.of(context).aiHintInputPlaceholder,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(AiMessage message) {
    final isUser = message.role == AiRole.user;
    final isLongMessage = message.content.length > 300;
    final lastAssistantMessage = _getLastAssistantMessage();

    return Padding(
      padding: EdgeInsets.only(
        bottom: 8.0,
        left: isUser ? 8.0 : 0,
        right: isUser ? 0 : 8.0,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: isUser ? const Radius.circular(12) : Radius.zero,
                  topRight: isUser ? Radius.zero : const Radius.circular(12),
                  bottomLeft: isUser ? Radius.zero : const Radius.circular(12),
                  bottomRight: isUser ? const Radius.circular(12) : Radius.zero,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isUser
                      ? _buildCollapsibleText(
                          message.content,
                          isLongMessage,
                        )
                      : _buildCollapsibleMarkdown(
                          message.content, false),
                  if (!isUser)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (message == lastAssistantMessage)
                          TextButton(
                            onPressed: _regenerateLastMessage,
                            child: Text(L10n.of(context).aiRegenerate),
                          ),
                        TextButton(
                          onPressed: () => _copyMessageContent(message.content),
                          child: Text(L10n.of(context).commonCopy),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCollapsibleText(String text, bool isLongMessage) {
    if (!isLongMessage) {
      return SelectableText(
        text,
        selectionControls: MaterialTextSelectionControls(),
      );
    }

    return _CollapsibleText(text: text);
  }

  Widget _buildCollapsibleMarkdown(String markdownText, bool isLongMessage) {
    if (!isLongMessage) {
      return MarkdownBody(
        data: markdownText,
        selectable: true,
      );
    }

    return _CollapsibleMarkdown(markdownText: markdownText);
  }
}

class _CollapsibleText extends StatefulWidget {
  final String text;

  const _CollapsibleText({required this.text});

  @override
  State<_CollapsibleText> createState() => _CollapsibleTextState();
}

class _CollapsibleTextState extends State<_CollapsibleText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isExpanded)
          SelectableText(
            widget.text,
            selectionControls: MaterialTextSelectionControls(),
          )
        else
          Stack(
            children: [
              SelectableText(
                widget.text.substring(0, 300),
                selectionControls: MaterialTextSelectionControls(),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withValues(alpha: 0),
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        TextButton(
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(_isExpanded
              ? L10n.of(context).aiHintCollapse
              : L10n.of(context).aiHintExpand),
        ),
      ],
    );
  }
}

class _CollapsibleMarkdown extends StatefulWidget {
  final String markdownText;

  const _CollapsibleMarkdown({required this.markdownText});

  @override
  State<_CollapsibleMarkdown> createState() => _CollapsibleMarkdownState();
}

class _CollapsibleMarkdownState extends State<_CollapsibleMarkdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isExpanded)
          MarkdownBody(
            data: widget.markdownText,
            selectable: true,
          )
        else
          Stack(
            children: [
              MarkdownBody(
                data: widget.markdownText.substring(0, 300),
                selectable: true,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .surfaceContainer
                            .withValues(alpha: 0),
                        Theme.of(context).colorScheme.surfaceContainer,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        TextButton(
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(_isExpanded
              ? L10n.of(context).aiHintCollapse
              : L10n.of(context).aiHintExpand),
        ),
      ],
    );
  }
}
