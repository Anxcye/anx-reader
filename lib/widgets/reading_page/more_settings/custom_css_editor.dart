import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';

class CustomCSSEditor extends StatefulWidget {
  const CustomCSSEditor({super.key});

  @override
  State<CustomCSSEditor> createState() => _CustomCSSEditorState();
}

class _CustomCSSEditorState extends State<CustomCSSEditor> {
  late TextEditingController _cssController;
  bool _hasValidationErrors = false;
  String _validationMessage = '';
  bool _isExpanded = false;
  String _tempCSS = '';

  static const String defaultCSS = '''p {
  color:red !important;
}
''';

  @override
  void initState() {
    super.initState();
    final currentCSS = Prefs().customCSS;
    _tempCSS = currentCSS.isEmpty ? defaultCSS : currentCSS;
    _cssController = TextEditingController(text: _tempCSS);
    _cssController.addListener(_onCSSChanged);
    _isExpanded = Prefs().customCSSEnabled;
  }

  @override
  void dispose() {
    _cssController.removeListener(_onCSSChanged);
    _cssController.dispose();
    super.dispose();
  }

  void _onCSSChanged() {
    _tempCSS = _cssController.text;
    _validateCSS(_tempCSS);
  }

  void _validateCSS(String css) {
    setState(() {
      _hasValidationErrors = false;
      _validationMessage = '';
    });

    if (css.trim().isEmpty) return;

    final lines = css.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty ||
          line.startsWith('/*') ||
          line.startsWith('*') ||
          line.startsWith('*/')) {
        continue;
      }

      final openBraces = '{'.allMatches(css).length;
      final closeBraces = '}'.allMatches(css).length;
      if (openBraces != closeBraces) {
        setState(() {
          _hasValidationErrors = true;
          _validationMessage = L10n.of(context).cssValidationUnmatchedBraces;
        });
        return;
      }

      if (line.contains(':') && !line.contains('{') && !line.contains('}')) {
        if (!line.endsWith(';') && !line.endsWith('{')) {
          setState(() {
            _hasValidationErrors = true;
            _validationMessage =
                L10n.of(context).cssValidationMissingSemicolon(i + 1);
          });
          return;
        }
      }
    }
  }

  void _applyCSS() {
    epubPlayerKey.currentState?.changeStyle(null);
  }

  void _saveAndApply() {
    if (_hasValidationErrors) return;

    Prefs().customCSS = _tempCSS;

    if (Prefs().customCSSEnabled) {
      _applyCSS();
    }

    AnxToast.show(L10n.of(context).commonSaved);
  }

  void _restoreDefault() {
    _cssController.text = defaultCSS;
    _tempCSS = defaultCSS;
    _validateCSS(defaultCSS);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(L10n.of(context).customCssEnabled)),
            Switch(
              value: Prefs().customCSSEnabled,
              onChanged: (value) {
                setState(() {
                  Prefs().customCSSEnabled = value;
                  _isExpanded = value;
                  if (!_hasValidationErrors) {
                    _applyCSS();
                  }
                });
              },
            ),
          ],
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 16),
          if (_hasValidationErrors)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validationMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withAlpha(80)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _cssController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: 14,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: L10n.of(context).cssEditorHint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _restoreDefault,
                icon: const Icon(Icons.restore, size: 16),
                label: Text(L10n.of(context).cssRestoreDefault),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _hasValidationErrors ? null : _saveAndApply,
                icon: const Icon(Icons.save, size: 16),
                label: Text(L10n.of(context).cssSaveAndApply),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
