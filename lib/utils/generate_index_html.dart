import 'package:anx_reader/models/read_theme.dart';

import '../models/book.dart';
import '../models/book_style.dart';
import '../service/book_player/book_player_server.dart';

String generateIndexHtml(
    Book book, BookStyle style, ReadTheme theme, String cfi) {
  String bookPath = 'http://localhost:${Server().port}/book/${book.filePath}';
  String epubJs = 'http://localhost:${Server().port}/js/epub.min.js';
  String zipJs = 'http://localhost:${Server().port}/js/jszip.min.js';
  String backgroundColor = theme.backgroundColor.substring(2) +
      theme.backgroundColor.substring(0, 2);
  String textColor =
      theme.textColor.substring(2) + theme.textColor.substring(0, 2);
print(textColor);
  String customStyles = '''
    body {
      padding-top: ${style.topMargin}px !important;
      padding-bottom: ${style.bottomMargin}px !important;
      line-height: ${style.lineHeight} !important;
      letter-spacing: ${style.letterSpacing}px !important;
      word-spacing: ${style.wordSpacing}px !important;
    }
    p {
      padding-top: ${style.paragraphSpacing}px !important;
      line-height: ${style.lineHeight} !important;
    }
  ''';

  return '''
  <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Anx Reader</title>

      <script src="$zipJs"></script>
      <script src="$epubJs"></script>
      <style>
        body {
          margin: 0;
          padding: 0; 
        }
        html {
          background-color: #$backgroundColor;
        }
      </style>
    </head>
<body>
  <div id="viewer"></div>

  <script>
    var book = ePub("$bookPath")
    var rendition = book.renderTo("viewer", {
        width: window.innerWidth,
        height: window.innerHeight,
        allowScriptedContent: true,
        gap: ${style.sideMargin},
    })
    var refreshProgress
    
    defaultStyle = function() {
      rendition.themes.fontSize('${style.fontSize}%');
      rendition.themes.font('${style.fontFamily}');

      rendition.themes.default({
        'html': {
          'background-color': '#$backgroundColor',
          'color': '#$textColor',
        },
        'body': {
          'padding-top': '${style.topMargin}px !important',
          'padding-bottom': '${style.bottomMargin}px !important',
          'line-height': '${style.lineHeight} !important',
          'letter-spacing': '${style.letterSpacing}px !important',
          'word-spacing': '${style.wordSpacing}px !important',
        },
        'p': {
          'padding-top': '${style.paragraphSpacing}px !important',
          'line-height': '${style.lineHeight} !important',
        },
      });
    }
    defaultStyle();
    
    
    book.ready.then(function() {
        return book.locations.generate(1000); 
    }).then(function(){
      refreshProgress();
    })
    

    getCurrentChapterTitle = function() {
      let toc = book.navigation.toc;
      let href = rendition.currentLocation().start.href;
    
      function findChapterLabel(items, href) {
        for (let item of items) {
          if (item.href === href) {
            return item.label.trim();
          } else if (item.subitems.length > 0) {
            const subitemLabel = findChapterLabel(item.subitems, href);
            if (subitemLabel) {
              return subitemLabel;
            }
          }
        }
        return null;
      }
    
      const chapterLabel = findChapterLabel(toc, href);
      return chapterLabel || 'Unknown Chapter';
    }
    
    refreshProgress = function() {
      let progress = book.locations.percentageFromCfi(rendition.currentLocation().start.cfi);
      window.flutter_inappwebview.callHandler('getProgress', progress);
      window.flutter_inappwebview.callHandler('getChapterCurrentPage', rendition.location.start.displayed.page);
      window.flutter_inappwebview.callHandler('getChapterTotalPage', rendition.location.end.displayed.total);
      window.flutter_inappwebview.callHandler('getChapterTitle', getCurrentChapterTitle());
      window.flutter_inappwebview.callHandler('getChapterHref', rendition.currentLocation().start.href);
    }

    var renderBook = async function() {
      if ('$cfi' !== '') {
        await rendition.display('$cfi')
      } else {
        await rendition.display()
      }

      rendition.on('relocated', function(locations) {
        refreshProgress();
        window.flutter_inappwebview.callHandler('onRelocated', locations.start.index);
      });
    };
    renderBook()
  </script>
</body>

    </html>
  ''';
}
