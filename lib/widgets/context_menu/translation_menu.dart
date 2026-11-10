import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/reading_lookup.dart';
import 'package:anx_reader/service/dictionary/pronunciation_player.dart';
import 'package:anx_reader/service/dictionary/reading_lookup_router.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/service/vocabulary_capture_service.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

typedef SelectionLookup = Future<ReadingLookupResult> Function({
  required ReadingLookupCandidate candidate,
  required NetworkPolicy networkPolicy,
  String? contextText,
});

/// A result for an explicitly requested lookup, frozen to its source selection.
/// Constructing this widget can only read local dictionaries and caches.
class TranslationMenu extends StatefulWidget {
  const TranslationMenu({
    super.key,
    required this.content,
    required this.decoration,
    required this.axis,
    required this.candidate,
    this.contextText,
    this.position,
    this.offline = false,
    this.embedded = false,
    this.translateImmediately = false,
    this.onExplainWithAi,
    this.aiGenerating = false,
    this.bookId,
    this.bookTitle,
    this.chapterHref,
    this.chapterTitle,
    this.lookup = ReadingLookupRouter.lookup,
    this.translationBuilder,
    this.pronounce,
  });

  final String content;
  final BoxDecoration decoration;
  final Axis axis;
  final String? contextText;
  final String? position;
  final bool offline;
  final bool embedded;

  /// Only set by the explicit passage translation action, never by selection.
  final bool translateImmediately;
  final VoidCallback? onExplainWithAi;
  final bool aiGenerating;
  final ReadingLookupCandidate candidate;
  final int? bookId;
  final String? bookTitle;
  final String? chapterHref;
  final String? chapterTitle;
  final SelectionLookup lookup;
  final Widget Function(String text, String? contextText)? translationBuilder;
  final Future<void> Function(String text, String? audioUrl)? pronounce;

  @override
  State<TranslationMenu> createState() => _TranslationMenuState();
}

class _TranslationMenuState extends State<TranslationMenu> {
  late final String _text;
  late final String? _contextText;
  late final String? _position;
  late final ReadingLookupCandidate _candidate;
  late final int? _bookId;
  late final String? _bookTitle;
  late final String? _chapterHref;
  late final String? _chapterTitle;
  late final Future<ReadingLookupResult> _localLookup;
  late final VoidCallback? _onExplainWithAi;
  ReadingLookupResult? _result;
  Widget? _translation;
  bool _loading = true;
  bool _failed = false;
  bool _pronouncing = false;
  bool _adding = false;
  bool _added = false;
  int _requestRevision = 0;
  NetworkPolicy _lastLookupPolicy = NetworkPolicy.offlineOnly;

  @override
  void initState() {
    super.initState();
    _text = widget.content.trim();
    _contextText = widget.contextText?.trim();
    _position = widget.position;
    _candidate = widget.candidate;
    _onExplainWithAi = widget.onExplainWithAi;
    _bookId = widget.bookId;
    _bookTitle = widget.bookTitle;
    _chapterHref = widget.chapterHref;
    _chapterTitle = widget.chapterTitle;
    _localLookup = _lookup(NetworkPolicy.offlineOnly);
    _readLocalResult();
    if (widget.translateImmediately && !widget.offline) _startTranslation();
  }

  @override
  void didUpdateWidget(covariant TranslationMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Connectivity may resolve after the explicit translation opens this
    // frozen result. Selection updates alone never authorize translation.
    if (oldWidget.offline &&
        !widget.offline &&
        widget.translateImmediately &&
        _translation == null) {
      _startTranslation();
    }
  }

  // A parent must change the key to request another source. Selection changes
  // alone must not start another lookup, overwrite this result or send a model
  // request. The shared workspace keeps this source snapshot until an action.
  Future<ReadingLookupResult> _lookup(NetworkPolicy policy) => widget.lookup(
        candidate: _candidate,
        networkPolicy: policy,
        contextText: _contextText,
      );

  Future<void> _readLocalResult() async {
    final revision = _requestRevision;
    try {
      final result = await _localLookup;
      if (!mounted || revision != _requestRevision) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || revision != _requestRevision) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _lookUpOnline() => _requestLookup(NetworkPolicy.networkAllowed);

  Future<void> _requestLookup(NetworkPolicy policy) async {
    if (_loading || (widget.offline && policy.allowsNetwork)) return;
    _lastLookupPolicy = policy;
    final revision = ++_requestRevision;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await _lookup(policy);
      if (!mounted || revision != _requestRevision) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || revision != _requestRevision) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _startTranslation() {
    if (widget.offline) return;
    _translation = widget.translationBuilder?.call(_text, _contextText) ??
        translateText(_text, contextText: _contextText);
  }

  Future<void> _playPronunciation() async {
    if (widget.offline || _pronouncing) return;
    setState(() => _pronouncing = true);
    try {
      // Audio metadata is read only after the explicit pronunciation action.
      final result = _result?.audioUrl != null
          ? _result!
          : await _lookup(NetworkPolicy.networkAllowed);
      if (!mounted) return;
      final pronounce = widget.pronounce;
      if (pronounce != null) {
        await pronounce(_text, result.audioUrl);
      } else {
        await PronunciationPlayer()
            .play(text: _text, audioUrl: result.audioUrl);
      }
    } catch (_) {
      if (mounted) AnxToast.show(L10n.of(context).commonFailed);
    } finally {
      if (mounted) setState(() => _pronouncing = false);
    }
  }

  Future<void> _addToVocabulary() async {
    if (_adding || _bookId == null) return;
    setState(() => _adding = true);
    final l10n = L10n.of(context);
    try {
      final result = await VocabularyCaptureService.captureQuick(
        word: _text,
        bookId: _bookId.toString(),
        bookTitle: _bookTitle,
        chapterId: _chapterHref,
        chapterTitle: _chapterTitle,
        contextText: _contextText,
        position: _position,
        // Saving a local word is not permission to enrich it over the network.
        translateLookup: (text, {contextText}) async => '',
        dictionaryLookup: (text) async => null,
      );
      if (!mounted) return;
      setState(() => _added = true);
      AnxToast.show(result.created
          ? l10n.vocabularyAddedToast
          : l10n.vocabularyAlreadyExists);
    } catch (_) {
      if (mounted) AnxToast.show(l10n.commonFailed);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Widget _languagePicker(bool from) => DropdownButton<LangListEnum>(
        value: from ? Prefs().translateFrom : Prefs().translateTo,
        isExpanded: true,
        itemHeight: Prefs().isEInkMode ? 56 : 48,
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            if (from) {
              Prefs().translateFrom = value;
            } else {
              Prefs().translateTo = value;
            }
            // A language change never silently re-runs the previous request.
            _translation = null;
          });
        },
        items: [
          for (final language in LangListEnum.values)
            DropdownMenuItem(
              value: language,
              child: Text(language.getNative(context)),
            ),
        ],
      );

  Widget _definition(BuildContext context) {
    final l10n = L10n.of(context);
    if (!_candidate.isDictionaryLookup) return const SizedBox.shrink();
    if (_loading) return const Text('…');
    if (_failed) return Text(l10n.commonFailed);
    final result = _result;
    if (result == null || !result.found) {
      return Text(l10n.selectionLookupEmpty);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          result.dictionaryName ??
              (result.source == ReadingLookupSource.englishDictionary
                  ? l10n.selectionLookupEnglish
                  : l10n.selectionLookupLocal),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        if (result.pronunciation?.isNotEmpty ?? false)
          Text(result.pronunciation!),
        if (result.partOfSpeech?.isNotEmpty ?? false)
          Text(result.partOfSpeech!),
        if (result.source == ReadingLookupSource.localMdx)
          // Imported HTML is text-only here: a local lookup must not fetch
          // remote images, styles, frames or audio embedded by a dictionary.
          Html(data: result.html ?? '', onlyRenderTheseTags: const {
            'html',
            'body',
            'p',
            'div',
            'span',
            'a',
            'b',
            'strong',
            'i',
            'em',
            'u',
            's',
            'br',
            'hr',
            'ul',
            'ol',
            'li',
            'dl',
            'dt',
            'dd',
            'h1',
            'h2',
            'h3',
            'h4',
            'table',
            'tbody',
            'tr',
            'td',
            'th',
            'small',
            'sup',
            'sub',
            'blockquote',
            'pre',
            'code',
          }),
        if (result.definition?.isNotEmpty ?? false) Text(result.definition!),
        for (var index = 0; index < result.senses.length; index++) ...[
          Text('${index + 1}. ${result.senses[index].definition}'),
          if (result.senses[index].example?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: Text(result.senses[index].example!),
            ),
        ],
        if (result.example?.isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          Text(result.example!),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final minHeight = Prefs().isEInkMode ? 56.0 : 48.0;
    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: Size(48, minHeight),
    );
    final body = Container(
      decoration: widget.decoration,
      padding: EdgeInsets.all(widget.embedded ? 16 : 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_text, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _definition(context),
            if (_failed)
              OutlinedButton.icon(
                style: buttonStyle,
                onPressed: () => _requestLookup(widget.offline
                    ? NetworkPolicy.offlineOnly
                    : _lastLookupPolicy),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.commonRetry),
              ),
            if (widget.offline) ...[
              const SizedBox(height: 16),
              Text(l10n.selectionOfflineUnavailable),
            ],
            if (_candidate.isDictionaryLookup &&
                !widget.offline &&
                (_result?.found != true || _failed))
              OutlinedButton.icon(
                style: buttonStyle,
                onPressed: _loading ? null : _lookUpOnline,
                icon: const Icon(Icons.language),
                label: Text(l10n.selectionLookupOnline),
              ),
            if (_candidate.isDictionaryLookup && !widget.offline)
              OutlinedButton.icon(
                style: buttonStyle,
                onPressed: _pronouncing ? null : _playPronunciation,
                icon: const Icon(Icons.volume_up_outlined),
                label: Text(_pronouncing ? '…' : l10n.selectionPronounce),
              ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _languagePicker(true)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 20),
              ),
              Expanded(child: _languagePicker(false)),
            ]),
            OutlinedButton.icon(
              style: buttonStyle,
              onPressed:
                  widget.offline ? null : () => setState(_startTranslation),
              icon: const Icon(Icons.translate),
              label: Text(l10n.selectionTranslateNow),
            ),
            if (_translation != null) ...[
              const SizedBox(height: 16),
              _translation!,
            ],
            if (_onExplainWithAi != null)
              OutlinedButton.icon(
                style: buttonStyle,
                onPressed: _onExplainWithAi,
                icon: const Icon(Icons.auto_awesome),
                label: Text(widget.aiGenerating
                    ? l10n.selectionStopAndExplain
                    : l10n.dictionaryAiContext),
              ),
            if (_candidate.isDictionaryLookup &&
                Prefs().bottomNavigatorShowVocabulary)
              OutlinedButton.icon(
                style: buttonStyle,
                onPressed: _adding || _bookId == null ? null : _addToVocabulary,
                icon: Icon(_added ? Icons.check : Icons.library_add_outlined),
                label: Text(_adding
                    ? l10n.vocabularyAdding
                    : _added
                        ? l10n.vocabularyAdded
                        : l10n.vocabularyAdd),
              ),
          ],
        ),
      ),
    );
    if (widget.embedded) return body;
    return Expanded(
      child: SizedBox(
        height: widget.axis == Axis.vertical ? null : 300,
        width: widget.axis == Axis.vertical ? 220 : null,
        child: body,
      ),
    );
  }
}
