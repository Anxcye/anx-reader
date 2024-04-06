import '../models/book.dart';
import '../models/book_style.dart';
import '../service/book_player/book_player_server.dart';

String generateIndexHtml(Book book, BookStyle style, String cfi) {
  String bookPath = 'http://localhost:${Server().port}/book/${book.filePath}';
  return '''
  <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Anx Reader</title>

      <script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.5/jszip.min.js"></script>

      <script src="https://cdn.jsdelivr.net/npm/epubjs/dist/epub.min.js"></script>

      <style>
        body {
          margin: 0;
          padding: 0;
          overflow: hidden;
        }
      </style>
    </head>
<body>
  <div id="viewer"></div>

  <script>
    var book = ePub("$bookPath");
    var rendition;

    var renderBook = async function() {
      rendition = book.renderTo("viewer", {
        width: window.innerWidth,
        height: window.innerHeight,
      })
      
      if ('$cfi' !== '') {
        await rendition.display('$cfi')
      } else {
        await rendition.display()
      }
    };
    renderBook();



  </script>
</body>

    </html>
  ''';
}
