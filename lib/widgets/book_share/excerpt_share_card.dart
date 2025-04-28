import 'package:flutter/material.dart';

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

  Widget _buildDefaultTemplate() {
    return Container(
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
              child: SingleChildScrollView(
                child: Text(
                  excerpt,
                  style: _getTextStyle().copyWith(
                    fontSize: 18,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
          ),
          if (chapter != null && chapter!.isNotEmpty)
            Text(
              '—— $chapter',
              style: _getTextStyle().copyWith(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.end,
            ),
          const SizedBox(height: 16),
          Divider(thickness: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookTitle,
                      style: _getTextStyle().copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: _getTextStyle().copyWith(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
                Text(
                  'Anx Reader',
                  style: _getTextStyle().copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTemplate() {
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
      child: Column(
        children: [
          Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '❝',
                      style: _getTextStyle().copyWith(
                        fontSize: 48,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      excerpt,
                      style: _getTextStyle().copyWith(
                        fontSize: 18,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '❞',
                      style: _getTextStyle().copyWith(
                        fontSize: 48,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          Column(
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
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 4),
              Text(
                author,
                style: _getTextStyle().copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElegantTemplate() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
          image: backgroundImage != null
              ? DecorationImage(
                  image: AssetImage(backgroundImage!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    backgroundColor.withOpacity(0.6),
                    BlendMode.dstATop,
                  ),
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: textColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              bookTitle,
              style: _getTextStyle().copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              author,
              style: _getTextStyle().copyWith(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              width: 100,
              color: textColor.withOpacity(0.5),
            ),
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
            if (chapter != null && chapter!.isNotEmpty)
              Column(
                children: [
                  Container(
                    height: 1,
                    width: 100,
                    color: textColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    chapter!,
                    style: _getTextStyle().copyWith(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
          ],
        ),
      
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
