import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/utils/get_base_path.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';

String generateIndexHtml(
    Book book, BookStyle style, ReadTheme theme, String cfi) {
  String bookPath =
      'http://localhost:${Server().port}/book/${getBasePath(book.filePath)}';
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
        #viewer {
          // background-color: #$backgroundColor;
          font-family: 'SourceHanSerif' !important;
        }
        @font-face {
          font-family: 'SourceHanSerif';
          src: url('http://localhost:${Server().port}/fonts/SourceHanSerifSC-Regular.otf');
        }
        .epub-container {
          position: relative;
          overflow: hidden;
        }
        .epub-view {
          transition: transform 0.3s ease;
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
    // book style    
        rendition.hooks.render.register(function(contents, view) {
          var doc = contents.document;
          doc.body.style.backgroundColor = 'transparent';
          doc.body.style.paddingTop = '${style.topMargin}px';
          doc.body.style.paddingBottom = '${style.bottomMargin}px';
          doc.body.style.lineHeight = '${style.lineHeight}';
          doc.body.style.letterSpacing = '${style.letterSpacing}px';
          doc.body.style.textAlign = 'justify';
          // image
          var images = doc.querySelectorAll('img');
          images.forEach(function(img) {
            img.style.maxWidth = '-webkit-fill-available';
          });
          // p
          var paragraphs = doc.querySelectorAll('p');
          paragraphs.forEach(function(p) {
            p.style.paddingTop = '${style.paragraphSpacing}px';
            p.style.lineHeight = '${style.lineHeight}';
          });
          // pre
          var pres = doc.querySelectorAll('pre');
          pres.forEach(function(pre) {
            pre.style.whiteSpace = 'pre-wrap';
          });
          // *
          var all = doc.querySelectorAll('*');
          all.forEach(function(e) {
            e.style.fontFamily = 'SourceHanSerif';
          });
        });
        
        
        defaultStyle = function() {
          rendition.themes.fontSize('${style.fontSize}%');
          
          rendition.themes.default({
          // '@font-face': {
          //   'font-family': 'SourceHanSerif',
          //   'src': 'url(http://localhost:${Server().port}/fonts/SourceHanSerifSC-Regular.otf)',
          // },
            'html': {
              'background-color': 'transparent',
              'color': '#$textColor',
            },
            'body': {
              'padding-top': '${style.topMargin}px !important',
              'padding-bottom': '${style.bottomMargin}px !important',
              'line-height': '${style.lineHeight} !important',
              'letter-spacing': '${style.letterSpacing}px !important',
              'text-align': 'justify !important',
            },
            '*': {
              'font-family': 'SourceHanSerif !important',
              'scroll-behavior': 'smooth',
            },
            'p': {
              'padding-top': '${style.paragraphSpacing}px !important',
              'line-height': '${style.lineHeight} !important',
            },
            'pre':{
              'white-space': 'pre-wrap',
            },
            'img':{
              'max-width':'-webkit-fill-available !important',
            }
          });
        }
        defaultStyle();
        
        
        book.ready.then(function() {
          return book.locations.generate(1000); 
        }).then(function(){
          refreshProgress();
        })
    // page navigation  
        function nextPage() {
          animatePageTurn('next', 0, (check) => rendition.next(check), 1);
        }

        function prevPage() {
          animatePageTurn('prev', 0, (check) => rendition.prev(check), 1);
          // rendition.prev();
        }

    // page animation




        let touchStartX = 0;
        let touchStartY = 0;
        let touchStartTime = 0;
        let viewWidth = 0;
        let isAnimating = false;
        let epubContainer = null;
        let startScrollOffset = 0;

        rendition.on('rendered', () => {
          epubContainer = document.querySelector('.epub-container');
          viewWidth = epubContainer.offsetWidth;
        });

        function transformView(offsetX, duration = 0, ease) {
          isAnimating = true;
          console.log('transformView');
          const startScrollLeft = epubContainer.scrollLeft;
          const targetScrollLeft = Math.round((startScrollLeft - offsetX) / viewWidth) * viewWidth;

          if (duration === 0) {
            // epubContainer.scrollLeft = targetScrollLeft;
          } else {
            let start = null;

            function easeInOutCubic(t) {
              return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
            }
            function easeOutQuint(t) {
              return 1 - Math.pow(1 - t, 5);
            }
            
            function step(timestamp) {
              if (!start) start = timestamp;
              const progress = timestamp - start;
              let percentage = progress / duration;

              percentage = ease === 2 ? easeOutQuint(percentage) : 
                                        easeInOutCubic(percentage);

              epubContainer.scrollLeft = startScrollLeft + (targetScrollLeft - startScrollLeft) * percentage;

              if (progress < duration) {
                window.requestAnimationFrame(step);
              }
            }

            window.requestAnimationFrame(step);
          }
          setTimeout(() => {
            isAnimating = false;
          }, duration);
        }

        function animatePageTurn(direction, offset, callback, ease = 2) {
          const endOffset = direction === 'next' ? -(viewWidth - Math.abs(offset)) : (viewWidth - Math.abs(offset));


          const left = Math.round(startScrollOffset / viewWidth) * viewWidth;

          console.log('scrollLeft: ' + epubContainer.scrollLeft)
          console.log('endOffset: ' + endOffset)
          console.log('left: ' + left);
          console.log('width: ' + epubContainer.scrollWidth)

          if (direction === 'next' && left >= epubContainer.scrollWidth - viewWidth) {
            console.log('return next');
            callback(true);
            return;
          } else if (direction === 'prev' && left <= 0) {
            console.log('return prev');
            callback(true);
            return;
          }

          console.log("here");
          callback(false);
          transformView(endOffset, 300, ease);

        }

        rendition.on('touchstart', event => {
          if (isAnimating) return;

          touchStartX = event.changedTouches[0].screenX;
          touchStartY = event.changedTouches[0].screenY;
          startScrollOffset = epubContainer.scrollLeft;

          touchStartTime = event.timeStamp;
          lastX = touchStartX;
        });

        rendition.on('touchmove', event => {
          isAnimating = true;
          const currentX = event.changedTouches[0].screenX;
          epubContainer.scrollLeft = startScrollOffset + touchStartX - event.changedTouches[0].screenX;
          
        });

        rendition.on('touchend', event => {
          isAnimating = false;
          const offsetX = event.changedTouches[0].screenX - touchStartX;
          const offsetY = event.changedTouches[0].screenY - touchStartY;
          const time = event.timeStamp - touchStartTime;
          if (Math.abs(offsetX) + Math.abs(offsetY) < 10) return;

          const speed = Math.abs(offsetX) / time;


          if (Math.abs(offsetX) > Math.abs(offsetY)) {
            if (Math.abs(offsetX) > viewWidth * 0.2 || speed > 0.8) {
              if (offsetX > 0) {
                animatePageTurn('prev', offsetX, (check) => rendition.prev(check));
              } else {
                animatePageTurn('next', offsetX, (check) => rendition.next(check));
              }
            } else {
              transformView(-offsetX, 300, 'ease-out');
            }
          } else {
            if (time < 300 && offsetY < -40) {
              window.flutter_inappwebview.callHandler('showMenu');
            }
            transformView(-offsetX, 300, 'ease-out');
          }

        });

    // get current chapter title    
        getCurrentChapterTitle = function() {
          let toc = book.navigation.toc;
        
          function removeSuffix(obj) {
            if (obj.href && obj.href.includes('#')) {
              obj.href = obj.href.split('#')[0];
            }
            if (obj.subitems) {
              obj.subitems.forEach(removeSuffix);
            }
          }
        
          toc = JSON.parse(JSON.stringify(toc));
          toc.forEach(removeSuffix);
        
          let href = rendition.currentLocation().start.href;
        
          function findChapterLabel(items, href, parentLabels = []) {
            for (let item of items) {
              if (item.href === href) {
                const labels = [...parentLabels, item.label.trim()];
                return labels.join(' / ');
              } else if (item.subitems.length > 0) {
                const subitemLabel = findChapterLabel(item.subitems, href, [...parentLabels, item.label.trim()]);
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
    // refresh progress    
        refreshProgress = function() {
          let progress = book.locations.percentageFromCfi(rendition.currentLocation().start.cfi);
          window.flutter_inappwebview.callHandler('getProgress', progress);
          window.flutter_inappwebview.callHandler('getChapterCurrentPage', rendition.location.start.displayed.page);
          window.flutter_inappwebview.callHandler('getChapterTotalPage', rendition.location.end.displayed.total);
          window.flutter_inappwebview.callHandler('getChapterTitle', getCurrentChapterTitle());
          window.flutter_inappwebview.callHandler('getChapterHref', rendition.currentLocation().start.href);
        }
        
    // render book
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
            if (isAnimating) return;
            defaultStyle();
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
          // console.log('annotation clicked', e.target);
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
          // console.log(selectedText);
          // console.log(e.target);
      
          if (e.defaultPrevented || selectedText > 0) {
            return;
          }
      
          let width = window.innerWidth;
          let height = window.innerHeight;
      
          let iframeRect = e.view.frameElement.getBoundingClientRect();
          let x = (e.clientX + iframeRect.left + window.screenX) / width;
          let y = (e.clientY + iframeRect.top + window.screenY) / height;
      
          // console.log('Clicked outside iframe', x, y);
          window.flutter_inappwebview.callHandler('onTap', { x: x, y: y });
        }
         
      
      </script>
    </body>
  </html>
  ''';
}
