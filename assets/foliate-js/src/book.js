console.log('book.js')
console.log('AnxUA', navigator.userAgent)

import './view.js'
import { FootnoteHandler } from './footnotes.js'
import { Overlayer } from './overlayer.js'
import { collapse, compare, fromRange, toRange } from './epubcfi.js'
const { configure, ZipReader, BlobReader, TextWriter, BlobWriter } =
  await import('./vendor/zip.js')
const { EPUB } = await import('./epub.js')

var isPdf = false;

const getPosition = (target) => {
  const clamp01 = value => Math.min(Math.max(value, 0), 1);

  const frameRect = (framePos, elementRect, scaleX = 1, scaleY = 1) => {
    return {
      left: scaleX * elementRect.left + framePos.left,
      right: scaleX * elementRect.right + framePos.left,
      top: scaleY * elementRect.top + framePos.top,
      bottom: scaleY * elementRect.bottom + framePos.top
    };
  };
  const rootNode = target.getRootNode?.() ?? target?.endContainer?.getRootNode?.();
  const frameElement = rootNode?.defaultView?.frameElement;

  let scaleX = 1, scaleY = 1;
  if (frameElement) {
    const transform = getComputedStyle(frameElement).transform;
    const matches = transform.match(/matrix\((.+)\)/);
    if (matches) {
      [scaleX, , , scaleY] = matches[1].split(/\s*,\s*/).map(Number);
    }
  }

  const frame = frameElement?.getBoundingClientRect() ?? { top: 0, left: 0 };

  const rects = Array.from(target.getClientRects());
  if (!rects.length) {
    return {
      left: 0,
      top: 0,
      right: 0,
      bottom: 0
    };
  }
  const frameRects = rects.map(rect => frameRect(frame, rect, scaleX, scaleY));

  const boundingRect = frameRects.reduce((acc, rect) => ({
    left: Math.min(acc.left, rect.left),
    top: Math.min(acc.top, rect.top),
    right: Math.max(acc.right, rect.right),
    bottom: Math.max(acc.bottom, rect.bottom)
  }), { ...frameRects[0] });

  const screenWidth = window.innerWidth;
  const screenHeight = window.innerHeight;

  return {
    left: clamp01(boundingRect.left / screenWidth),
    top: clamp01(boundingRect.top / screenHeight),
    right: clamp01(boundingRect.right / screenWidth),
    bottom: clamp01(boundingRect.bottom / screenHeight)
  };
};

const getSelectionRange = (selection) => {
  if (!selection?.rangeCount) return null;
  const range = selection.getRangeAt(0);
  return range.collapsed ? null : range;
};

const CONTEXT_WINDOW_CHARS = 120;
const MAX_CONTEXT_CHARS = 600;

const _collapseWhitespace = (text) =>
  typeof text === 'string'
    ? text.replace(/\s+/g, ' ').trim()
    : '';

const _sliceWithWindow = (text, start, end) => {
  if (!text) return '';
  const safeStart = Math.max(0, Math.min(text.length, start));
  const safeEnd = Math.max(safeStart, Math.min(text.length, end));
  return text.slice(safeStart, safeEnd);
};

const buildRangeContextText = (range) => {
  if (!range) return '';

  const selectionText = range.toString().trim();
  const startNode = range.startContainer;
  const endNode = range.endContainer;
  const startText = startNode?.textContent ?? '';
  const endText = endNode?.textContent ?? '';

  let contextText = '';

  if (startNode === endNode) {
    const segment = _sliceWithWindow(
      startText,
      range.startOffset - CONTEXT_WINDOW_CHARS,
      range.endOffset + CONTEXT_WINDOW_CHARS
    );
    contextText = _collapseWhitespace(segment);
  } else {
    const startSegment = _collapseWhitespace(
      _sliceWithWindow(
        startText,
        range.startOffset - CONTEXT_WINDOW_CHARS,
        range.startOffset + CONTEXT_WINDOW_CHARS
      )
    );
    const endSegment = _collapseWhitespace(
      _sliceWithWindow(
        endText,
        range.endOffset - CONTEXT_WINDOW_CHARS,
        range.endOffset + CONTEXT_WINDOW_CHARS
      )
    );
    const parts = [
      startSegment,
      selectionText,
      endSegment
    ].filter(Boolean);
    contextText = parts.join(' ');
  }

  if (!contextText && selectionText) {
    contextText = selectionText;
  }

  contextText = _collapseWhitespace(contextText);

  if (contextText.length > MAX_CONTEXT_CHARS) {
    return contextText.slice(0, MAX_CONTEXT_CHARS);
  }

  return contextText;
};

const handleSelection = (view, doc, index) => {
  const selection = doc.getSelection();
  const range = getSelectionRange(selection);

  if (!range) return;

  const position = getPosition(range);
  const cfi = view.getCFI(index, range);
  const lang = 'en-US'

  let text = selection.toString();
  if (!text) {
    const newSelection = range.startContainer.ownerDocument.getSelection();
    newSelection.removeAllRanges();
    newSelection.addRange(range);
    text = newSelection.toString();
  }

  const contextText = buildRangeContextText(range);

  onSelectionEnd({
    index,
    range,
    lang,
    cfi,
    pos: position,
    text,
    contextText
  });
};

const setSelectionHandler = (view, doc, index) => {
  let hasActiveSelection = false;
  let lastPointerUpRange = null;
  doc.__anxSelectionClearedAt = 0;
  doc.__anxSuppressClick = false;

  // Notify Flutter when the selection collapses so it can hide the context menu.
  const handleSelectionStateChange = () => {
    const selectionRange = getSelectionRange(doc.getSelection());
    if (selectionRange) {
      hasActiveSelection = true;
      doc.__anxSelectionClearedAt = 0;
      doc.__anxSuppressClick = false;
      return;
    }

    if (!hasActiveSelection) return;
    hasActiveSelection = false;
    lastPointerUpRange = null;
    doc.__anxSelectionClearedAt = Date.now();
    doc.__anxSuppressClick = true;
    callFlutter('onSelectionCleared');
  };

  doc.addEventListener('selectionchange', handleSelectionStateChange);

  const rangesEqual = (a, b) => (
    a.startContainer === b.startContainer
    && a.startOffset === b.startOffset
    && a.endContainer === b.endContainer
    && a.endOffset === b.endOffset
  );

  const shouldSkipPointerUp = () => {
    const selectionRange = getSelectionRange(doc.getSelection());
    if (!selectionRange) return false;

    if (lastPointerUpRange && rangesEqual(lastPointerUpRange, selectionRange)) {
      return true;
    }

    lastPointerUpRange = selectionRange.cloneRange();
    return false;
  };

  //    doc.addEventListener('pointerdown', () => isSelecting = true);
  // if macos or iOS
  if (navigator.platform.includes('Mac')
    || navigator.platform.includes('iPhone')
    || navigator.platform.includes('iPad')
  ) {
    doc.addEventListener('pointerup', () => {
      if (shouldSkipPointerUp()) return;
      handleSelection(view, doc, index);
    });
  }
  else if (navigator.platform.includes('Win')) {
    if (navigator.maxTouchPoints > 0) {
      // In Edge, the longpress by touch generates following touch event sequence:
      // pointerover -> enter -> down -> move(n) -> cancel -> out -> leave
      // While on the flutter webview, it generates:
      // pointerover -> enter -> down -> move(n) -> up -> out -> leave
      // Besides above event difference (cancle/up),
      // the touch event is not triggered when change text selection range.
      // Thus cannot use pointerup to detect the end of touch selection.
      // Instead, we use selectionchange event to detect the end of touch selection
      // for Edge and flutter webview.

      // for mouse pointerup, handle selection directly
      doc.addEventListener('pointerup', (e) => {
        if (e.pointerType === 'touch') return;
        if (shouldSkipPointerUp()) return;
        handleSelection(view, doc, index);
      });

      // filter out selectionchange event cause by mouse
      var isMouseSelecting = false;
      doc.addEventListener('pointerdown', (e) => {
        if (e.pointerType !== 'mouse') return;
        isMouseSelecting = true;
      });
      doc.addEventListener('pointerup', (e) => {
        if (e.pointerType !== 'mouse') return;
        isMouseSelecting = false;
      });

      var debounceTimerId = undefined;
      doc.addEventListener('selectionchange', () => {
        if (isMouseSelecting) return;

        const selRange = getSelectionRange(doc.getSelection())
        if (!selRange) return;

        clearTimeout(debounceTimerId);
        let delay = 500;
        debounceTimerId = setTimeout(() => {
          handleSelection(view, doc, index);
        }, delay);
      });

    } else {
      doc.addEventListener('pointerup', () => {
        if (shouldSkipPointerUp()) return;
        handleSelection(view, doc, index);
      });
    }
  }

  else if (navigator.userAgent.includes('Phone; OpenHarmony')) {
    doc.addEventListener('contextmenu', e => {
      e.preventDefault();
    });

    var debounceTimerId = undefined;
    doc.addEventListener('selectionchange', () => {
      const selRange = getSelectionRange(doc.getSelection());
      if (!selRange) return;

      clearTimeout(debounceTimerId);
      // Wait for selection to settle (e.g. 600ms after last change)
      // This handles the case where pointerup/touchend is swallowed by native handles
      debounceTimerId = setTimeout(() => {
        handleSelection(view, doc, index);
      }, 600);
    });
  } else { // Android
    let hasNativeSelectionStarted = false;

    doc.addEventListener('pointerdown', () => {
      hasNativeSelectionStarted = false;
    });

    // When the native selection handles appear, the browser loses control of the pointer
    // This event signals that the user has started dragging handles
    doc.addEventListener('pointercancel', () => {
      hasNativeSelectionStarted = true;
    });

    doc.addEventListener('contextmenu', e => {
      // Allow mouse context menu (if any)
      if (e.pointerType === 'mouse') {
        handleSelection(view, doc, index);
        return;
      }

      // If we haven't lost pointer control yet (no pointercancel),
      // this is the "early" long-press event during drag start.
      // We block it to prevent the custom menu from interfering with the drag.
      if (!hasNativeSelectionStarted) {
        e.preventDefault();
        return;
      }

      // If we have entered native selection mode (pointercancel happened),
      // this contextmenu event is likely triggered by the system or user interaction
      // after the selection phase (e.g. on release). We handle it.
      handleSelection(view, doc, index);
    });
  }
  // doc.addEventListener('selectionchange', () => handleSelection(view, doc, index));

  if (!view.isFixedLayout) {
    // go to the next page when selecting to the end of a page
    // this makes it possible to select across pages

    doc.addEventListener('selectstart', () => {
      const container = view.shadowRoot.querySelector('foliate-paginator').shadowRoot.querySelector("#container");
      if (!container) return;
      globalThis.originalScrollLeft = container.scrollLeft;
    });


    doc.addEventListener('selectionchange', () => {
      if (view.renderer.getAttribute('flow') !== 'paginated') return
      const { lastLocation } = view
      if (!lastLocation) return

      const selRange = getSelectionRange(doc.getSelection())
      if (!selRange) return

      if (globalThis.pageDebounceTimer) {
        clearTimeout(globalThis.pageDebounceTimer);
        globalThis.pageDebounceTimer = null;
      }

      const container = view.shadowRoot.querySelector('foliate-paginator').shadowRoot.querySelector("#container");

      if (selRange.compareBoundaryPoints(Range.END_TO_END, lastLocation.range) >= 0) {
        globalThis.pageDebounceTimer = setTimeout(async () => {
          await view.next();
          globalThis.originalScrollLeft = container.scrollLeft;
          globalThis.pageDebounceTimer = null;
        }, 1000);
        return
      }

      const preventScroll = () => {
        const selRange = getSelectionRange(doc.getSelection());
        if (!selRange || !view.lastLocation || !view.lastLocation.range) return;

        if (view.lastLocation.range.startContainer === selRange.endContainer) {
          container.scrollLeft = globalThis.originalScrollLeft;
        }
      };

      container.addEventListener('scroll', preventScroll);

      doc.addEventListener('pointerup', () => {
        container.removeEventListener('scroll', preventScroll);
      }, { once: true });
    })

  }
}
const isZip = async file => {
  const arr = new Uint8Array(await file.slice(0, 4).arrayBuffer())
  return arr[0] === 0x50 && arr[1] === 0x4b && arr[2] === 0x03 && arr[3] === 0x04
}

const isPDF = async file => {
  const arr = new Uint8Array(await file.slice(0, 5).arrayBuffer())
  return arr[0] === 0x25
    && arr[1] === 0x50 && arr[2] === 0x44 && arr[3] === 0x46
    && arr[4] === 0x2d
}

const makeZipLoader = async file => {
  configure({ useWebWorkers: false })
  const reader = new ZipReader(new BlobReader(file))
  const entries = await reader.getEntries()
  const map = new Map(entries.map(entry => [entry.filename, entry]))
  const load = f => (name, ...args) =>
    map.has(name) ? f(map.get(name), ...args) : null
  const loadText = load(entry => entry.getData(new TextWriter()))
  const loadBlob = load((entry, type) => entry.getData(new BlobWriter(type)))
  const getSize = name => map.get(name)?.uncompressedSize ?? 0
  return { entries, loadText, loadBlob, getSize }
}

const getFileEntries = async entry => entry.isFile ? entry
  : (await Promise.all(Array.from(
    await new Promise((resolve, reject) => entry.createReader()
      .readEntries(entries => resolve(entries), error => reject(error))),
    getFileEntries))).flat()

const makeDirectoryLoader = async entry => {
  const entries = await getFileEntries(entry)
  const files = await Promise.all(
    entries.map(entry => new Promise((resolve, reject) =>
      entry.file(file => resolve([file, entry.fullPath]),
        error => reject(error)))))
  const map = new Map(files.map(([file, path]) =>
    [path.replace(entry.fullPath + '/', ''), file]))
  const decoder = new TextDecoder()
  const decode = x => x ? decoder.decode(x) : null
  const getBuffer = name => map.get(name)?.arrayBuffer() ?? null
  const loadText = async name => decode(await getBuffer(name))
  const loadBlob = name => map.get(name)
  const getSize = name => map.get(name)?.size ?? 0
  return { loadText, loadBlob, getSize }
}

const isCBZ = ({ name, type }) =>
  type === 'application/vnd.comicbook+zip' || name.endsWith('.cbz')

const isFB2 = ({ name, type }) =>
  type === 'application/x-fictionbook+xml' || name.endsWith('.fb2')

const isFBZ = ({ name, type }) =>
  type === 'application/x-zip-compressed-fb2'
  || name.endsWith('.fb2.zip') || name.endsWith('.fbz')

const getView = async file => {
  let book
  if (file.isDirectory) {
    const loader = await makeDirectoryLoader(file)
    const { EPUB } = await import('./epub.js')
    book = await new EPUB(loader).init()
  }
  else if (!file.size) throw new Error('File not found')
  else if (await isZip(file)) {
    const loader = await makeZipLoader(file)
    if (isCBZ(file)) {
      const { makeComicBook } = await import('./comic-book.js')
      book = makeComicBook(loader, file)
    } else if (isFBZ(file)) {
      const { makeFB2 } = await import('./fb2.js')
      const { entries } = loader
      const entry = entries.find(entry => entry.filename.endsWith('.fb2'))
      const blob = await loader.loadBlob((entry ?? entries[0]).filename)
      book = await makeFB2(blob)
    } else {
      book = await new EPUB(loader).init()
    }
  }
  else if (await isPDF(file)) {
    isPdf = true;
    const { makePDF } = await import('./pdf.js')
    book = await makePDF(file)
  }
  else {
    const { isMOBI, MOBI } = await import('./mobi.js')
    if (await isMOBI(file)) {
      const fflate = await import('./vendor/fflate.js')
      book = await new MOBI({ unzlib: fflate.unzlibSync }).open(file)
    } else if (isFB2(file)) {
      const { makeFB2 } = await import('./fb2.js')
      book = await makeFB2(file)
    }
  }
  if (!book) throw new Error('File type not supported')
  const view = document.createElement('foliate-view')
  document.body.append(view)
  await view.open(book)
  return view
}

const getCSS = ({ fontSize,
  fontName,
  fontPath,
  fontWeight,
  letterSpacing,
  spacing,
  textIndent,
  paragraphSpacing,
  fontColor,
  backgroundColor,
  justify,
  textAlign,
  hyphenate,
  writingMode,
  backgroundImage,
  flow,
  customCSS,
  customCSSEnabled,
  useBookStyles,
  headingFontSize,
  codeHighlightTheme
}) => {

  const fontFamily = fontName === 'book' ? '' :
    fontName === 'system' ? 'font-family: system-ui !important;' :
      `font-family: ${fontName} !important;`

  const writingModeCSS = writingMode === 'auto' ? '' : `writing-mode: ${writingMode} !important;`

  const backgroundImageCSS = !backgroundImage || flow || backgroundImage === 'none' ? 'background: none !important;' :
    `background-image: url('${backgroundImage}') !important;
    background-size: 100% 100% !important;
    background-repeat: repeat !important;
    background-attachment: scroll !important; 
    background-position: center center !important;
    background-clip: content-box !important;`


  // Some CSS selectors are inspired by https://github.com/readest/foliate-js
  return `
    @namespace epub "http://www.idpf.org/2007/ops";
    @font-face {
      font-family: ${fontName};
      src: url('${fontPath}');
      font-display: swap;
    }

    html {
        ${writingModeCSS}
        color: ${fontColor} !important;
        ${backgroundImageCSS}
        background-color: transparent !important;
        ${useBookStyles ? '' : `letter-spacing: ${letterSpacing}px;`}
        ${useBookStyles ? '' : `font-size: ${fontSize}em;`}
        orphans: 1;  
        widows: 1;
    }

    body {
        background: none !important;
        background-color: transparent;
        padding: 0;
    }

    body > div:only-of-type,
    body > div:only-of-type > div:only-of-type {
        overflow: visible !important;
    }

    img, svg {
        // height: auto !important;
        // width: auto !important;
        object-fit: contain !important;
        break-inside: avoid !important;
        box-sizing: border-box !important;
        font-size: initial !important;
        // height: initial !important;
        // width: initial !important;
    }

    a:link {
        color:rgb(167, 96, 52) !important;
    }
    
    a > img {
        font-size: ${fontSize}em !important;
    }

    * {
        // line-height: ${spacing}em !important;
        ${fontFamily}
    }

    ${useBookStyles ? '' : `
    h1 { 
        font-size: calc(2em * ${headingFontSize}) !important; 
        line-height: ${spacing} !important;
    }
    h2 { 
        font-size: calc(1.5em * ${headingFontSize}) !important; 
        line-height: ${spacing} !important;
    }
    h3 { 
        font-size: calc(1.17em * ${headingFontSize}) !important; 
        line-height: ${spacing} !important;
    }
    h4 { 
        font-size: calc(1em * ${headingFontSize}) !important; 
        line-height: ${spacing} !important;
    }
    h5 { 
        font-size: calc(0.83em * ${headingFontSize}) !important; 
        line-height: ${spacing} !important;
    }
    h6 { 
        font-size: calc(0.67em * ${headingFontSize}) !important; 
        line-height: ${spacing} !important;
    }
    `}

    p, li, blockquote, dd, div:not(:has(*:not(b, a, em, i, strong, u, span))), font {
        color: ${fontColor} !important;
        ${useBookStyles ? '' : `line-height: ${spacing} !important;`}
        ${useBookStyles ? '' : `font-weight: ${fontWeight} !important;`}
        ${useBookStyles ? '' : `text-align: ${textAlign === 'auto' ? (justify ? 'justify' : 'start') : textAlign};`}
        ${useBookStyles || textIndent < 0 ? '' : 'text-indent: ' + textIndent + 'em !important;'}
        -webkit-hyphens: ${hyphenate ? 'auto' : 'manual'};
        hyphens: ${hyphenate ? 'auto' : 'manual'};
        -webkit-hyphenate-limit-before: 3;
        -webkit-hyphenate-limit-after: 2;
        -webkit-hyphenate-limit-lines: 2;
        hanging-punctuation: allow-end last;
        widows: 2;
        ${useBookStyles ? '' : `margin-block-start: ${paragraphSpacing / 2}em !important;`}
        ${useBookStyles ? '' : `margin-block-end: ${paragraphSpacing / 2}em !important;`}
    }

    .anx-text-center,
    [align="center"],
    [style*="text-align: center"],
    [style*="text-align:center"] {
        text-indent: 0 !important;
    }


    /*  Paragraphs containing only an image — don't change */
    p:has(> img:only-child),
    p:has(> span:only-child > img:only-child),
    p:has(> img:not(.has-text-siblings)),
    p:has(> a:first-child + img:last-child),
    div:has(> img:only-child),
    div:has(> span:only-child > img:only-child),
    div:has(> img:not(.has-text-siblings)),
    div:has(> a:first-child + img:last-child)  {
        text-indent: initial !important;
        font-size: initial !important;
        height: initial !important;
        width: initial !important;
    }

    /*  Paragraphs inside list items — prevent double indentation */
    li > p,
    ol > p,
    ul > p {
        text-indent: 0 !important;
    }
        
    /* prevent the above from overriding the align attribute */
    [align="left"] { text-align: left; }
    [align="right"] { text-align: right; }
    [align="center"] { text-align: center; }
    [align="justify"] { text-align: justify; }

    /* Code highlighting styles */
    pre {
        white-space: pre-wrap !important;
        background: rgba(128, 128, 128, 0.1) !important;
        border-radius: 6px !important;
        padding: 1em !important;
        overflow: visible !important;
        font-family: 'Consolas', 'Monaco', 'Courier New', monospace !important;
        font-size: 0.9em !important;
        line-height: 1.5 !important;
        margin: 0.5em 0 !important;
        /* Allow code blocks to be split across columns/pages in WebKit */
        break-inside: auto !important;
        page-break-inside: auto !important;
        -webkit-column-break-inside: auto !important;
        /* Force block formatting context to allow proper column breaks */
        display: block !important;
        /* Remove any max-height constraints */
        max-height: none !important;
        height: auto !important;
    }
    
    /* Individual lines within code can break across columns */
    pre code {
        display: block !important;
        break-inside: auto !important;
        page-break-inside: auto !important;
        -webkit-column-break-inside: auto !important;
        overflow: visible !important;
        max-height: none !important;
        height: auto !important;
        white-space: pre-wrap !important;
    }
    
    /* Line wrapper for Safari column breaking */
    .anx-code-line {
        display: block !important;
        break-inside: avoid !important;
        page-break-inside: avoid !important;
        -webkit-column-break-inside: avoid !important;
    }
    
    code {
        font-family: 'Consolas', 'Monaco', 'Courier New', monospace !important;
        font-size: 0.9em !important;
        background: rgba(128, 128, 128, 0.15) !important;
        padding: 0.2em 0.4em !important;
        border-radius: 3px !important;
    }
    
    pre > code {
        background: transparent !important;
        padding: 0 !important;
        border-radius: 0 !important;
        font-size: 1em !important;
    }
    
    aside[epub|type~="endnote"],
    aside[epub|type~="footnote"],
    aside[epub|type~="note"],
    aside[epub|type~="rearnote"] {
        display: none;
    }
    
    ${customCSSEnabled && customCSS ? customCSS : ''}
`}

const convertChineseHandler = (mode, doc) => {
  console.log('convertChinese', mode)
  const zh_s = '皑蔼碍爱翱袄奥坝罢摆败颁办绊帮绑镑谤剥饱宝报鲍辈贝钡狈备惫绷笔毕毙闭边编贬变辩辫鳖瘪濒滨宾摈饼拨钵铂驳卜补参蚕残惭惨灿苍舱仓沧厕侧册测层诧搀掺蝉馋谗缠铲产阐颤场尝长偿肠厂畅钞车彻尘陈衬撑称惩诚骋痴迟驰耻齿炽冲虫宠畴踌筹绸丑橱厨锄雏础储触处传疮闯创锤纯绰辞词赐聪葱囱从丛凑窜错达带贷担单郸掸胆惮诞弹当挡党荡档捣岛祷导盗灯邓敌涤递缔点垫电淀钓调迭谍叠钉顶锭订东动栋冻斗犊独读赌镀锻断缎兑队对吨顿钝夺鹅额讹恶饿儿尔饵贰发罚阀珐矾钒烦范贩饭访纺飞废费纷坟奋愤粪丰枫锋风疯冯缝讽凤肤辐抚辅赋复负讣妇缚该钙盖干赶秆赣冈刚钢纲岗皋镐搁鸽阁铬个给龚宫巩贡钩沟构购够蛊顾剐关观馆惯贯广规硅归龟闺轨诡柜贵刽辊滚锅国过骇韩汉阂鹤贺横轰鸿红后壶护沪户哗华画划话怀坏欢环还缓换唤痪焕涣黄谎挥辉毁贿秽会烩汇讳诲绘荤浑伙获货祸击机积饥讥鸡绩缉极辑级挤几蓟剂济计记际继纪夹荚颊贾钾价驾歼监坚笺间艰缄茧检碱硷拣捡简俭减荐槛鉴践贱见键舰剑饯渐溅涧浆蒋桨奖讲酱胶浇骄娇搅铰矫侥脚饺缴绞轿较秸阶节茎惊经颈静镜径痉竞净纠厩旧驹举据锯惧剧鹃绢杰洁结诫届紧锦仅谨进晋烬尽劲荆觉决诀绝钧军骏开凯颗壳课垦恳抠库裤夸块侩宽矿旷况亏岿窥馈溃扩阔蜡腊莱来赖蓝栏拦篮阑兰澜谰揽览懒缆烂滥捞劳涝乐镭垒类泪篱离里鲤礼丽厉励砾历沥隶俩联莲连镰怜涟帘敛脸链恋炼练粮凉两辆谅疗辽镣猎临邻鳞凛赁龄铃凌灵岭领馏刘龙聋咙笼垄拢陇楼娄搂篓芦卢颅庐炉掳卤虏鲁赂禄录陆驴吕铝侣屡缕虑滤绿峦挛孪滦乱抡轮伦仑沦纶论萝罗逻锣箩骡骆络妈玛码蚂马骂吗买麦卖迈脉瞒馒蛮满谩猫锚铆贸么霉没镁门闷们锰梦谜弥觅绵缅庙灭悯闽鸣铭谬谋亩钠纳难挠脑恼闹馁腻撵捻酿鸟聂啮镊镍柠狞宁拧泞钮纽脓浓农疟诺欧鸥殴呕沤盘庞国爱赔喷鹏骗飘频贫苹凭评泼颇扑铺朴谱脐齐骑岂启气弃讫牵扦钎铅迁签谦钱钳潜浅谴堑枪呛墙蔷强抢锹桥乔侨翘窍窃钦亲轻氢倾顷请庆琼穷趋区躯驱龋颧权劝却鹊让饶扰绕热韧认纫荣绒软锐闰润洒萨鳃赛伞丧骚扫涩杀纱筛晒闪陕赡缮伤赏烧绍赊摄慑设绅审婶肾渗声绳胜圣师狮湿诗尸时蚀实识驶势释饰视试寿兽枢输书赎属术树竖数帅双谁税顺说硕烁丝饲耸怂颂讼诵擞苏诉肃虽绥岁孙损笋缩琐锁獭挞抬摊贪瘫滩坛谭谈叹汤烫涛绦腾誊锑题体屉条贴铁厅听烃铜统头图涂团颓蜕脱鸵驮驼椭洼袜弯湾顽万网韦违围为潍维苇伟伪纬谓卫温闻纹稳问瓮挝蜗涡窝呜钨乌诬无芜吴坞雾务误锡牺袭习铣戏细虾辖峡侠狭厦锨鲜纤咸贤衔闲显险现献县馅羡宪线厢镶乡详响项萧销晓啸蝎协挟携胁谐写泻谢锌衅兴汹锈绣虚嘘须许绪续轩悬选癣绚学勋询寻驯训讯逊压鸦鸭哑亚讶阉烟盐严颜阎艳厌砚彦谚验鸯杨扬疡阳痒养样瑶摇尧遥窑谣药爷页业叶医铱颐遗仪彝蚁艺亿忆义诣议谊译异绎荫阴银饮樱婴鹰应缨莹萤营荧蝇颖哟拥佣痈踊咏涌优忧邮铀犹游诱舆鱼渔娱与屿语吁御狱誉预驭鸳渊辕园员圆缘远愿约跃钥岳粤悦阅云郧匀陨运蕴酝晕韵杂灾载攒暂赞赃脏凿枣灶责择则泽贼赠扎札轧铡闸诈斋债毡盏斩辗崭栈战绽张涨帐账胀赵蛰辙锗这贞针侦诊镇阵挣睁狰帧郑证织职执纸挚掷帜质钟终种肿众诌轴皱昼骤猪诸诛烛瞩嘱贮铸筑驻专砖转赚桩庄装妆壮状锥赘坠缀谆浊兹资渍踪综总纵邹诅组钻致钟么为只凶准启板里雳余链泄';
  const zh_t = '皚藹礙愛翺襖奧壩罷擺敗頒辦絆幫綁鎊謗剝飽寶報鮑輩貝鋇狽備憊繃筆畢斃閉邊編貶變辯辮鼈癟瀕濱賓擯餅撥缽鉑駁蔔補參蠶殘慚慘燦蒼艙倉滄廁側冊測層詫攙摻蟬饞讒纏鏟産闡顫場嘗長償腸廠暢鈔車徹塵陳襯撐稱懲誠騁癡遲馳恥齒熾沖蟲寵疇躊籌綢醜櫥廚鋤雛礎儲觸處傳瘡闖創錘純綽辭詞賜聰蔥囪從叢湊竄錯達帶貸擔單鄲撣膽憚誕彈當擋黨蕩檔搗島禱導盜燈鄧敵滌遞締點墊電澱釣調叠諜疊釘頂錠訂東動棟凍鬥犢獨讀賭鍍鍛斷緞兌隊對噸頓鈍奪鵝額訛惡餓兒爾餌貳發罰閥琺礬釩煩範販飯訪紡飛廢費紛墳奮憤糞豐楓鋒風瘋馮縫諷鳳膚輻撫輔賦複負訃婦縛該鈣蓋幹趕稈贛岡剛鋼綱崗臯鎬擱鴿閣鉻個給龔宮鞏貢鈎溝構購夠蠱顧剮關觀館慣貫廣規矽歸龜閨軌詭櫃貴劊輥滾鍋國過駭韓漢閡鶴賀橫轟鴻紅後壺護滬戶嘩華畫劃話懷壞歡環還緩換喚瘓煥渙黃謊揮輝毀賄穢會燴彙諱誨繪葷渾夥獲貨禍擊機積饑譏雞績緝極輯級擠幾薊劑濟計記際繼紀夾莢頰賈鉀價駕殲監堅箋間艱緘繭檢堿鹼揀撿簡儉減薦檻鑒踐賤見鍵艦劍餞漸濺澗漿蔣槳獎講醬膠澆驕嬌攪鉸矯僥腳餃繳絞轎較稭階節莖驚經頸靜鏡徑痙競淨糾廄舊駒舉據鋸懼劇鵑絹傑潔結誡屆緊錦僅謹進晉燼盡勁荊覺決訣絕鈞軍駿開凱顆殼課墾懇摳庫褲誇塊儈寬礦曠況虧巋窺饋潰擴闊蠟臘萊來賴藍欄攔籃闌蘭瀾讕攬覽懶纜爛濫撈勞澇樂鐳壘類淚籬離裏鯉禮麗厲勵礫曆瀝隸倆聯蓮連鐮憐漣簾斂臉鏈戀煉練糧涼兩輛諒療遼鐐獵臨鄰鱗凜賃齡鈴淩靈嶺領餾劉龍聾嚨籠壟攏隴樓婁摟簍蘆盧顱廬爐擄鹵虜魯賂祿錄陸驢呂鋁侶屢縷慮濾綠巒攣孿灤亂掄輪倫侖淪綸論蘿羅邏鑼籮騾駱絡媽瑪碼螞馬罵嗎買麥賣邁脈瞞饅蠻滿謾貓錨鉚貿麽黴沒鎂門悶們錳夢謎彌覓綿緬廟滅憫閩鳴銘謬謀畝鈉納難撓腦惱鬧餒膩攆撚釀鳥聶齧鑷鎳檸獰甯擰濘鈕紐膿濃農瘧諾歐鷗毆嘔漚盤龐國愛賠噴鵬騙飄頻貧蘋憑評潑頗撲鋪樸譜臍齊騎豈啓氣棄訖牽扡釺鉛遷簽謙錢鉗潛淺譴塹槍嗆牆薔強搶鍬橋喬僑翹竅竊欽親輕氫傾頃請慶瓊窮趨區軀驅齲顴權勸卻鵲讓饒擾繞熱韌認紉榮絨軟銳閏潤灑薩鰓賽傘喪騷掃澀殺紗篩曬閃陝贍繕傷賞燒紹賒攝懾設紳審嬸腎滲聲繩勝聖師獅濕詩屍時蝕實識駛勢釋飾視試壽獸樞輸書贖屬術樹豎數帥雙誰稅順說碩爍絲飼聳慫頌訟誦擻蘇訴肅雖綏歲孫損筍縮瑣鎖獺撻擡攤貪癱灘壇譚談歎湯燙濤縧騰謄銻題體屜條貼鐵廳聽烴銅統頭圖塗團頹蛻脫鴕馱駝橢窪襪彎灣頑萬網韋違圍爲濰維葦偉僞緯謂衛溫聞紋穩問甕撾蝸渦窩嗚鎢烏誣無蕪吳塢霧務誤錫犧襲習銑戲細蝦轄峽俠狹廈鍁鮮纖鹹賢銜閑顯險現獻縣餡羨憲線廂鑲鄉詳響項蕭銷曉嘯蠍協挾攜脅諧寫瀉謝鋅釁興洶鏽繡虛噓須許緒續軒懸選癬絢學勳詢尋馴訓訊遜壓鴉鴨啞亞訝閹煙鹽嚴顔閻豔厭硯彥諺驗鴦楊揚瘍陽癢養樣瑤搖堯遙窯謠藥爺頁業葉醫銥頤遺儀彜蟻藝億憶義詣議誼譯異繹蔭陰銀飲櫻嬰鷹應纓瑩螢營熒蠅穎喲擁傭癰踴詠湧優憂郵鈾猶遊誘輿魚漁娛與嶼語籲禦獄譽預馭鴛淵轅園員圓緣遠願約躍鑰嶽粵悅閱雲鄖勻隕運蘊醞暈韻雜災載攢暫贊贓髒鑿棗竈責擇則澤賊贈紮劄軋鍘閘詐齋債氈盞斬輾嶄棧戰綻張漲帳賬脹趙蟄轍鍺這貞針偵診鎮陣掙睜猙幀鄭證織職執紙摯擲幟質鍾終種腫衆謅軸皺晝驟豬諸誅燭矚囑貯鑄築駐專磚轉賺樁莊裝妝壯狀錐贅墜綴諄濁茲資漬蹤綜總縱鄒詛組鑽緻鐘麼為隻兇準啟闆裡靂餘鍊洩';

  const from = mode === 's2t' ? zh_s : zh_t
  const to = mode === 's2t' ? zh_t : zh_s




  const convertTextNode = (node, from, to) => {
    if (node.nodeType === Node.TEXT_NODE) {
      node.textContent = node.textContent.replace(/[\u4e00-\u9fa5]/g, (match) => {
        return to[from.indexOf(match)] ?? match
      });
    } else {
      node.childNodes.forEach(child => convertTextNode(child, from, to));
    }
  };

  doc.body.childNodes.forEach(node => {
    convertTextNode(node, from, to);
  });
}

const bionicReadingHandler = (doc) => {

  return;

};


const readingFeaturesDocHandler = (doc) => {
  if (readingRules.convertChineseMode !== 'none') {
    convertChineseHandler(readingRules.convertChineseMode, doc)
  }
  if (readingRules.bionicReadingMode) {
    bionicReadingHandler(doc)
  }

  // handle text indent and center alignment
  if (style.textIndent > 0) {
    const elements = doc.querySelectorAll('p, div, li, blockquote, dd, font')
    elements.forEach(el => {
      const computedStyle = window.getComputedStyle(el)
      if (computedStyle.textAlign === 'center') {
        el.classList.add('anx-text-center')
      }
    })
  }

  // handle vertical writing mode, replace “”‘’ with 『』「」
  if (style.writingMode.startsWith('vertical') || reader.view.renderer.writingMode.startsWith('vertical')) {
    const replaceQuotes = (node) => {
      if (node.nodeType === Node.TEXT_NODE) {
        node.textContent = node.textContent
          .replace(/“/g, '『')
          .replace(/”/g, '』')
          .replace(/‘/g, '「')
          .replace(/’/g, '」');
      } else {
        node.childNodes.forEach(child => replaceQuotes(child));
      }
    };
    doc.body.childNodes.forEach(node => {
      replaceQuotes(node);
    });
  }
}


const footnoteDialog = document.getElementById('footnote-dialog')
footnoteDialog.style.display = 'none'
footnoteDialog.addEventListener('click', () => {
  // display none
  footnoteDialog.style.display = 'none'
  callFlutter("onFootnoteClose")
})

const replaceFootnote = (view) => {
  clearSelection()
  footnoteDialog.querySelector('main').replaceChildren(view)

  view.addEventListener('load', (e) => {
    const { doc, index } = e.detail
    globalThis.footnoteSelection = () => handleSelection(view, doc, index)
    setSelectionHandler(view, doc, index)
    // convertChineseHandler(convertChineseMode, doc)
    readingFeaturesDocHandler(doc)
    doc.__isFootNote = true


    setTimeout(() => {
      const dialog = document.getElementById('footnote-dialog')
      const content = document.querySelector("#footnote-dialog > main > foliate-view")
        .shadowRoot.querySelector("foliate-paginator")
        .shadowRoot.querySelector("#container > div > iframe")

      dialog.style.display = 'block'

      // dialog.style.width = 'auto'
      // dialog.style.height = 'auto'

      // const contentWidth = content.clientWidth
      // const contentHeight = content.clientHeight

      // const squareSize = contentWidth * contentHeight

      // dialog.style.height = 100 + 'px'
      // dialog.style.width = squareSize / 100 + 'px'

      // if (squareSize > window.innerWidth * 100 * 0.8) {
      //   dialog.style.width = window.innerWidth * 0.8 + 'px'
      //   dialog.style.height = squareSize / (window.innerWidth * 3.0) + 'px'
      // }

      //dialog.style.width = `${Math.min(Math.max(contentWidth, 200), window.innerWidth * 0.8)}px`
      //dialog.style.height = `${Math.min(Math.max(contentHeight, 100), window.innerHeight * 0.8)}px`
    }, 0)
  })

  const { renderer } = view
  renderer.setAttribute('flow', 'scrolled')
  renderer.setAttribute('gap', '5%')
  renderer.setAttribute('top-margin', '0px')
  renderer.setAttribute('bottom-margin', '0px')
  const footNoteStyle = {
    fontSize: style.fontSize,
    fontName: style.fontName,
    fontPath: style.fontPath,
    letterSpacing: style.letterSpacing,
    spacing: style.spacing,
    textIndent: style.textIndent,
    fontColor: style.fontColor,
    backgroundColor: 'transparent',
    justify: true,
    textAlign: style.textAlign,
    hyphenate: true,
    customCSS: style.customCSS,
    customCSSEnabled: style.customCSSEnabled,
    writingMode: style.writingMode,
    useBookStyles: style.useBookStyles,
    headingFontSize: style.headingFontSize,
  }
  renderer.setStyles(getCSS(footNoteStyle))
  // set background color of dialog
  // if #rrggbbaa, replace aa to ee
  footnoteDialog.style.backgroundColor = style.backgroundColor.slice(0, 7) + '33'
}
footnoteDialog.addEventListener('click', e =>
  e.target === footnoteDialog ? footnoteDialog.close() : null)

class Reader {
  annotations = new Map()
  annotationsByValue = new Map()
  #footnoteHandler = new FootnoteHandler()
  #doc
  #index
  #originalContent
  #bookMarkExists = false
  #upTriggered = false
  #bookmarkInfo = {
    exists: false,
    cfi: null,
    id: null,
  }
  #ignoreBookmarkGesture = false
  constructor() {
    this.#footnoteHandler.addEventListener('before-render', e => {
      const { view } = e.detail
      this.setView(view)
      replaceFootnote(view)
    })
    this.#footnoteHandler.addEventListener('render', e => {
      const { view } = e.detail
      footnoteDialog.showModal()
    })
    this.#originalContent = null
  }
  async open(file, cfi) {
    this.view = await getView(file, cfi)

    if (importing) return

    this.view.addEventListener('load', this.#onLoad.bind(this))
    this.view.addEventListener('relocate', this.#onRelocate.bind(this))
    this.view.addEventListener('click-view', this.#onClickView.bind(this))
    this.view.addEventListener('doctouchstart', this.#onTouchStart.bind(this))
    this.view.addEventListener('doctouchmove', this.#onTouchMove.bind(this))
    this.view.addEventListener('doctouchend', this.#onTouchEnd.bind(this))

    setStyle()
    if (!cfi)
      this.view.renderer.next()
    this.setView(this.view)
    await this.view.init({ lastLocation: cfi })

    // set html bg color to grey 
    document.documentElement.style.backgroundColor = 'grey'
  }

  setView(view) {
    view.addEventListener('create-overlay', e => {
      const { index } = e.detail
      const list = this.annotations.get(index)
      if (list) for (const annotation of list)
        this.view.addAnnotation(annotation)
      
      // Apply code highlighting to newly created overlay content
      if (style && style.codeHighlightTheme && style.codeHighlightTheme !== 'off') {
        // Get the document from the overlayer
        const overlayerObj = view.renderer?.getContents()?.find(x => x.index === index && x.overlayer)
        if (overlayerObj && overlayerObj.doc) {
          applyCodeHighlighting(style.codeHighlightTheme, overlayerObj.doc)
        }
      }
    })

    view.addEventListener('draw-annotation', e => {
      const { draw, annotation } = e.detail
      const { color, type } = annotation
      const opts = { color, writingMode: this.view.renderer.writingMode }
      if (type === 'highlight') draw(Overlayer.highlight, { ...opts })
      else if (type === 'underline') draw(Overlayer.underline, { ...opts })
    })

    view.addEventListener('show-annotation', e => {
      const annotation = this.annotationsByValue.get(e.detail.value)
      const pos = getPosition(e.detail.range)
      if (window.getSelection()?.toString()) return
      const contextText = buildRangeContextText(e.detail.range)
      onAnnotationClick({ annotation, pos, contextText })
    })
    view.addEventListener('external-link', e => {
      e.preventDefault()
      onExternalLink(e.detail)
    })

    view.addEventListener('link', e =>
      this.#footnoteHandler.handle(this.view.book, e)?.catch(err => {
        console.warn(err)
        this.view.goTo(e.detail.href)
      }))

    view.history.addEventListener('pushstate', e => {
      callFlutter('onPushState', {
        canGoBack: view.history.canGoBack,
        canGoForward: view.history.canGoForward
      })
    })
    view.addEventListener('click-image', async e => {
      // console.log('click-image', e.detail.img.src)
      const blobUrl = e.detail.img.src
      const blob = await fetch(blobUrl).then(r => r.blob())
      const base64 = await new Promise((resolve, reject) => {
        const reader = new FileReader()
        reader.onloadend = () => resolve(reader.result)
        reader.onerror = reject
        reader.readAsDataURL(blob)
      })
      callFlutter('onImageClick', base64)
    })
  }

  renderAnnotation(annotations) {
    const annos = annotations ?? allAnnotations ?? []
    for (const anno of annos) {
      const { value, type, color, note } = anno
      const annotation = {
        id: anno.id,
        value,
        type,
        color,
        note
      }

      this.addAnnotation(annotation)
    }

  }

  showContextMenu() {
    return handleSelection(this.view, this.#doc, this.#index)
  }

  addAnnotation(annotation) {
    const { value } = annotation
    const spineCode = (value.split('/')[2].split('!')[0] - 2) / 2

    const list = this.annotations.get(spineCode)
    if (list) list.push(annotation)
    else this.annotations.set(spineCode, [annotation])

    this.annotationsByValue.set(value, annotation)

    if (annotation.type === 'bookmark') {
      if (this.#checkBookmark(annotation)) {
        this.#showBookmarkIcon(60)
        this.#bookmarkInfo = {
          exists: true,
          cfi: annotation.value,
          id: annotation.id,
        }
      }
    } else {
      this.view.addAnnotation(annotation)
    }

  }

  #checkCurrentPageBookmark() {
    const spineCode = this.#index
    const list = this.annotations.get(spineCode)
    let found = false
    let bookmark = null
    if (list) {
      for (const bm of list) {
        if (bm.type === 'bookmark') {
          found = this.#checkBookmark(bm) ? true : found
          if (found) {
            bookmark = bm
            this.#showBookmarkIcon(60)
            break
          }
        }
      }
    }

    this.#bookmarkInfo = {
      exists: found,
      cfi: found ? bookmark.value : null,
      id: found ? bookmark.id : null,
    }
    if (!found) {
      this.#hideBookmarkIcon()
    }
  }

  #checkBookmark(bookmark) {
    const currCfi = this.view.lastLocation?.cfi
    const currStart = collapse(currCfi)
    const currEnd = collapse(currCfi, true)

    const bookmarkCfi = bookmark.value
    const bookmarkStart = collapse(bookmarkCfi)

    if (compare(currStart, bookmarkStart) <= 0 &&
      compare(currEnd, bookmarkStart) > 0) {
      return true
    }
  }

  removeAnnotation(cfi) {
    const annotation = this.annotationsByValue.get(cfi)
    if (!annotation) return
    const { value } = annotation
    const spineCode = (value.split('/')[2].split('!')[0] - 2) / 2

    const list = this.annotations.get(spineCode)
    if (list) {
      const index = list.findIndex(a => a.id === annotation.id)
      if (index !== -1) list.splice(index, 1)
    }

    this.annotationsByValue.delete(value)

    this.view.addAnnotation(annotation, true)

    if (annotation.type === 'bookmark' && this.#checkBookmark(annotation)) {
      this.#hideBookmarkIcon()
      this.handleBookmark(true)
      this.#bookmarkInfo = {
        exists: false,
        cfi: null,
        id: null,
      }
    }

  }

  #onLoad({ detail: { doc, index } }) {
    this.#doc = doc
    this.#index = index
    setSelectionHandler(this.view, doc, index)

    // if (!this.#originalContent) {
    // console.log('Saving original content', doc);
    // this.#originalContent = doc.cloneNode(true)
    // console.log('Original content saved', this.#originalContent);
    // }

    this.#saveOriginalContent()

    this.readingFeatures(readingRules)
    
    // Apply code highlighting to newly loaded content
    if (style && style.codeHighlightTheme && style.codeHighlightTheme !== 'off') {
      // console.log('Applying code highlighting to loaded document, theme:', style.codeHighlightTheme)
      applyCodeHighlighting(style.codeHighlightTheme, doc)
    }
  }

  #onRelocate({ detail }) {
    const { cfi, fraction, location, tocItem, pageItem, chapterLocation } = detail
    const loc = pageItem
      ? `Page ${pageItem.label}`
      : `Loc ${location.current}`
    this.#checkCurrentPageBookmark()
    onRelocated({
      cfi,
      fraction,
      loc,
      tocItem,
      pageItem,
      location,
      chapterLocation,
      bookmark: this.#bookmarkInfo,
    })
  }

  #onClickView({ detail: { x, y } }) {
    const selection = this.#doc?.getSelection?.()
    if (selection && getSelectionRange(selection)) {
      return
    }

    if (this.#doc?.__anxSuppressClick) {
      this.#doc.__anxSuppressClick = false;
      return
    }

    // debounce for 200ms after selection cleared
    const lastClearedAt = this.#doc?.__anxSelectionClearedAt ?? 0
    if (lastClearedAt && Date.now() - lastClearedAt < 200) {
      return
    }

    const coordinatesX = x / window.innerWidth
    const coordinatesY = y / window.innerHeight
    onClickView(coordinatesX, coordinatesY)
  }

  get index() {
    return this.#index
  }

  #saveOriginalContent = () => {
    // this.#originalContent = this.#doc.cloneNode(true)

    // save original content
    this.#originalContent = [];
    const walker = document.createTreeWalker(
      this.#doc.body,
      NodeFilter.SHOW_TEXT,
      null,
      false
    );
    while (walker.nextNode()) {
      this.#originalContent.push(walker.currentNode.textContent);
    }
  }

  #restoreOriginalContent = () => {
    // this.#doc.body.innerHTML = this.#originalContent.body.innerHTML

    const walker = document.createTreeWalker(
      this.#doc.body,
      NodeFilter.SHOW_TEXT,
      null,
      false
    );
    let node;
    let index = 0;
    while (node = walker.nextNode()) {
      node.textContent = this.#originalContent[index++];
    }
  }

  readingFeatures = () => {
    this.#restoreOriginalContent()
    readingFeaturesDocHandler(this.#doc)
  }

  getChapterContent = () => {
    return this.#doc.body.textContent
  }

  getChapterContentByHref = async (target, options = {}) => {
    if (!target) return ''
    if (!this.view?.book?.sections) return ''

    const resolved = this.view.resolveNavigation?.(target)
    if (!resolved || resolved.index == null) return ''

    const section = this.view.book.sections[resolved.index]
    if (!section?.createDocument) return ''

    const doc = await section.createDocument()
    let content = doc?.body?.textContent ?? ''

    if (!content) return ''

    const rawMax = options?.maxChars
    const numericMax = rawMax == null ? null : Number(rawMax)
    const maxChars = Number.isFinite(numericMax) && numericMax > 0
      ? Math.floor(numericMax)
      : null

    if (maxChars != null && content.length > maxChars) {
      content = content.slice(0, maxChars)
    }

    return content
  }

  getPreviousContent = (count = 2000) => {
    let currentContainer = this.view.lastLocation?.range?.endContainer?.parentElement;
    if (!currentContainer) return '';

    let text = '';
    while (text.length < count && currentContainer) {
      text = currentContainer.textContent + text;
      currentContainer = currentContainer.previousSibling;
    }

    return text;

  }

  getSelection = () => {
    const selection = this.#doc.getSelection();
    const range = getSelectionRange(selection);
    return range;
  }

  #ignoreTouch = () => {
    return this.view.renderer.scrollProp === 'scrollTop'
  }


  #onTouchStart = ({ detail: e }) => {
    if (this.#ignoreTouch()) return;

    this.#bookMarkExists = !!document.getElementById('bookmark-icon');
    this.#upTriggered = false;

    // Check if touch started from the top 10% of the screen
    // If so, disable bookmark gesture to avoid conflict with system control center
    const touch = e.touch;
    const screenHeight = window.innerHeight;
    const startY = touch?.screenY ?? touch?.clientY ?? 0;
    this.#ignoreBookmarkGesture = startY < screenHeight * 0.1;
  }

  #onTouchMove = ({ detail: e }) => {
    if (this.#ignoreTouch()) return;

    const mainView = this.view.shadowRoot.children[0]
    if (e.touchState.direction === 'vertical') {
      const deltaY = e.touchState.delta.y;

      if (deltaY > 0) {
        // Only show bookmark pull-down UI if touch did not start from top 10%
        if (!this.#ignoreBookmarkGesture) {
          mainView.style.transform = `translateY(${Math.sqrt(deltaY * 50)}px)`;
          this.#showBookmarkIcon(deltaY);
        }
      } else if (deltaY < -60) {
        if (!this.#upTriggered) {
          this.#upTriggered = true;
          window.pullUp()
        }
      }
    }
  }

  #onTouchEnd = ({ detail: e }) => {
    if (this.#ignoreTouch()) {
      if (e.touchState.direction === 'vertical') {
        const renderer = this.view.renderer;
        const scrollTop = renderer.shadowRoot.querySelector('#container').scrollTop;
        const deltaY = e.touchState.delta.y;
        const swipeThreshold = 60;

        if (deltaY > swipeThreshold && scrollTop <= 1) {
          renderer.shadowRoot.querySelector('#container').scrollTop = 0;
          prevPage();
        } else if (deltaY < -swipeThreshold && renderer.viewSize - renderer.end <= 1) {
          nextPage();
        }
        return;
      }
    }

    const mainView = this.view.shadowRoot.children[0]
    if (e.touchState.direction === 'vertical') {
      const deltaY = e.touchState.delta.y;

      if (deltaY < -60) {
        // console.log('UP');
      } else if (deltaY > 60) {
        // Only handle bookmark if touch did not start from top 10% of screen
        if (!this.#ignoreBookmarkGesture) {
          if (this.#bookMarkExists) {
            this.#hideBookmarkIcon();
            this.handleBookmark(true);
          } else {
            this.#showBookmarkIcon(deltaY);
            this.handleBookmark(false);
          }
        }
      } else {
        this.#hideBookmarkIcon();
      }

      mainView.style.transition = 'transform 0.3s ease-out';
      mainView.style.transform = 'translateY(0px)';

      setTimeout(() => {
        mainView.style.transition = '';
      }, 300);
    }
  }

  #showBookmarkIcon = (deltaY) => {
    let bookmarkIcon = document.getElementById('bookmark-icon');

    const bookMarkSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 24"><g data-name="Layer 2"><g data-name="bookmark"><rect width="8" height="24" opacity="0"/><path d="M2 21a1 1 0 0 1-.49-.13A1 1 0 0 1 1 20V5.33A2.28 2.28 0 0 1 3.2 3h1.6A2.28 2.28 0 0 1 7 5.33V20a1 1 0 0 1-.5.86 1 1 0 0 1-1 0L4 19.07l-1.5 1.79A1 1 0 0 1 2 21z" fill="#215a8f"/></g></g></svg>`

    if (!bookmarkIcon) {
      bookmarkIcon = document.createElement('div');
      bookmarkIcon.id = 'bookmark-icon';
      bookmarkIcon.innerHTML = bookMarkSvg;
      bookmarkIcon.style.cssText = `
        height: 80px;
        width: 26px;
        position: fixed;
        top: -16px;
        right: 20px;
        font-size: 24px;
        opacity: 0;
        transition: opacity 0.2s ease;
        z-index: 1000;
        pointer-events: none;
      `;
      document.body.appendChild(bookmarkIcon);
    }

    const opacity = Math.min(deltaY / 60, 1);
    bookmarkIcon.style.opacity = opacity;
  }

  #hideBookmarkIcon = () => {
    const bookmarkIcon = document.getElementById('bookmark-icon');
    if (bookmarkIcon) {
      bookmarkIcon.style.transition = 'opacity 0.3s ease-out';
      bookmarkIcon.style.opacity = '0';

      setTimeout(() => {
        if (bookmarkIcon && bookmarkIcon.parentNode) {
          bookmarkIcon.parentNode.removeChild(bookmarkIcon);
        }
      }, 300);
    }
  }

  handleBookmark = (remove) => {
    const cfi = remove ? this.#bookmarkInfo.cfi : this.view.lastLocation?.cfi

    let content = this.view.lastLocation.range.startContainer.data ?? this.view.lastLocation.range.startContainer.innerText
    content = content.trim()
    if (content.length > 200) {
      content = content.slice(0, 200) + '...'
    }
    const percentage = this.view.lastLocation.fraction

    callFlutter('handleBookmark', {
      remove,
      detail: {
        cfi,
        content,
        percentage
      }
    })
  }

  get toc() {
    const sectionFractions = this.view.getSectionFractions()
    const currentHref = this.view.lastLocation?.tocItem?.href.split('#')[0] ?? 'Not Found'
    let currentChapterIndex = sectionFractions.findIndex(s => s.href === currentHref)
    if (currentChapterIndex === -1) {
      currentChapterIndex = 0;
    }
    const currentSectionStart = sectionFractions[currentChapterIndex]?.fraction || 0
    const nextSectionStart = sectionFractions[currentChapterIndex + 1]?.fraction || 1
    const currentSectionPages = this.view.lastLocation?.chapterLocation.total || 1

    const totalPages = currentSectionPages / (nextSectionStart - currentSectionStart)

    const getFractionByHref = (href) => {
      if (!href) return 0;
      href = href.split('#')[0]
      const section = sectionFractions.find(s => s.href === href)
      return section ? section.fraction : 0
    }

    const buildItems = (item, level) => {
      return item?.map(item => ({
        label: item.label,
        href: item.href,
        id: item.id,
        level,
        startPercentage: getFractionByHref(item.href),
        startPage: Math.ceil(getFractionByHref(item.href) * totalPages),
        subitems: buildItems(item.subitems, level + 1)
      })) || [];
    }
    return buildItems(this.view.book.toc, 1)
  }
}


const open = async (file, cfi) => {
  const reader = new Reader()
  globalThis.reader = reader
  await reader.open(file, cfi)
  
  // Initialize code highlighting if theme is set
  if (style.codeHighlightTheme && style.codeHighlightTheme !== 'off') {
    changeCodeHighlightTheme(style.codeHighlightTheme)
  }
  
  if (!importing) {
    callFlutter('onLoadEnd')
    onSetToc()
    callFlutter('renderAnnotations')
  }
  else { getMetadata() }
}


const callFlutter = (name, data) => {
  // console.log('callFlutter', name, data)
  window.flutter_inappwebview.callHandler(name, data)
}

const setStyle = (oldStyle) => {
  const turn = {
    scroll: false,
    animated: true
  }

  switch (style.pageTurnStyle) {
    case 'slide':
      turn.scroll = false
      turn.animated = true
      break
    case 'scroll':
      turn.scroll = true
      turn.animated = true
      break
    case "noAnimation":
      turn.scroll = false
      turn.animated = false
      break
  }

  reader.view.renderer.setAttribute('flow', turn.scroll ? 'scrolled' : 'paginated')
  reader.view.renderer.setAttribute('top-margin', `${style.topMargin}px`)
  reader.view.renderer.setAttribute('bottom-margin', `${style.bottomMargin}px`)
  reader.view.renderer.setAttribute('gap', `${style.sideMargin}%`)
  reader.view.renderer.setAttribute('background-color', style.backgroundColor)
  reader.view.renderer.setAttribute('max-column-count', style.maxColumnCount)
  reader.view.renderer.setAttribute('column-threshold', `${style.columnThreshold}px`)
  reader.view.renderer.setAttribute('bgimg-url', style.backgroundImage)

  turn.animated ? reader.view.renderer.setAttribute('animated', 'true')
    : reader.view.renderer.removeAttribute('animated')

  const newStyle = {
    fontSize: style.fontSize,
    fontName: style.fontName,
    fontPath: style.fontPath,
    fontWeight: style.fontWeight,
    letterSpacing: style.letterSpacing,
    spacing: style.spacing,
    paragraphSpacing: style.paragraphSpacing,
    textIndent: style.textIndent,
    fontColor: style.fontColor,
    backgroundColor: style.backgroundColor,
    justify: style.justify,
    textAlign: style.textAlign,
    hyphenate: style.hyphenate,
    writingMode: style.writingMode,
    backgroundImage: style.backgroundImage,
    flow: turn.scroll,
    customCSS: style.customCSS,
    customCSSEnabled: style.customCSSEnabled,
    useBookStyles: style.useBookStyles,
    headingFontSize: style.headingFontSize
  }
  reader.view.renderer.setStyles?.(getCSS(newStyle))

  if (!oldStyle) {
    return
  }

  if (oldStyle?.writingMode !== style.writingMode ||
    oldStyle?.pageTurnStyle !== style.pageTurnStyle && [oldStyle?.pageTurnStyle, style.pageTurnStyle].includes('scroll')
  ) {
    refreshLayout()
  }
}

const refreshLayout = () => {
  const cfi = reader.view.lastLocation?.cfi
  window.nextSection().then(() => {
    if (cfi) {
      setTimeout(() => {
        window.goToCfi(cfi)
      }, 0)
    }
  })
}


const onRelocated = (currentInfo) => {
  const chapterTitle = currentInfo.tocItem?.label
  const chapterHref = currentInfo.tocItem?.href
  const chapterTotalPages = currentInfo.chapterLocation.total
  const chapterCurrentPage = currentInfo.chapterLocation.current
  const bookTotalPages = currentInfo.location.total
  const bookCurrentPage = currentInfo.location.current
  const cfi = currentInfo.cfi
  const percentage = currentInfo.fraction

  callFlutter('onRelocated', {
    chapterTitle,
    chapterHref,
    chapterTotalPages,
    chapterCurrentPage,
    bookTotalPages,
    bookCurrentPage,
    cfi,
    percentage,
    bookmark: currentInfo.bookmark,
    writingMode: reader.view.renderer.writingMode,
  })
}

const onAnnotationClick = (annotation) => callFlutter('onAnnotationClick', annotation)

const onClickView = (x, y) => callFlutter('onClick', { x, y })

const onExternalLink = (link) => callFlutter('onExternalLink', link)

const onSetToc = () => callFlutter('onSetToc', reader.toc)

const getMetadata = async () => {
  const cover = await reader.view.book.getCover()
  if (cover) {
    // cover is a blob, so we need to convert it to base64
    const fileReader = new FileReader()
    fileReader.readAsDataURL(cover)
    fileReader.onloadend = () => {
      callFlutter('onMetadata', {
        ...reader.view.book.metadata,
        cover: fileReader.result
      })
    }
  } else {
    callFlutter('onMetadata', {
      ...reader.view.book.metadata,
      cover: null
    })
  }
}

window.refreshToc = () => onSetToc()

window.changeStyle = (newStyle) => {
  const oldStyle = style
  style = { ...style, ...newStyle }
  console.log('changeStyle', JSON.stringify(style))
  setStyle(oldStyle)
  
  // Update code highlighting theme if changed
  if (newStyle.codeHighlightTheme !== undefined) {
    changeCodeHighlightTheme(newStyle.codeHighlightTheme)
  }
}

window.goToHref = href => reader.view.goTo(href)

window.goToCfi = cfi => reader.view.goTo(cfi)

window.goToPercent = percent => reader.view.goToFraction(percent)

window.nextPage = () => reader.view.next()

window.prevPage = () => reader.view.prev()

window.setScroll = () => {
  style.scroll = true
  style.animated = true
  setStyle()
}

window.setPaginated = () => {
  style.scroll = false
  style.animated = true
  setStyle()
}

window.setNoAnimation = () => {
  style.scroll = false
  style.animated = false
  setStyle()
}

const onSelectionEnd = (selection) => {
  if (window.isFootNoteOpen() || isPdf) {
    callFlutter('onSelectionEnd', { ...selection, footnote: true })
  } else {
    callFlutter('onSelectionEnd', { ...selection, footnote: false })
  }
}

window.showContextMenu = () => {
  if (window.isFootNoteOpen()) {
    footnoteSelection()
  } else {
    reader.showContextMenu()
  }
}

window.getSelection = () => reader.getSelection()

window.clearSelection = () => reader.view.deselect()

window.addAnnotation = (annotation) => reader.addAnnotation(annotation)

window.addBookmarkHere = () => reader.handleBookmark(false)

window.removeAnnotation = (cfi) => reader.removeAnnotation(cfi)

window.prevSection = () => reader.view.renderer.prevSection()

window.nextSection = () => reader.view.renderer.nextSection()

window.initTts = () => reader.view.initTTS()

window.ttsStop = () => reader.view.initTTS(true)

window.ttsHere = () => {
  initTts()
  return reader.view.tts.from(reader.view.lastLocation.range)
}

window.ttsFromCfi = async (cfi) => {
  initTts()
  try {
    const resolved = await reader.view.resolveNavigation(cfi)
    if (resolved && resolved.anchor) {
      const contents = reader.view.renderer.getContents()
      const content = contents.find(c => c.index === resolved.index) || contents[0]
      if (content && content.doc) {
        const range = resolved.anchor(content.doc)
        return reader.view.tts.from(range)
      }
    }
  } catch (e) {
    console.error(e)
  }
  return reader.view.tts.from(reader.view.lastLocation.range)
}

window.ttsCurrentDetail = () => {
  initTts()
  return reader.view.tts.currentDetail()
}

window.ttsCollectDetails = (count = 1, includeCurrent = false, offset = 1) => {
  initTts()
  return reader.view.tts.collectDetails(count, { includeCurrent, offset })
}

window.ttsHighlightByCfi = cfi => {
  initTts()
  return reader.view.tts.highlightCfi(cfi)
}

window.ttsNextSection = async () => {
  await nextSection()
  initTts()
  return ttsNext()
}

window.ttsPrevSection = async (last) => {
  await prevSection()
  initTts()
  return last ? reader.view.tts.end() : ttsNext()
}

window.ttsNext = async () => {
  const result = reader.view.tts.next(true)
  if (result) return result
  return await ttsNextSection()
}

window.ttsPrev = () => {
  const result = reader.view.tts.prev(true)
  if (result) return result
  return ttsPrevSection(true)
}

window.ttsPrepare = () => reader.view.tts.prepare()

window.clearSearch = () => reader.view.clearSearch()

window.search = async (text, opts) => {
  opts == null && (opts = {
    'scope': 'book',
    'matchCase': false,
    'matchDiacritics': false,
    'matchWholeWords': false,
  })
  const query = text.trim()
  if (!query) return

  const index = opts.scope === 'section' ? reader.index : null

  for await (const result of reader.view.search({ ...opts, query, index })) {
    if (result === 'done') {
      callFlutter('onSearch', { process: 1.0 })
    }
    else if ('progress' in result)
      callFlutter('onSearch', { process: result.progress })
    else {
      callFlutter('onSearch', result)
    }
  }
}

window.back = () => reader.view.history.back()

window.forward = () => reader.view.history.forward()

window.renderAnnotations = (annotations) => reader.renderAnnotation(annotations)

window.theChapterContent = () => reader.getChapterContent()

window.previousContent = (count = 2000) => reader.getPreviousContent(count)

window.getChapterContentByHref = async (href, opts) =>
  reader.getChapterContentByHref(href, opts)

// window.convertChinese = (mode) => reader.convertChinese(mode)

// window.bionicReading = (enable) => reader.bionicReading(enable)

window.isFootNoteOpen = () => footnoteDialog.getAttribute('style').includes('display: block')

window.closeFootNote = () => {
  // set zindex to 0
  footnoteDialog.style.display = 'none'
  callFlutter("onFootnoteClose")
}

window.readingFeatures = (rules) => {
  readingRules = { ...readingRules, ...rules }
  reader.readingFeatures()
}

window.pullUp = () => {
  callFlutter('onPullUp')
}

// Code highlighting management
const CodeHighlighter = (() => {
  // Private state
  let currentTheme = null
  let prismLoaded = false
  let prismLoading = null // Promise for loading, to avoid duplicate loads
  const LOAD_TIMEOUT = 10000 // 10 seconds timeout
  const MAX_RETRIES = 2
  const PRISM_BASE_PATH = '/foliate-js/src/vendor/prism'
  
  // Track which documents have been processed to avoid duplicate work
  const processedDocs = new WeakSet()
  
  /**
   * Load a script with timeout and retry support
   */
  const loadScript = (src, timeout = LOAD_TIMEOUT) => {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = src
      
      const timeoutId = setTimeout(() => {
        reject(new Error(`Script load timeout: ${src}`))
      }, timeout)
      
      script.onload = () => {
        clearTimeout(timeoutId)
        resolve()
      }
      
      script.onerror = (error) => {
        clearTimeout(timeoutId)
        reject(new Error(`Failed to load script: ${src}`))
      }
      
      document.head.appendChild(script)
    })
  }
  
  /**
   * Load Prism.js library with retry support
   */
  const loadPrismLibrary = async (retryCount = 0) => {
    if (prismLoaded) return true
    
    // If already loading, wait for that promise
    if (prismLoading) {
      return prismLoading
    }
    
    prismLoading = (async () => {
      try {
        // Load Prism core
        await loadScript(`${PRISM_BASE_PATH}/prism-core.min.js`)
        // Load autoloader plugin
        await loadScript(`${PRISM_BASE_PATH}/prism-autoloader.min.js`)
        // Configure autoloader
        if (window.Prism?.plugins?.autoloader) {
          window.Prism.plugins.autoloader.languages_path = `${PRISM_BASE_PATH}/components/`
        } else {
          throw new Error('Prism autoloader not available after loading')
        }
        prismLoaded = true
        return true
      } catch (error) {
        console.error('[CodeHighlighter] Load error:', error.message)
        
        if (retryCount < MAX_RETRIES) {
          prismLoading = null
          return loadPrismLibrary(retryCount + 1)
        }
        
        console.error('[CodeHighlighter] Max retries reached, giving up')
        prismLoading = null
        return false
      }
    })()
    
    return prismLoading
  }

  /**
   * Get theme CSS URL
   */
  const getThemeCssUrl = (theme) => {
    if (!theme || theme === 'off') return null
    const cssFile = theme === 'default' 
      ? 'prism-default.min.css' 
      : `prism-${theme}.min.css`
    return new URL(`${PRISM_BASE_PATH}/themes/${cssFile}`, window.location.origin).href
  }
  
  /**
   * Inject or update theme CSS in a document
   */
  const injectThemeCss = (doc, theme) => {
    if (!doc?.head) return false
    
    // Remove existing theme
    const existingLink = doc.getElementById('prism-theme')
    if (existingLink) {
      existingLink.remove()
    }
    
    if (!theme || theme === 'off') return true
    
    const cssUrl = getThemeCssUrl(theme)
    if (!cssUrl) return false
    
    const link = doc.createElement('link')
    link.id = 'prism-theme'
    link.rel = 'stylesheet'
    link.href = cssUrl
    doc.head.appendChild(link)
    
    return true
  }
  
  /**
   * Detect programming language from element attributes and class names
   */
  const detectLanguage = (element) => {
    // Check data-language attribute
    const dataLang = element.getAttribute('data-language')
    if (dataLang) return dataLang.toLowerCase()
    
    // Check class names for language-xxx pattern
    const classMatch = element.className.match(/(?:^|\s)(?:language|lang)-(\w+)/)
    if (classMatch) return classMatch[1].toLowerCase()
    
    // Check type attribute (some epub use this)
    const typeAttr = element.getAttribute('type')
    if (typeAttr) {
      const typeMatch = typeAttr.match(/(?:text|application)\/(\w+)/)
      if (typeMatch) return typeMatch[1].toLowerCase()
    }
    
    // Check parent element for language hints
    const parent = element.parentElement
    if (parent) {
      const parentLang = parent.getAttribute('data-language') || 
                         parent.className.match(/(?:^|\s)(?:language|lang)-(\w+)/)?.[1]
      if (parentLang) return parentLang.toLowerCase()
    }
    
    // Default fallback - let Prism auto-detect or use plaintext
    return null
  }
  
  /**
   * Highlight a single code block
   */
  const highlightBlock = (block, doc) => {
    if (block.classList.contains('prism-highlighted')) return false
    
    try {
      // Detect language
      const lang = detectLanguage(block)
      if (lang && !block.classList.contains(`language-${lang}`)) {
        block.classList.add(`language-${lang}`)
      }
      
      window.Prism.highlightElement(block)
      block.classList.add('prism-highlighted')
      return true
    } catch (error) {
      console.warn('[CodeHighlighter] Failed to highlight block:', error.message)
      return false
    }
  }
  
  /**
   * Convert <pre> blocks without <code> children to proper structure
   */
  const normalizePreBlock = (preBlock, doc) => {
    if (preBlock.querySelector('code')) return null // Already has code child
    if (preBlock.classList.contains('prism-highlighted')) return null
    
    const lang = detectLanguage(preBlock) || 'plaintext'
    
    // Create a code element and move content into it
    const codeElement = doc.createElement('code')
    codeElement.className = `language-${lang}`
    codeElement.innerHTML = preBlock.innerHTML
    preBlock.innerHTML = ''
    preBlock.appendChild(codeElement)
    preBlock.classList.add(`language-${lang}`)
    
    return codeElement
  }
  
  /**
   * Apply code highlighting to a document
   * Uses requestIdleCallback for non-blocking processing of large code blocks
   */
  const applyHighlighting = async (theme, doc = document) => {
    if (!theme || theme === 'off' || !doc) return
    
    // Skip if already processed and theme hasn't changed
    if (processedDocs.has(doc) && theme === currentTheme) {
      return
    }
    
    // Find all code blocks
    const preCodeBlocks = Array.from(doc.querySelectorAll('pre code'))
    const preOnlyBlocks = Array.from(
      doc.querySelectorAll('pre.snippet, pre.code, pre[class*="language-"], pre[data-language]')
    )
    
    const totalBlocks = preCodeBlocks.length + preOnlyBlocks.length
    if (totalBlocks === 0) {
      processedDocs.add(doc)
      return
    }
    
    // Inject theme CSS for iframe documents
    if (doc !== document) {
      injectThemeCss(doc, theme)
    }
    
    // Ensure Prism is loaded
    const loaded = await loadPrismLibrary()
    if (!loaded || !window.Prism) {
      console.error('[CodeHighlighter] Prism not available, skipping highlighting')
      return
    }
    
    let highlightedCount = 0
    
    // Process pre-only blocks first (normalize to pre>code structure)
    for (const preBlock of preOnlyBlocks) {
      const codeElement = normalizePreBlock(preBlock, doc)
      if (codeElement) {
        preCodeBlocks.push(codeElement)
      }
    }
    
    // Highlight all code blocks
    // For large numbers of blocks, use chunked processing to avoid blocking
    const CHUNK_SIZE = 10
    
    for (let i = 0; i < preCodeBlocks.length; i += CHUNK_SIZE) {
      const chunk = preCodeBlocks.slice(i, i + CHUNK_SIZE)
      
      for (const block of chunk) {
        if (highlightBlock(block, doc)) {
          highlightedCount++
        }
      }
      
      // Yield to the browser between chunks for large files
      if (preCodeBlocks.length > CHUNK_SIZE && i + CHUNK_SIZE < preCodeBlocks.length) {
        await new Promise(resolve => setTimeout(resolve, 0))
      }
    }
    
    processedDocs.add(doc)
  }

  /**
   * Get all iframe documents from the reader view
   */
  const getAllIframeDocs = () => {
    const iframeDocs = []
    
    // Get documents from the reader's view renderer
    if (globalThis.reader?.view?.renderer?.getContents) {
      const contents = globalThis.reader.view.renderer.getContents() || []
      contents.forEach((content, index) => {
        if (content?.doc) {
          iframeDocs.push({ doc: content.doc, name: `view-content-${index}` })
        }
      })
    }
    
    // Fallback: query iframes directly
    document.querySelectorAll('iframe').forEach((iframe, index) => {
      try {
        const doc = iframe.contentDocument || iframe.contentWindow?.document
        if (doc && !iframeDocs.find(d => d.doc === doc)) {
          iframeDocs.push({ doc, name: `iframe-${index}` })
        }
      } catch (e) {
        // Cross-origin iframe, ignore
      }
    })
    
    return iframeDocs
  }
  
  /**
   * Change the code highlighting theme
   */
  const changeTheme = async (theme) => {
    if (theme === currentTheme) return

    const oldTheme = currentTheme
    currentTheme = theme
    
    // Update main document
    injectThemeCss(document, theme)
    
    if (theme === 'off') return
    
    // Update all iframe documents
    const iframeDocs = getAllIframeDocs()
    
    for (const { doc, name } of iframeDocs) {
      // Update theme CSS
      injectThemeCss(doc, theme)
      
      // Clear processed flag to allow re-highlighting
      processedDocs.delete(doc)
      
      // Clear prism-highlighted flags so blocks can be re-highlighted with new theme
      doc.querySelectorAll('.prism-highlighted').forEach(el => {
        el.classList.remove('prism-highlighted')
      })
      
      // Re-apply highlighting
      await applyHighlighting(theme, doc)
    }
  }
  
  /**
   * Get current theme
   */
  const getTheme = () => currentTheme
  
  /**
   * Check if Prism is loaded
   */
  const isLoaded = () => prismLoaded
  
  /**
   * Reset processed state for a document (useful when content changes)
   */
  const resetDocument = (doc) => {
    processedDocs.delete(doc)
  }
  
  // Public API
  return {
    loadPrismLibrary,
    applyHighlighting,
    changeTheme,
    getTheme,
    isLoaded,
    resetDocument,
    injectThemeCss
  }
})()

// Backward-compatible function aliases
const applyCodeHighlighting = (theme, doc) => CodeHighlighter.applyHighlighting(theme, doc)
const changeCodeHighlightTheme = (theme) => CodeHighlighter.changeTheme(theme)

window.initCodeHighlighting = (theme) => {
  changeCodeHighlightTheme(theme)
}

// get varible from url
var urlParams = new URLSearchParams(window.location.search)
var importing = JSON.parse(urlParams.get('importing'))
var url = JSON.parse(urlParams.get('url'))
var initialCfi = JSON.parse(urlParams.get('initialCfi'))
var style = JSON.parse(urlParams.get('style'))
var readingRules = JSON.parse(urlParams.get('readingRules'))

fetch(url)
  .then(res => res.blob())
  .then(blob => open(new File([blob], new URL(url, window.location.origin).pathname), initialCfi))
  .catch(e => console.error(e))
