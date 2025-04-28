import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/utils/save_img.dart';
import 'package:anx_reader/widgets/book_share/excerpt_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcerptShareBottomSheet extends StatefulWidget {
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
  State<ExcerptShareBottomSheet> createState() =>
      _ExcerptShareBottomSheetState();
}

class _ExcerptShareBottomSheetState extends State<ExcerptShareBottomSheet> {
  final GlobalKey _cardKey = GlobalKey();

  String _template = 'default';
  String _font = 'default';
  Color _textColor = Colors.black;
  Color _backgroundColor = Colors.white;
  String? _backgroundImage;

  // 模板列表
  final List<String> _templates = ['default', 'simple', 'elegant', 'modern'];

  // 字体列表
  final List<String> _fonts = ['default', 'serif', 'sans-serif', 'monospace'];

  // 配色方案列表
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

  // 背景图片列表 - 这里可以添加项目中的背景图片或者使用网络图片
  final List<String?> _backgroundImages = [
    null, // 无背景图片选项
    'assets/images/book_share/bg1.jpg',
    'assets/images/book_share/bg2.jpg',
    'assets/images/book_share/bg3.jpg',
    'assets/images/book_share/bg4.jpg',
    'assets/images/book_share/bg5.jpg',
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
      debugPrint('截图错误: $e');
      return null;
    }
  }

  Future<void> _shareAsImage() async {
    SmartDialog.showLoading(msg: '加载中...');

    final imageData = await _captureCard();
    if (imageData == null) {
      SmartDialog.dismiss();
      return;
    }

    final tempDir = await getApplicationDocumentsDirectory();
    final file = File('${tempDir.path}/anx_excerpt_share.png');
    await file.writeAsBytes(imageData);

    SmartDialog.dismiss();
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _saveAsImage() async {
    final imageData = await _captureCard();
    if (imageData == null) return;

    final fileName = 'AnxReader_${widget.bookTitle.replaceAll(' ', '_')}';
    await SaveImg.downloadImg(imageData, 'png', fileName);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // 顶部拖动条
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '分享',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
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

          const SizedBox(height: 16),

          // 设置选项
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 模板选择
                    Text(
                      '模板',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _templates.length,
                        itemBuilder: (context, index) {
                          final template = _templates[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(template),
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

                    // 字体选择
                    Text(
                      '字体',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _fonts.length,
                        itemBuilder: (context, index) {
                          final font = _fonts[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(font),
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
                    ),

                    const SizedBox(height: 16),

                    // 配色选择
                    Text(
                      '配色方案',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
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
                                  _textColor = scheme['text']!;
                                  _backgroundColor = scheme['background']!;
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

                    // 背景图片选择
                    Text(
                      '背景图片',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
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
                                  _backgroundImage = bgImage;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: bgImage == null
                                      ? Colors.grey.withOpacity(0.2)
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

          // 底部按钮
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(
                  icon: const Icon(Icons.save_alt),
                  label: '保存图片',
                  onTap: _saveAsImage,
                ),
                _actionButton(
                  icon: const Icon(Icons.share),
                  label: '分享',
                  onTap: _shareAsImage,
                ),
                _actionButton(
                  icon: const Icon(Icons.copy),
                  label: '复制',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.excerpt));
                    SmartDialog.showToast('复制成功');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
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
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ExcerptShareBottomSheet(
      bookTitle: bookTitle,
      author: author,
      excerpt: excerpt,
      chapter: chapter,
    ),
  );
}
