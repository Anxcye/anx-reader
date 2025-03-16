import 'package:anx_reader/enums/ai_role.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/ai_message.dart';
import 'package:anx_reader/providers/ai_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AiChatStream extends ConsumerStatefulWidget {
  const AiChatStream(
      {super.key, this.initialMessage, this.sendImmediate = false});

  final String? initialMessage;
  final bool sendImmediate;

  @override
  ConsumerState<AiChatStream> createState() => _AiChatStreamState();
}

class _AiChatStreamState extends ConsumerState<AiChatStream> {
  final TextEditingController _controller = TextEditingController();
  Stream<List<AiMessage>>? _messageStream;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialMessage ?? '';
    if (widget.sendImmediate) {
      _sendMessage();
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
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

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final message = _controller.text.trim();
    _controller.clear();

    setState(() {
      _messageStream =
          ref.read(aiChatProvider.notifier).sendMessageStream(message, ref);
    });
  }

  void _clearMessage() {
    setState(() {
      ref.read(aiChatProvider.notifier).clear();
      _messageStream = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: _messageStream != null
                ? StreamBuilder<List<AiMessage>>(
                    stream: _messageStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data!;
                      _scrollToBottom();

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
                            child: Text(L10n.of(context).ai_hint_text),
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
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearMessage,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: L10n.of(context).ai_hint_input_placeholder,
                    border: const OutlineInputBorder(),
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
    );
  }

  Widget _buildMessageItem(AiMessage message) {
    final isUser = message.role == AiRole.user;
    final isLongMessage = message.content.length > 300;

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
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.only(
                  topLeft: isUser ? const Radius.circular(12) : Radius.zero,
                  topRight: isUser ? Radius.zero : const Radius.circular(12),
                  bottomLeft: isUser ? Radius.zero : const Radius.circular(12),
                  bottomRight: isUser ? const Radius.circular(12) : Radius.zero,
                ),
              ),
              child: isUser
                  ? _buildCollapsibleText(message.content, isLongMessage)
                  : _buildCollapsibleMarkdown(message.content, isLongMessage),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCollapsibleText(String text, bool isLongMessage) {
    if (!isLongMessage) {
      return Text(text);
    }

    return _CollapsibleText(text: text);
  }

  Widget _buildCollapsibleMarkdown(String markdownText, bool isLongMessage) {
    if (!isLongMessage) {
      return MarkdownBody(data: markdownText);
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
          Text(widget.text)
        else
          Stack(
            children: [
              Text(
                widget.text.substring(0, 300),
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
                            .primaryContainer
                            .withValues(alpha: 0),
                        Theme.of(context).colorScheme.primaryContainer,
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
              ? L10n.of(context).ai_hint_collapse
              : L10n.of(context).ai_hint_expand),
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
          MarkdownBody(data: widget.markdownText)
        else
          Stack(
            children: [
              MarkdownBody(
                data: widget.markdownText.substring(0, 300),
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
              ? L10n.of(context).ai_hint_collapse
              : L10n.of(context).ai_hint_expand),
        ),
      ],
    );
  }
}
