import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

class ExcerptShareCard extends StatelessWidget {
  final String bookTitle;
  final String author;
  final String excerpt;
  final String? chapter;
  final String template;
  final String font;
  final Color textColor;
  final Color backgroundColor;
  final String? backgroundImage;

  const ExcerptShareCard({
    super.key,
    required this.bookTitle,
    required this.author,
    required this.excerpt,
    this.chapter,
    required this.template,
    required this.font,
    required this.textColor,
    required this.backgroundColor,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = switch (template) {
      'simple' => _buildSimpleTemplate(),
      'elegant' => _buildElegantTemplate(),
      'modern' => _buildModernTemplate(),
      _ => _buildDefaultTemplate(),
    };

    return RepaintBoundary(
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
      ),
    );
  }

  TextStyle _getTextStyle() {
    FontWeight weight = FontWeight.normal;
    switch (font) {
      case 'serif':
        return TextStyle(
          fontFamily: 'SourceHanSerif',
          color: textColor,
          fontWeight: weight,
        );
      case 'sans-serif':
        return TextStyle(
          fontFamily: 'sans-serif',
          color: textColor,
          fontWeight: weight,
        );
      case 'monospace':
        return TextStyle(
          fontFamily: 'monospace',
          color: textColor,
          fontWeight: weight,
        );
      case 'default':
      default:
        return TextStyle(
          color: textColor,
          fontWeight: weight,
        );
    }
  }

  Widget _getAnxReaderLogo() {
    return Text(
      'Anx Reader',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w100,
      ),
    );
  }

  Text _getContent() {
    return Text(
      excerpt,
      style: _getTextStyle().copyWith(
        fontSize: 18,
        height: 2,
      ),
    );
  }

  Widget _getTitleText({
    TextAlign textAlign = TextAlign.start,
    TextDirection textDirection = TextDirection.ltr,
    bool verticle = false,
    double fontSize = 20,
  }) {
    if (verticle) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 350),
        child: MongolText(
          bookTitle,
          style: _getTextStyle().copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
      );
    } else {
      return Text(
        bookTitle,
        textAlign: textAlign,
        textDirection: textDirection,
        style: _getTextStyle().copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget _getChapterText({
    String leading = '—— ',
    bool verticle = false,
    double textSize = 14,
  }) {
    if (chapter == null || chapter!.isEmpty) {
      return const SizedBox.shrink();
    }
    if (verticle) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 350),
        child: MongolText(
          '$leading$chapter',
          style: _getTextStyle().copyWith(
            fontSize: textSize,
          ),
        ),
      );
    } else {
      return Text(
        '$leading$chapter',
        style: _getTextStyle().copyWith(
          fontSize: textSize,
        ),
      );
    }
  }

  Widget _getAuthorText({bool verticle = false, double textSize = 14}) {
    if (verticle) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 350),
        child: MongolText(
          author,
          style: _getTextStyle().copyWith(
            fontSize: textSize,
          ),
        ),
      );
    } else {
      return Text(
        author,
        style: _getTextStyle().copyWith(
          fontSize: textSize,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget _buildDefaultTemplate() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        image: backgroundImage != null
            ? DecorationImage(
                image: AssetImage(backgroundImage!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  backgroundColor.withAlpha(100),
                  BlendMode.dstATop,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _getContent(),
          Row(
            children: [
              const Spacer(),
              _getChapterText(),
            ],
          ),
          const SizedBox(height: 16),
          Divider(thickness: 1, color: textColor.withAlpha(80)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _getTitleText(),
                    const SizedBox(height: 4),
                    _getAuthorText(),
                  ],
                ),
              ),
              _getAnxReaderLogo(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTemplate() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        image: backgroundImage != null
            ? DecorationImage(
                image: AssetImage(backgroundImage!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  backgroundColor.withAlpha(100),
                  BlendMode.dstATop,
                ),
              )
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _getTitleText()),
              const SizedBox(width: 16),
              _getChapterText(),
              const SizedBox(width: 16),
              _getAuthorText(),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Positioned(
                top: -15,
                left: 0,
                child: Icon(
                  Icons.format_quote,
                  size: 64,
                  color: textColor.withAlpha(40),
                ),
              ),
              _getContent(),
              Positioned(
                bottom: 0,
                right: 0,
                child: Transform.rotate(
                  angle: 3.14,
                  child: Icon(
                    Icons.format_quote,
                    size: 64,
                    color: textColor.withAlpha(40),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Row(
                children: [
                  Spacer(),
                  _getAnxReaderLogo(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElegantTemplate() {
    return Column(
      children: [
        Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              image: backgroundImage != null
                  ? DecorationImage(
                      image: AssetImage(backgroundImage!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        backgroundColor.withAlpha(200),
                        BlendMode.dstATop,
                      ),
                    )
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getTitleText(verticle: true, fontSize: 30),
                const SizedBox(width: 16),
                _getAuthorText(verticle: true, textSize: 20),
              ],
            )),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(children: [
          _getChapterText( leading: '/ ', textSize: 20),
          const SizedBox(height: 16),
          _getContent(),
               
          ]),
        ),
      ],
    );
  }

  Widget _buildModernTemplate() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        image: backgroundImage != null
            ? DecorationImage(
                image: AssetImage(backgroundImage!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  backgroundColor.withOpacity(0.7),
                  BlendMode.dstATop,
                ),
              )
            : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Icon(
              Icons.format_quote,
              size: 36,
              color: textColor.withOpacity(0.2),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 24),
              Center(
                child: SingleChildScrollView(
                  child: Text(
                    excerpt,
                    style: _getTextStyle().copyWith(
                      fontSize: 18,
                      height: 1.6,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      bookTitle,
                      style: _getTextStyle().copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    if (chapter != null && chapter!.isNotEmpty)
                      Text(
                        chapter!,
                        style: _getTextStyle().copyWith(
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: _getTextStyle().copyWith(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Transform.rotate(
              angle: 3.14,
              child: Icon(
                Icons.format_quote,
                size: 36,
                color: textColor.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
