import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';

class TranslationMenu extends StatefulWidget {
  const TranslationMenu(
      {super.key, required this.content, required this.decoration});
  final String content;
  final BoxDecoration decoration;

  @override
  State<TranslationMenu> createState() => _TranslationMenuState();
}

class _TranslationMenuState extends State<TranslationMenu> {
  String? translatedText;
  bool isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    if (_mounted) {
      _translate();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _translate() async {
    try {
      final result = await translateText(widget.content);
      if (!_mounted) return;
      setState(() {
        translatedText = result;
        isLoading = false;
      });
    } catch (e) {
      if (!_mounted) return;
      setState(() {
        translatedText = L10n.of(context).translate_error;
        isLoading = false;
      });
    }
  }

  Widget _langPicker(bool isFrom) {
    return PopupMenuButton<LangList>(
      elevation: 100,
      position: PopupMenuPosition.under,
      useRootNavigator: true,
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 240,
        // Currently blocked by https://github.com/flutter/flutter/issues/116504
        maxHeight: 200,
      ),
      color: Theme.of(context).colorScheme.secondaryContainer,
      itemBuilder: (context) => [
        for (var lang in LangList.values)
          PopupMenuItem(
            child: Text(lang.getNative(context)),
            onTap: () {
              if (isFrom) {
                Prefs().translateFrom = lang;
              } else {
                Prefs().translateTo = lang;
              }
            },
          ),
      ],
      child: Text(
        isFrom
            ? Prefs().translateFrom.getNative(context)
            : Prefs().translateTo.getNative(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Container(
            decoration: widget.decoration,
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.content,
                    style: const TextStyle(
                      fontSize: 16,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: translatedText != null ? 1.0 : 0.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            translatedText ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Divider(),
                          Row(
                            children: [
                              _langPicker(true),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                              _langPicker(false),
                              const Spacer(),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(
                                      ClipboardData(text: widget.content));
                                  AnxToast.show(
                                      L10n.of(context).notes_page_copied);
                                },
                                icon: const Icon(EvaIcons.copy),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
