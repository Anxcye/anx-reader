import 'dart:io';
import 'dart:ui' as ui;

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/excerpt_share_template.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/font_model.dart';
import 'package:anx_reader/providers/font_list.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/save_img.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/book_share/excerpt_share_card.dart';
import 'package:anx_reader/widgets/icon_and_text.dart';
import 'package:anx_reader/widgets/show_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:share_plus/share_plus.dart';

class ExcerptShareBottomSheet extends ConsumerStatefulWidget {
  final String bookTitle;
  final String author;
  final String excerpt;
  final String? chapter;

  const ExcerptShareBottomSheet({
    super.key,
    required this.bookTitle,
    required this.author,
    required this.excerpt,
    this.chapter,
  });

  @override
  ConsumerState<ExcerptShareBottomSheet> createState() =>
      _ExcerptShareBottomSheetState();
}

class _ExcerptShareBottomSheetState
    extends ConsumerState<ExcerptShareBottomSheet> {
  final GlobalKey _cardKey = GlobalKey();

  // Color _textColor = Colors.black;
  // Color _backgroundColor = Colors.white;
  // String? _backgroundImage;

  set _template(ExcerptShareTemplateEnum template) {
    Prefs().excerptShareTemplate = template;
  }

  set _font(FontModel font) {
    Prefs().excerptShareFont = font;
  }

  ExcerptShareTemplateEnum get _template => Prefs().excerptShareTemplate;

  FontModel get _font => Prefs().excerptShareFont;

  set _colorIndex(int index) {
    Prefs().excerptShareColorIndex = index;
  }

  set _bgimgIndex(int index) {
    Prefs().excerptShareBgimgIndex = index;
  }

  Color get _textColor =>
      _colorSchemes[Prefs().excerptShareColorIndex]['text']!;

  Color get _backgroundColor =>
      _colorSchemes[Prefs().excerptShareColorIndex]['background']!;

  String? get _backgroundImage =>
      _backgroundImages[Prefs().excerptShareBgimgIndex];

  // final List<String> _fonts = ['default', 'serif', 'sans-serif', 'monospace'];

  final List<Map<String, Color>> _colorSchemes = [
    {'text': Colors.black, 'background': Colors.white},
    {
      'text': const ui.Color.fromARGB(255, 246, 217, 149),
      'background': const ui.Color.fromARGB(255, 48, 44, 28)
    },
    {'text': Colors.black, 'background': Colors.amber.shade100},
    {'text': Colors.white, 'background': Colors.blueGrey.shade800},
    {'text': Colors.black, 'background': Colors.pink.shade50},
    {'text': Colors.white, 'background': Colors.indigo.shade900},
  ];

  final List<String?> _backgroundImages = [
    null,
    'assets/images/book_share/bg1.jpg',
    'assets/images/book_share/bg2.jpg',
    'assets/images/book_share/bg3.jpg',
    'assets/images/book_share/bg4.jpg',
    'assets/images/book_share/bg5.jpg',
    'assets/images/book_share/bg6.jpg',
    'assets/images/book_share/bg7.jpg',
  ];

  Future<Uint8List?> _captureCard() async {
    try {
      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      AnxToast.show('Capture card error');
      AnxLog.severe('Capture card error: $e');
      return null;
    }
  }

  Future<void> _shareAsImage() async {
    showLoading();

    final imageData = await _captureCard();
    if (imageData == null) {
      SmartDialog.dismiss();
      return;
    }

    final tempDir = (await getAnxTempDir()).path;
    final file = File('$tempDir/anx_excerpt_share.png');
    await file.writeAsBytes(imageData);

    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
    SmartDialog.dismiss();
  }

  Future<void> _saveAsImage() async {
    final imageData = await _captureCard();
    if (imageData == null) return;

    final fileName = 'AnxReader_${widget.bookTitle.replaceAll(' ', '_')}';
    await SaveImg.downloadImg(imageData, 'png', fileName);
  }

  TextStyle _getTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: ExcerptShareCard(
                    key: _cardKey,
                    bookTitle: widget.bookTitle,
                    author: widget.author,
                    excerpt: widget.excerpt,
                    chapter: widget.chapter,
                    template: _template,
                    font: _font,
                    textColor: _textColor,
                    backgroundColor: _backgroundColor,
                    backgroundImage: _backgroundImage,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.of(context).readingPageShareTemplate,
                      style: _getTitleStyle(context),
                    ),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: ExcerptShareTemplateEnum.values.length,
                        itemBuilder: (context, index) {
                          final template =
                              ExcerptShareTemplateEnum.values[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(template.getL10n(context)),
                              selected: _template == template,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _template = template;
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      L10n.of(context).readingPageShareFont,
                      style: _getTitleStyle(context),
                    ),
                    SizedBox(
                      height: 50,
                      child: ref.watch(fontListProvider).when(
                            data: (data) => ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                final font = data[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ChoiceChip(
                                    label: Text(font.label),
                                    selected: _font == font,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _font = font;
                                        });
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stack) => Center(
                              child: Text(error.toString()),
                            ),
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      L10n.of(context).readingPageShareColor,
                      style: _getTitleStyle(context),
                    ),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _colorSchemes.length,
                        itemBuilder: (context, index) {
                          final scheme = _colorSchemes[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _colorIndex = index;
                                });
                              },
                              child: Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: scheme['background'],
                                  border: Border.all(
                                    color: (_textColor == scheme['text'] &&
                                            _backgroundColor ==
                                                scheme['background'])
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                    width: (_textColor == scheme['text'] &&
                                            _backgroundColor ==
                                                scheme['background'])
                                        ? 2
                                        : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Aa',
                                    style: TextStyle(
                                      color: scheme['text'],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      L10n.of(context).readingPageShareBackground,
                      style: _getTitleStyle(context),
                    ),
                    SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _backgroundImages.length,
                        itemBuilder: (context, index) {
                          final bgImage = _backgroundImages[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _bgimgIndex = index;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: bgImage == null
                                      ? Colors.grey.withAlpha(100)
                                      : null,
                                  image: bgImage != null
                                      ? DecorationImage(
                                          image: AssetImage(bgImage),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  border: Border.all(
                                    color: _backgroundImage == bgImage
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey,
                                    width: _backgroundImage == bgImage ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: bgImage == null
                                    ? const Icon(Icons.block)
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconAndText(
                icon: const Icon(Icons.save_alt),
                text: L10n.of(context).readingPageShareSave,
                onTap: _saveAsImage,
              ),
              IconAndText(
                icon: const Icon(Icons.share),
                text: L10n.of(context).readingPageShareShare,
                onTap: _shareAsImage,
              ),
              IconAndText(
                icon: const Icon(Icons.copy),
                text: L10n.of(context).commonCopy,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.excerpt));
                  AnxToast.show(L10n.of(context).notesPageCopied);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showExcerptShareBottomSheet({
  required BuildContext context,
  required String bookTitle,
  required String author,
  required String excerpt,
  String? chapter,
}) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => ExcerptShareBottomSheet(
      bookTitle: bookTitle,
      author: author,
      excerpt: excerpt,
      chapter: chapter,
    ),
  );
}
