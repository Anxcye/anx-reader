import 'package:anx_reader/models/read_theme.dart';

import '../models/book.dart';
import '../models/book_style.dart';
import '../service/book_player/book_player_server.dart';

String generateIndexHtml(
    Book book, BookStyle style, ReadTheme theme, String cfi) {
  String bookPath = 'http://localhost:${Server().port}/book/${book.filePath}';
  String epubJs = 'http://localhost:${Server().port}/js/epub.js';
  String zipJs = 'http://localhost:${Server().port}/js/jszip.min.js';
  String backgroundColor = theme.backgroundColor.substring(2) +
      theme.backgroundColor.substring(0, 2);
  String textColor =
      theme.textColor.substring(2) + theme.textColor.substring(0, 2);
// language=HTML
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
          overflow: hidden;
          margin: 0;
          padding: 0; 
          column-fill: auto;
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
              // 'word-spacing': '${style.wordSpacing}px !important',
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
            await rendition.display('$cfi').then(() => {
              setAllAnnotations();
            });
          } else {
            await rendition.display().then(() => {
              setAllAnnotations();
            });
          }
    
          rendition.on('relocated', function(locations) {
            refreshProgress();
            setClickEvent();
            window.flutter_inappwebview.callHandler('onRelocated', locations.start.index);
          });
        }  

        renderBook()
        
        // Annotation events
        
        // selected text
        var selectedCfiRange = null;
        var selectedText = null;
        rendition.on('selected', (cfiRange, contents) => {
          // console.log('selected', cfiRange);
          // console.log(rendition.getContents()[0].window.getSelection().toString());
    
          selectedCfiRange = cfiRange;
          selectedText = rendition.getContents()[0].window.getSelection().toString();
    
          const debouncedAutoNext = (() => {
            let timeout;
    
            return (cfiRange, wait = 1000, immediate = false) => {
              const later = () => {
                timeout = null;
                const selCfi = new ePub.CFI(cfiRange);
                selCfi.collapse();
                const compare = selCfi.compare(selCfi, rendition.location.end.cfi) >= 0;
                if (compare) rendition.next();
              };
    
              const callNow = immediate && !timeout;
              clearTimeout(timeout);
              timeout = setTimeout(later, wait);
              if (callNow) later();
            };
          })();
    
          debouncedAutoNext(cfiRange);
        });
    
    
        const getRect = (target, frame) => {
          const rect = target.getBoundingClientRect()
          const viewElementRect =
            frame ? frame.getBoundingClientRect() : { left: 0, top: 0 }
          const left = (rect.left + viewElementRect.left) / window.innerWidth
          const right = (rect.right + viewElementRect.left) / window.innerWidth
          const top = (rect.top + viewElementRect.top) / window.innerHeight
          const bottom = (rect.bottom + viewElementRect.top) / window.innerHeight
          // console.log({ left, right, top, bottom })
          // console.log(selectedCfiRange)
          // console.log(selectedText)
          window.flutter_inappwebview.callHandler('onSelected', { left: left, right: right, top: top, bottom: bottom, cfiRange: selectedCfiRange, text: selectedText });
          return { left, right, top, bottom }
        }
    
        // rendition.hooks.content.register((contents, /*view*/) => {
        //   const frame = contents.document.defaultView.frameElement
        //   contents.document.onclick = e => {
        //     const selection = contents.window.getSelection()
        //     const range = selection.getRangeAt(0)
        //     const { left, right, top, bottom } = getRect(range, frame)
        //   }
        // })  
        
        var excerptHandler = function () {
          const frame = rendition.getContents()[0].document.defaultView.frameElement
          const selection = rendition.getContents()[0].window.getSelection()
          const range = selection.getRangeAt(0)
          const { left, right, top, bottom } = getRect(range, frame)
          rendition.getContents()[0].window.getSelection().removeAllRanges()
        }
        
        
        // set annotations
        const getSelections = () => rendition.getContents()
            .map(contents => contents.window.getSelection())
        
        const clearSelection = () => getSelections().forEach(s => s.removeAllRanges())
        
        const selectByCfi = cfi => getSelections().forEach(s => s.addRange(rendition.getRange(cfi)))
        
        var setAllAnnotations = function () {
          window.flutter_inappwebview.callHandler('getAllAnnotations', null);
        };
        
        var addABookNote = function(bookNote){
          var style = bookNote.type === 'highlight'
              ? { fill: '#' + bookNote.color, 'fill-opacity': '0.3', 'mix-blend-mode': 'multiply' }
              : { stroke: '#' + bookNote.color, 'stroke-width': '2px', 'stroke-opacity': '0.8' };
        
          rendition.annotations.add(bookNote.type, bookNote.cfi, {}, function(e) {
            handleAnnoClick(e, bookNote);
          }, 'anx-js-anno', style);
          setClickEvent();
        }
        var eventOfCurrentAnnotation = null;
        var handleAnnoClick = function(e, bookNote) {
          console.log('annotation clicked', e.target);
          x = e.target.getBoundingClientRect().left / window.innerWidth;
          y = e.target.getBoundingClientRect().top / window.innerHeight;
          selectByCfi(bookNote.cfi);
          eventOfCurrentAnnotation = e;
          window.flutter_inappwebview.callHandler('onAnnotationClicked', { x: x, y: y, id: bookNote.id});
        }
        var removeCurrentAnnotations = function() {
          eventOfCurrentAnnotation.target.remove();
        }
        
        
        // set click event
        var setClickEvent = function (annotations) {
          // get current iframe
          var win = rendition.getContents()[0].window;
          win.document.removeEventListener('click', handleClick);
          win.document.addEventListener('click', handleClick);
          // make sure annotations are clickable
          var annotations = document.querySelectorAll('.anx-js-anno');
          annotations.forEach(function (annotation) {
            annotation.style.pointerEvents = 'auto';
          });
        };
        function handleClick(e) {
          var selectedText = e.view.getSelection().toString().length;
          console.log(selectedText);
          console.log(e.target);
      
          if (e.defaultPrevented || selectedText > 0) {
            return;
          }
      
          let width = window.innerWidth;
          let height = window.innerHeight;
      
          let iframeRect = e.view.frameElement.getBoundingClientRect();
          let x = (e.clientX + iframeRect.left + window.screenX) / width;
          let y = (e.clientY + iframeRect.top + window.screenY) / height;
      
          console.log('Clicked outside iframe', x, y);
          window.flutter_inappwebview.callHandler('onTap', { x: x, y: y });
        }
         
      
      </script>
    </body>
  </html>
  ''';
}
