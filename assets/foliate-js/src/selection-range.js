const BLOCK_SELECTOR = 'p,li,blockquote,h1,h2,h3,h4,h5,h6,td,th,pre,figcaption,dd,dt'
const SKIP_SELECTOR = 'script,style,noscript,input,textarea,button,select,[hidden],.anx-translated,.translation'
const WORD_CHAR = /[A-Za-z0-9'\u2019\-]/
const CJK_CHAR = /[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]/
const SENTENCE_END = /[.!?\u3002\uff01\uff1f]/
const TRAILING_PUNCTUATION = /["'\u2019\u201d\u300d\u300f\u3011\uff09)]/
const ABBREVIATIONS = new Set([
  'mr.', 'mrs.', 'ms.', 'dr.', 'prof.', 'sr.', 'jr.', 'st.', 'vs.',
  'etc.', 'e.g.', 'i.e.', 'no.',
])
let nextSelectionSessionId = 0

const selectedRange = doc => {
  const selection = doc.getSelection()
  return selection?.rangeCount && !selection.isCollapsed ? selection.getRangeAt(0) : null
}

const sameRange = (left, right) => Boolean(left && right &&
  left.startContainer === right.startContainer && left.startOffset === right.startOffset &&
  left.endContainer === right.endContainer && left.endOffset === right.endOffset)

const domConstants = doc => ({
  Node: doc.defaultView.Node,
  NodeFilter: doc.defaultView.NodeFilter,
})

const textNodes = root => {
  const doc = root.ownerDocument || root
  const constants = domConstants(doc)
  const walker = doc.createTreeWalker(root, constants.NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      if (!node.nodeValue || !node.nodeValue.trim()) return constants.NodeFilter.FILTER_REJECT
      const parent = node.parentElement
      if (!parent || parent.closest(SKIP_SELECTOR)) return constants.NodeFilter.FILTER_REJECT
      return constants.NodeFilter.FILTER_ACCEPT
    },
  })
  const result = []
  let node
  while ((node = walker.nextNode())) result.push(node)
  return result
}

const buildTextMap = root => {
  const entries = []
  let text = ''
  textNodes(root).forEach(node => {
    const start = text.length
    text += node.nodeValue
    entries.push({ node, start, end: text.length })
  })
  return { text, entries }
}

const buildTextMapFromNodes = nodes => {
  const entries = []
  let text = ''
  nodes.forEach(node => {
    const start = text.length
    text += node.nodeValue
    entries.push({ node, start, end: text.length })
  })
  return { text, entries }
}

const pdfParagraphMap = (textLayer, anchorNode) => {
  const spans = Array.from(textLayer.querySelectorAll('span'))
    .filter(span => span.textContent && span.textContent.trim())
  const anchorElement = anchorNode.parentElement
  const anchorSpan = anchorElement && anchorElement.closest('span')
  const anchorIndex = spans.indexOf(anchorSpan)
  if (anchorIndex < 0) return null
  const belongsToSameBlock = (left, right) => {
    const leftRect = left.getBoundingClientRect()
    const rightRect = right.getBoundingClientRect()
    const lineHeight = Math.max(leftRect.height, rightRect.height, 1)
    const verticalGap = rightRect.top - leftRect.bottom
    return verticalGap <= Math.max(8, lineHeight * 0.9)
  }
  let start = anchorIndex
  let end = anchorIndex
  while (start > 0 && belongsToSameBlock(spans[start - 1], spans[start])) start--
  while (end + 1 < spans.length && belongsToSameBlock(spans[end], spans[end + 1])) end++
  const nodes = spans.slice(start, end + 1).reduce(
    (result, span) => result.concat(textNodes(span)),
    [],
  )
  return nodes.length ? buildTextMapFromNodes(nodes) : null
}

const pointAt = (map, offset, preferEnd) => {
  if (!map.entries.length) return null
  const safe = Math.max(0, Math.min(map.text.length, offset))
  let entryIndex = map.entries.findIndex(item => safe < item.end)
  if (entryIndex < 0) entryIndex = map.entries.length - 1
  if (preferEnd && safe <= map.entries[entryIndex].start && entryIndex > 0) entryIndex--
  const entry = map.entries[entryIndex]
  return {
    node: entry.node,
    offset: Math.max(0, Math.min(entry.node.nodeValue.length, safe - entry.start)),
  }
}

const rangeFromOffsets = (doc, map, start, end) => {
  const startPoint = pointAt(map, start, false)
  const endPoint = pointAt(map, end, true)
  if (!startPoint || !endPoint || end <= start) return null
  const range = doc.createRange()
  range.setStart(startPoint.node, startPoint.offset)
  range.setEnd(endPoint.node, endPoint.offset)
  return range
}

const offsetForPoint = (map, node, offset) => {
  const entry = map.entries.find(item => item.node === node)
  if (entry) return entry.start + offset
  // Visible page ranges can end at an element boundary, not a text node.
  const doc = node.ownerDocument
  if (!doc || !map.entries.length) return -1
  const point = doc.createRange()
  point.setStart(node, offset)
  point.collapse(true)
  for (const item of map.entries) {
    if (point.comparePoint(item.node, 0) >= 0) return item.start
    if (point.comparePoint(item.node, item.node.length) === 0) return item.end
  }
  return map.text.length
}

const caretRangeFromPoint = (doc, x, y) => {
  if (doc.caretRangeFromPoint) return doc.caretRangeFromPoint(x, y)
  if (!doc.caretPositionFromPoint) return null
  const point = doc.caretPositionFromPoint(x, y)
  if (!point) return null
  const range = doc.createRange()
  range.setStart(point.offsetNode, point.offset)
  range.collapse(true)
  return range
}

const nearestBlock = (doc, node) => {
  const element = node.nodeType === domConstants(doc).Node.ELEMENT_NODE ? node : node.parentElement
  if (!element) return null
  // PDF text must remain in its current page's text layer.
  const textLayer = element.closest('.textLayer')
  return textLayer || element.closest(BLOCK_SELECTOR)
}

const wordBounds = (text, offset) => {
  if (!text.length) return null
  const index = Math.max(0, Math.min(text.length - 1, offset === text.length ? offset - 1 : offset))
  if (CJK_CHAR.test(text[index] || '')) return { start: index, end: index + 1, needsDictionary: true }
  if (!WORD_CHAR.test(text[index] || '')) return null
  let start = index
  let end = index + 1
  while (start > 0 && WORD_CHAR.test(text[start - 1])) start--
  while (end < text.length && WORD_CHAR.test(text[end])) end++
  while (start < end && /['\u2019\-]/.test(text[start])) start++
  while (end > start && /['\u2019\-]/.test(text[end - 1])) end--
  return start < end ? { start, end, needsDictionary: false } : null
}

const graphemeSegments = text => {
  if (typeof Intl !== 'undefined' && Intl.Segmenter) {
    return Array.from(new Intl.Segmenter(undefined, { granularity: 'grapheme' }).segment(text),
      item => ({ start: item.index, end: item.index + item.segment.length }))
  }
  // Chrome 83 has no Segmenter. Keep combining marks, variation selectors,
  // emoji modifiers, joined emoji and flag pairs intact without a dependency.
  const result = []
  let cursor = 0
  let previous = ''
  let regionalCount = 0
  for (const char of Array.from(text)) {
    const code = char.codePointAt(0)
    const regional = code >= 0x1F1E6 && code <= 0x1F1FF
    const continuation = /\p{Mark}/u.test(char) || code === 0xFE0F || code === 0xFE0E ||
      (code >= 0x1F3FB && code <= 0x1F3FF) || char === '\u200D' || previous === '\u200D' ||
      (regional && regionalCount % 2 === 1)
    if (continuation && result.length) result[result.length - 1].end = cursor + char.length
    else result.push({ start: cursor, end: cursor + char.length })
    regionalCount = regional ? regionalCount + 1 : 0
    cursor += char.length
    previous = char
  }
  return result
}

const characterBounds = (text, offset) => {
  if (!text.length) return null
  const index = Math.max(0, Math.min(text.length - 1, offset === text.length ? offset - 1 : offset))
  return graphemeSegments(text).find(item => item.start <= index && index < item.end) || null
}

const isSentenceEnd = (text, index) => {
  const char = text[index]
  if (!SENTENCE_END.test(char || '')) return false
  if (char === '.' && /\d/.test(text[index - 1] || '') && /\d/.test(text[index + 1] || '')) return false
  if (char === '.') {
    const match = text.slice(Math.max(0, index - 8), index + 1).toLowerCase().match(/[a-z.]+$/)
    const token = match ? match[0] : ''
    if (ABBREVIATIONS.has(token) || /^[a-z]\.$/.test(token)) return false
  }
  return true
}

const sentenceBounds = (text, offset) => {
  if (!text.trim()) return null
  let start = Math.max(0, Math.min(text.length, offset))
  while (start > 0 && !isSentenceEnd(text, start - 1) && text[start - 1] !== '\n') start--
  while (start < text.length && /\s/.test(text[start])) start++
  let end = Math.max(start, Math.min(text.length, offset))
  while (end < text.length && !isSentenceEnd(text, end) && text[end] !== '\n') end++
  if (end < text.length && isSentenceEnd(text, end)) {
    end++
    while (end < text.length && TRAILING_PUNCTUATION.test(text[end])) end++
  }
  while (end > start && /\s/.test(text[end - 1])) end--
  return start < end ? { start, end } : null
}

const readableBlocks = (doc, current) => {
  const page = current.closest('.page') || current.closest('[data-page-number]')
  const root = current.classList && current.classList.contains('textLayer') ? current : doc
  return Array.from(root.querySelectorAll(BLOCK_SELECTOR + ',.textLayer'))
    .filter(item => item !== current && !item.closest(SKIP_SELECTOR) && item.textContent.trim())
    .filter(item => !page || item.closest('.page') === page || item.closest('[data-page-number]') === page)
}

// Selection never turns a page by dwell time. This adapter is the only
// cross-page path; native range changes remain local and side-effect free.
export const createSelectionPageAdapter = (view, doc, index) => {
  const supported = () => !view.isFixedLayout && !doc.__isFootNote &&
    !doc.querySelector('.textLayer') && view.renderer?.getContents?.().some(item => item.doc === doc && item.index === index)
  const currentRange = () => selectedRange(doc)
  const flow = () => view.renderer?.getAttribute?.('flow') === 'scrolled' ? 'scrolled' : 'paginated'
  const state = () => {
    const renderer = view.renderer
    const selection = currentRange()
    const visible = view.lastLocation?.range
    let sourceProgress = null
    // The visible page-end fraction is safe only when it covers the exact
    // selected end. Never approximate evidence progress from character ratios.
    if (selection && visible && visible.endContainer.ownerDocument === doc &&
        selection.compareBoundaryPoints(doc.defaultView.Range.END_TO_END, visible) <= 0 &&
        Number.isFinite(view.lastLocation.fraction) && view.lastLocation.fraction >= 0 && view.lastLocation.fraction <= 1) sourceProgress = view.lastLocation.fraction
    const supportedLayout = supported()
    let atChapterEnd = !selection
    if (selection) {
      const remainder = doc.createRange()
      remainder.selectNodeContents(doc.body)
      remainder.setStart(selection.endContainer, selection.endOffset)
      atChapterEnd = !remainder.toString().trim()
    }
    const pageAtEnd = renderer && (renderer.scrolled
      ? renderer.viewSize - renderer.end <= 2
      : renderer.page >= renderer.pages - 2)
    return {
      flow: flow(), sourceProgress, visibleFromProgress: sourceProgress,
      canShowSelectionEnd: Boolean(selection && typeof renderer?.scrollToAnchor === 'function'),
      canExtendNextPage: Boolean(supportedLayout && !atChapterEnd && !pageAtEnd),
      extensionUnavailableReason: !supportedLayout ? 'unsupportedLayout' : atChapterEnd || pageAtEnd ? 'chapterEnd' : null,
    }
  }
  return {
    state,
    capture: () => ({ cfi: view.lastLocation?.cfi, range: view.lastLocation?.range?.cloneRange() }),
    showEnd: async range => {
      if (typeof view.renderer?.scrollToAnchor !== 'function') return false
      const endpoint = range.cloneRange()
      endpoint.collapse(false)
      await view.renderer.scrollToAnchor(endpoint)
      return true
    },
    restore: async page => {
      if (page.range?.startContainer.isConnected) await view.renderer.scrollToAnchor(page.range)
      else if (page.cfi) await view.goTo(page.cfi)
    },
    advance: async () => {
      if (!state().canExtendNextPage) return null
      const range = currentRange()?.cloneRange()
      if (!range) return null
      // A paragraph may already span pages: advance from its end, not its start.
      range.collapse(false)
      await view.renderer.scrollToAnchor(range)
      const renderer = view.renderer
      const atEnd = renderer.scrolled ? renderer.viewSize - renderer.end <= 2
        : renderer.page >= renderer.pages - 2
      if (atEnd) return null
      await view.next()
      const visible = view.lastLocation?.range
      return visible?.endContainer.ownerDocument === doc ? visible.cloneRange() : null
    },
  }
}


export class SelectionRangeController {
  constructor({ doc, index, emitSelection, requestWordBoundary, pageAdapter = null, longPressMode = 'word' }) {
    this.doc = doc
    this.index = index
    this.pageAdapter = pageAdapter
    this.revision = 0
    this.extensionHistory = []
    this.extending = false
    this.emitSelection = emitSelection
    this.requestWordBoundary = requestWordBoundary
    this.longPressMode = longPressMode
    this.swipeToTurnPage = false
    this.offlineDictionaryMode = false
    this.sessionId = 0
    this.rangeType = 'custom'
    this.trigger = 'manual'
    this.anchor = null
    this.programmatic = false
    this.lastTouch = null
    this.pendingWordTimer = null
    this.pendingWordRequest = null
    // Android can report the temporary native selection before the configured
    // long-press range (word/sentence) has been applied. Keep that state in
    // the controller so the temporary range never opens a second menu.
    this.nativeSelectionStarted = false
    this.longPressExpandedForTouch = false
    this.lastReportedSelection = null
  }

  configure(config) {
    if (typeof config.swipeToTurnPage === 'boolean') {
      this.swipeToTurnPage = config.swipeToTurnPage
    }
    if (config.longPressMode === 'word' || config.longPressMode === 'sentence') {
      this.longPressMode = config.longPressMode
    }
    if (typeof config.offlineDictionaryMode === 'boolean') {
      this.offlineDictionaryMode = config.offlineDictionaryMode
    }
  }

  install() {
    this.doc.addEventListener('dblclick', event => {
      if (event.button !== 0) return
      if (this.selectAtPoint(event.clientX, event.clientY, 'word', 'doubleTap')) {
        event.preventDefault()
        event.stopPropagation()
        this.doc.__anxSuppressClick = true
      }
    }, true)
    this.doc.addEventListener('touchstart', event => {
      const touch = event.touches && event.touches[0]
      const selection = this.doc.getSelection()
      if (touch) {
        this.longPressExpandedForTouch = false
        if (!selection || selection.isCollapsed) this.nativeSelectionStarted = false
        this.lastTouch = {
          x: touch.clientX,
          y: touch.clientY,
          at: Date.now(),
          hadSelection: Boolean(selection && !selection.isCollapsed),
        }
      }
    }, { passive: true, capture: true })
    this.doc.addEventListener('selectstart', () => {
      if (this.programmatic) return
      if (!this.lastTouch?.hadSelection || !this.sessionId) this.sessionId = ++nextSelectionSessionId
      this.rangeType = 'custom'
      this.trigger = 'manual'
      this.nativeSelectionStarted = false
      this.lastReportedSelection = null
      this.extensionHistory = []
    })
  }

  consumeNavigation() {
    const selection = this.doc.getSelection()
    if (!selection || selection.isCollapsed) return false
    this.lastReportedSelection = null
    this.extensionHistory = []
    this.pendingWordRequest = null
    clearTimeout(this.pendingWordTimer)
    this.revision += 1
    this.doc.__anxSelectionClearedAt = Date.now()
    this.doc.__anxSuppressClick = true
    selection.removeAllRanges()
    return true
  }

  installGestureGuard() {
    const doc = this.doc
    // Capture the gesture which exits selection before paginator listeners,
    // including its trailing synthetic click. Native handle drags remain native.
    let selectionTouch = null
    let sentenceSwipe = null
    const stopGesture = event => {
      event.stopImmediatePropagation()
      if (event.cancelable) event.preventDefault()
    }
    doc.addEventListener('touchstart', event => {
      sentenceSwipe = null
      const range = selectedRange(doc)
      const touch = event.touches?.[0]
      if (!range || !touch) {
        selectionTouch = null
        // A fresh gesture is allowed immediately; only the trailing click of
        // the gesture which dismissed selection must be consumed.
        doc.__anxConsumedSelectionClickUntil = 0
        doc.__anxSuppressClick = false
        doc.__anxSelectionClearedAt = 0
        if (touch && event.touches.length === 1 && !this.swipeToTurnPage &&
            (globalThis.visualViewport?.scale ?? 1) <= 1 &&
            !event.target.closest?.('a,button,input,textarea,select,[contenteditable="true"]')) {
          sentenceSwipe = { x: touch.clientX, y: touch.clientY,
            onText: Boolean(nearestBlock(doc, event.target)), moved: false,
            scrollMode: this.pageAdapter?.state?.().flow === 'scrolled' }
        }
        return
      }
      const nearSelection = Array.from(range.getClientRects()).some(rect =>
        touch.clientX >= rect.left - 28 && touch.clientX <= rect.right + 28 &&
        touch.clientY >= rect.top - 28 && touch.clientY <= rect.bottom + 28)
      selectionTouch = { range: range.cloneRange(), outside: !nearSelection }
      event.stopImmediatePropagation()
      if (!nearSelection) {
        this.consumeNavigation()
        if (event.cancelable) event.preventDefault()
      }
    }, { capture: true, passive: false })
    doc.addEventListener('touchmove', event => {
      if (sentenceSwipe) {
        const touch = event.touches?.[0]
        if (!touch || event.touches.length !== 1 ||
            this.nativeSelectionStarted || selectedRange(doc)) {
          sentenceSwipe = null
        } else {
          const dx = Math.abs(touch.clientX - sentenceSwipe.x)
          const dy = Math.abs(touch.clientY - sentenceSwipe.y)
          if (Math.max(dx, dy) >= 5) {
            // Continuous reading still scrolls vertically. Horizontal swipes
            // select sentences; paginated text accepts either swipe axis.
            if (sentenceSwipe.scrollMode && dy >= dx) sentenceSwipe = null
            else {
              sentenceSwipe.blocked = true
              sentenceSwipe.moved ||= Math.max(dx, dy) >= 24
              stopGesture(event)
              return
            }
          }
        }
      }
      if (!selectionTouch) return
      event.stopImmediatePropagation()
      if (selectionTouch.outside || !this.nativeSelectionStarted) {
        if (event.cancelable) event.preventDefault()
      }
    }, { capture: true, passive: false })
    doc.addEventListener('touchend', event => {
      if (sentenceSwipe?.blocked) {
        const swipe = sentenceSwipe
        sentenceSwipe = null
        if (swipe.moved && swipe.onText && !this.nativeSelectionStarted && !selectedRange(doc)) {
          this.selectAtPoint(swipe.x, swipe.y, 'sentence', 'swipe')
        }
        doc.__anxConsumedSelectionClickUntil = Date.now() + 500
        doc.__anxSuppressClick = true
        stopGesture(event)
        return
      }
      sentenceSwipe = null
      if (!selectionTouch) return
      const current = selectedRange(doc)
      const unchanged = sameRange(current, selectionTouch.range)
      if (selectionTouch.outside || unchanged) {
        this.consumeNavigation()
        doc.__anxConsumedSelectionClickUntil = Date.now() + 500
        stopGesture(event)
      } else event.stopImmediatePropagation()
      selectionTouch = null
    }, { capture: true, passive: false })
    doc.addEventListener('touchcancel', () => {
      selectionTouch = null
      sentenceSwipe = null
    }, true)
    doc.addEventListener('pointerdown', event => {
      if (event.pointerType !== 'mouse' || event.button !== 0) return
      const range = selectedRange(doc)
      if (!range) {
        doc.__anxConsumedSelectionClickUntil = 0
        doc.__anxSuppressClick = false
        doc.__anxSelectionClearedAt = 0
        return
      }
      const nearSelection = Array.from(range.getClientRects()).some(rect =>
        event.clientX >= rect.left - 8 && event.clientX <= rect.right + 8 &&
        event.clientY >= rect.top - 8 && event.clientY <= rect.bottom + 8)
      if (!nearSelection) {
        this.consumeNavigation()
        doc.__anxConsumedSelectionClickUntil = Date.now() + 500
        stopGesture(event)
      }
    }, true)
    const navigationKeys = new Set(['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown',
      'PageUp', 'PageDown', ' ', 'Space', 'AudioVolumeUp', 'AudioVolumeDown'])
    const blockedKeys = new Set()
    doc.addEventListener('keydown', event => {
      const key = event.code || event.key
      if (blockedKeys.has(key)) { stopGesture(event); return }
      if (event.shiftKey || event.ctrlKey || event.metaKey || event.altKey ||
          !navigationKeys.has(event.key) && !navigationKeys.has(event.code)) return
      if (this.consumeNavigation()) {
        blockedKeys.add(key)
        stopGesture(event)
      }
    }, true)
    doc.addEventListener('keyup', event => {
      const key = event.code || event.key
      if (blockedKeys.delete(key)) stopGesture(event)
    }, true)
    doc.defaultView.addEventListener('blur', () => blockedKeys.clear())
    doc.addEventListener('click', event => {
      if (Date.now() < (doc.__anxConsumedSelectionClickUntil || 0)) {
        doc.__anxConsumedSelectionClickUntil = 0
        doc.__anxSuppressClick = false
        doc.__anxSelectionClearedAt = 0
        stopGesture(event)
      }
    }, true)
  }

  markNativeSelectionStarted() {
    this.nativeSelectionStarted = true
  }

  get hasPendingNativeLongPress() {
    return this.nativeSelectionStarted &&
      Boolean(this.lastTouch && !this.lastTouch.hadSelection)
  }

  markManual() {
    if (this.programmatic) return
    this.rangeType = 'custom'
    this.trigger = 'manual'
  }

  expandLongPressSelection() {
    if (this.longPressExpandedForTouch) return false
    if (this.lastTouch && this.lastTouch.hadSelection) return false
    const selection = this.doc.getSelection()
    if (!selection || selection.isCollapsed || !selection.rangeCount) return false
    const range = selection.getRangeAt(0)
    const rect = range.getBoundingClientRect()
    const point = this.lastTouch || { x: rect.left, y: rect.top }
    const wasNativeSelectionStarted = this.nativeSelectionStarted
    this.nativeSelectionStarted = false
    this.longPressExpandedForTouch = true
    const expanded = this.selectAtPoint(point.x, point.y, this.longPressMode, 'longPress')
    if (!expanded) {
      this.nativeSelectionStarted = wasNativeSelectionStarted
      this.longPressExpandedForTouch = false
    }
    return expanded
  }

  shouldSkipDuplicateReport(range) {
    const previous = this.lastReportedSelection
    if (!previous || previous.sessionId !== this.sessionId) return false
    const sameRange = previous.range.startContainer === range.startContainer &&
      previous.range.startOffset === range.startOffset &&
      previous.range.endContainer === range.endContainer &&
      previous.range.endOffset === range.endOffset
    return sameRange
  }

  recordSelectionReport(range) {
    this.revision += 1
    this.lastReportedSelection = {
      sessionId: this.sessionId,
      range: range.cloneRange(),
    }
  }

  selectAtPoint(x, y, type, trigger) {
    const caret = caretRangeFromPoint(this.doc, x, y)
    if (!caret) return false
    const block = nearestBlock(this.doc, caret.startContainer)
    if (!block || block.closest(SKIP_SELECTOR)) return false
    let map = buildTextMap(block)
    const offset = offsetForPoint(map, caret.startContainer, caret.startOffset)
    if (offset < 0) return false
    if (type === 'paragraph' && block.classList.contains('textLayer')) {
      map = pdfParagraphMap(block, caret.startContainer)
      if (!map) return false
    }
    this.anchor = { block, map, offset }
    if (trigger !== 'rangeButton') {
      this.sessionId = ++nextSelectionSessionId
      this.extensionHistory = []
    }
    this.trigger = trigger
    if (type === 'paragraph') return this.applyBounds(0, map.text.length, 'paragraph')
    if (type === 'sentence') {
      const bounds = sentenceBounds(map.text, offset)
      return bounds ? this.applyBounds(bounds.start, bounds.end, 'sentence') : false
    }
    if (type === 'character') {
      const bounds = characterBounds(map.text, offset)
      return bounds ? this.applyBounds(bounds.start, bounds.end, 'character') : false
    }
    const bounds = wordBounds(map.text, offset)
    if (!bounds) return false
    // Long press selects the touched character; dictionary expansion belongs
    // to an explicit range action, independently of connectivity.
    if (trigger === 'longPress' &&
        bounds.needsDictionary) {
      return this.applyBounds(bounds.start, bounds.end, 'character')
    }
    if (!bounds.needsDictionary || !this.requestWordBoundary) {
      return this.applyBounds(bounds.start, bounds.end, 'word')
    }
    const contextStart = Math.max(0, offset - 12)
    const contextEnd = Math.min(map.text.length, offset + 13)
    const requestSession = this.sessionId
    const requestRevision = this.revision
    const requestAnchor = this.anchor
    this.pendingWordRequest = { sessionId: requestSession, revision: requestRevision, anchor: requestAnchor }
    this.requestWordBoundary({
      sessionId: requestSession,
      text: map.text.slice(contextStart, contextEnd),
      offset: offset - contextStart,
    })
    clearTimeout(this.pendingWordTimer)
    this.pendingWordTimer = setTimeout(() => {
      if (this.sessionId === requestSession && this.revision === requestRevision && this.anchor === requestAnchor) this.applyBounds(bounds.start, bounds.end, 'word')
    }, 180)
    return true
  }

  selectOfflineDictionaryAtLastTouch() {
    if (!this.lastTouch) return false
    return this.selectAtPoint(this.lastTouch.x, this.lastTouch.y, 'word', 'longPress')
  }

  applyResolvedWord({ sessionId, startOffset, endOffset }) {
    const pending = this.pendingWordRequest
    if (!this.anchor || sessionId !== this.sessionId || !pending ||
        pending.sessionId !== sessionId || pending.revision !== this.revision || pending.anchor !== this.anchor) return false
    clearTimeout(this.pendingWordTimer)
    const contextStart = Math.max(0, this.anchor.offset - 12)
    return this.applyBounds(contextStart + startOffset, contextStart + endOffset, 'word')
  }

  applyBounds(start, end, type) {
    if (!this.anchor) return false
    const range = rangeFromOffsets(this.doc, this.anchor.map, start, end)
    if (!range || !range.toString().trim()) return false
    return this.applyRange(range, type)
  }

  applyRange(range, type = 'custom') {
    if (!range || range.collapsed || !range.toString().trim()) return false
    this.pendingWordRequest = null
    clearTimeout(this.pendingWordTimer)
    this.programmatic = true
    const selection = this.doc.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
    this.rangeType = type
    this.emitSelection(this)
    setTimeout(() => { this.programmatic = false }, 0)
    return true
  }

  changeRange(type) {
    if (!['character', 'word', 'sentence', 'paragraph'].includes(type)) return false
    const selection = this.doc.getSelection()
    if (!selection || selection.isCollapsed || !selection.rangeCount) return false
    const range = selection.getRangeAt(0)
    const block = nearestBlock(this.doc, range.startContainer)
    if (!block) return false
    let map = buildTextMap(block)
    const offset = offsetForPoint(map, range.startContainer, range.startOffset)
    if (offset < 0) return false
    if (type === 'paragraph' && block.classList.contains('textLayer')) {
      map = pdfParagraphMap(block, range.startContainer)
      if (!map) return false
    }
    this.anchor = { block, map, offset }
    this.trigger = 'rangeButton'
    if (type === 'paragraph') return this.applyBounds(0, map.text.length, type)
    const bounds = type === 'character'
      ? characterBounds(map.text, offset)
      : type === 'word'
        ? wordBounds(map.text, offset)
        : sentenceBounds(map.text, offset)
    if (!bounds) return false
    if (type === 'word' && bounds.needsDictionary && this.requestWordBoundary) {
      return this.selectAtPointFromRange(range, type)
    }
    return this.applyBounds(bounds.start, bounds.end, type)
  }

  selectAtPointFromRange(range, type) {
    const rect = range.getBoundingClientRect()
    return this.selectAtPoint(rect.left + 1, rect.top + Math.min(8, rect.height / 2), type, 'rangeButton')
  }

  adjacentSentence(direction, apply) {
    const selection = this.doc.getSelection()
    if (!selection || selection.isCollapsed || !selection.rangeCount) return false
    const range = selection.getRangeAt(0)
    const block = nearestBlock(this.doc, range.startContainer)
    if (!block) return false
    let map = buildTextMap(block)
    const boundary = direction < 0
      ? offsetForPoint(map, range.startContainer, range.startOffset)
      : offsetForPoint(map, range.endContainer, range.endOffset)
    let probe = direction < 0 ? boundary - 1 : boundary
    while (probe >= 0 && probe < map.text.length && /\s/.test(map.text[probe])) probe += direction
    let bounds = probe >= 0 && probe < map.text.length ? sentenceBounds(map.text, probe) : null
    let targetBlock = block
    if (!bounds) {
      const blocks = readableBlocks(this.doc, block)
      const all = [block].concat(blocks).sort((a, b) => {
        const position = a.compareDocumentPosition(b)
        return position & domConstants(this.doc).Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1
      })
      const targetIndex = all.indexOf(block) + direction
      if (targetIndex < 0 || targetIndex >= all.length) return false
      targetBlock = all[targetIndex]
      map = buildTextMap(targetBlock)
      bounds = sentenceBounds(map.text, direction < 0 ? map.text.length - 1 : 0)
    }
    if (!bounds) return false
    if (!apply) return true
    this.anchor = { block: targetBlock, map, offset: bounds.start }
    this.trigger = direction < 0 ? 'previousSentence' : 'nextSentence'
    return this.applyBounds(bounds.start, bounds.end, 'sentence')
  }

  moveSentence(direction) {
    return this.adjacentSentence(direction < 0 ? -1 : 1, true)
  }

  adjacentCharacter(direction, apply) {
    const selection = this.doc.getSelection()
    if (!selection || selection.isCollapsed || !selection.rangeCount) return false
    const range = selection.getRangeAt(0)
    const block = nearestBlock(this.doc, range.startContainer)
    if (!block) return false
    let targetBlock = block
    let map = buildTextMap(block)
    const boundary = direction < 0
      ? offsetForPoint(map, range.startContainer, range.startOffset) - 1
      : offsetForPoint(map, range.endContainer, range.endOffset)
    const findCharacter = (text, start) => {
      let index = start
      while (index >= 0 && index < text.length) {
        if (!/\s/.test(text[index])) return index
        index += direction
      }
      return -1
    }
    let probe = findCharacter(map.text, boundary)
    if (probe < 0) {
      const blocks = [block].concat(readableBlocks(this.doc, block)).sort((a, b) => {
        const position = a.compareDocumentPosition(b)
        return position & domConstants(this.doc).Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1
      })
      const targetIndex = blocks.indexOf(block) + direction
      if (targetIndex < 0 || targetIndex >= blocks.length) return false
      targetBlock = blocks[targetIndex]
      map = buildTextMap(targetBlock)
      probe = findCharacter(map.text, direction < 0 ? map.text.length - 1 : 0)
    }
    if (probe < 0) return false
    const bounds = characterBounds(map.text, probe)
    if (!bounds) return false
    if (!apply) return true
    this.anchor = { block: targetBlock, map, offset: bounds.start }
    this.trigger = direction < 0 ? 'previousCharacter' : 'nextCharacter'
    return this.applyBounds(bounds.start, bounds.end, 'character')
  }

  moveCharacter(direction) {
    return this.adjacentCharacter(direction < 0 ? -1 : 1, true)
  }

  boundaryMap() {
    const selection = this.doc.getSelection()
    if (!selection || selection.isCollapsed || !selection.rangeCount) return null
    const range = selection.getRangeAt(0)
    const block = nearestBlock(this.doc, range.startContainer)
    // PDF range adjustment stays inside the current page's text layer.
    const root = block?.classList.contains('textLayer') ? block : this.doc.body
    if (!root) return null
    const entries = []
    let text = ''
    let previousBlock = null
    for (const node of textNodes(root)) {
      const currentBlock = nearestBlock(this.doc, node)
      if (previousBlock && currentBlock !== previousBlock) text += '\n'
      const start = text.length
      text += node.nodeValue
      entries.push({ node, start, end: text.length })
      previousBlock = currentBlock
    }
    const map = { text, entries }
    const start = offsetForPoint(map, range.startContainer, range.startOffset)
    const end = offsetForPoint(map, range.endContainer, range.endOffset)
    return start >= 0 && end > start ? { map, start, end, range } : null
  }

  adjustedBoundary(endpoint, direction, unit = 'character', boundaryState = undefined) {
    if (!['start', 'end'].includes(endpoint) || ![-1, 1].includes(Number(direction)) || !['character', 'word', 'sentence'].includes(unit)) return null
    const state = boundaryState === undefined ? this.boundaryMap() : boundaryState
    if (!state) return null
    const { map, start, end } = state
    const current = endpoint === 'start' ? start : end
    const step = direction < 0 ? -1 : 1
    let probe = step < 0 ? current - 1 : current
    while (probe >= 0 && probe < map.text.length && /\s/.test(map.text[probe])) probe += step
    if (probe < 0 || probe >= map.text.length) return null
    const bounds = unit === 'sentence' ? sentenceBounds(map.text, probe)
      : unit === 'word' ? wordBounds(map.text, probe) || characterBounds(map.text, probe)
        : characterBounds(map.text, probe)
    if (!bounds) return null
    const next = step < 0 ? bounds.start : bounds.end
    const nextStart = endpoint === 'start' ? next : start
    const nextEnd = endpoint === 'end' ? next : end
    if (nextStart >= nextEnd || next === current) return null
    return rangeFromOffsets(this.doc, map, nextStart, nextEnd)
  }

  adjustBoundary(endpoint, direction, unit) {
    const range = this.adjustedBoundary(endpoint, direction, unit)
    if (!range) return false
    this.trigger = 'boundaryAdjustment'
    return this.applyRange(range)
  }

  extensionState() {
    const state = this.pageAdapter?.state()
    if (!state) return { canExtendNextPage: false, extensionUnavailableReason: 'unsupportedLayout' }
    return state
  }

  async extendPage() {
    if (this.extending || !this.extensionState().canExtendNextPage) return false
    const selection = this.doc.getSelection()
    if (!selection || selection.isCollapsed || !selection.rangeCount) return false
    const range = selection.getRangeAt(0).cloneRange()
    const sessionId = this.sessionId
    const revision = this.revision
    const page = this.pageAdapter.capture()
    this.extending = true
    try {
      const visible = await this.pageAdapter.advance()
      if (sessionId !== this.sessionId || revision !== this.revision || !sameRange(selectedRange(this.doc), range) || !visible ||
          visible.endContainer.ownerDocument !== this.doc) {
        await this.pageAdapter.restore(page)
        return false
      }
      if (range.compareBoundaryPoints(this.doc.defaultView.Range.END_TO_END, visible) >= 0) {
        await this.pageAdapter.restore(page)
        return false
      }
      const extended = range.cloneRange()
      extended.setEnd(visible.endContainer, visible.endOffset)
      this.extensionHistory.push({ range, page })
      this.trigger = 'extendPage'
      return this.applyRange(extended)
    } catch (error) {
      await this.pageAdapter.restore(page)
      throw error
    } finally {
      this.extending = false
    }
  }

  async undoExtension() {
    if (this.extending || !this.extensionHistory.length) return false
    const previous = this.extensionHistory[this.extensionHistory.length - 1]
    const page = this.pageAdapter.capture()
    const current = selectedRange(this.doc)?.cloneRange()
    const sessionId = this.sessionId
    const revision = this.revision
    this.extending = true
    try {
      await this.pageAdapter.restore(previous.page)
      if (sessionId !== this.sessionId || revision !== this.revision || !sameRange(selectedRange(this.doc), current)) return false
      this.extensionHistory.pop()
      this.trigger = 'undoExtension'
      return this.applyRange(previous.range)
    } catch (error) {
      await this.pageAdapter.restore(page)
      throw error
    } finally {
      this.extending = false
    }
  }

  async showEnd() {
    if (this.extending || !this.pageAdapter?.showEnd) return false
    const current = selectedRange(this.doc)?.cloneRange()
    if (!current) return false
    const revision = this.revision
    const sessionId = this.sessionId
    this.extending = true
    try {
      if (!await this.pageAdapter.showEnd(current)) return false
      if (revision !== this.revision || sessionId !== this.sessionId ||
          !sameRange(selectedRange(this.doc), current)) return false
      // Even the same range needs a fresh report: its end may now be visible,
      // changing the evidence boundary from unknown to safely covered.
      return this.restoreRange(current)
    } finally {
      this.extending = false
    }
  }

  restoreRange(range) {
    if (!range || range.startContainer.ownerDocument !== this.doc || range.endContainer.ownerDocument !== this.doc) return false
    this.lastReportedSelection = null
    return this.applyRange(range, this.rangeType)
  }

  restoreReportedSelection() {
    const range = this.lastReportedSelection?.range
    if (!range || !range.startContainer.isConnected || !range.endContainer.isConnected) return false
    const selection = this.doc.getSelection()
    if (selection && !selection.isCollapsed) return false
    this.programmatic = true
    selection.removeAllRanges()
    selection.addRange(range.cloneRange())
    setTimeout(() => { this.programmatic = false }, 0)
    return true
  }

  snapshot() {
    const selection = this.doc.getSelection()
    const range = selection && !selection.isCollapsed && selection.rangeCount ? selection.getRangeAt(0) : null
    const block = range ? nearestBlock(this.doc, range.startContainer) : null
    const boundaryState = this.boundaryMap()
    return {
      sessionId: this.sessionId,
      revision: this.revision,
      canAdjustStartPrevious: Boolean(this.adjustedBoundary('start', -1, 'character', boundaryState)),
      canAdjustStartNext: Boolean(this.adjustedBoundary('start', 1, 'character', boundaryState)),
      canAdjustEndPrevious: Boolean(this.adjustedBoundary('end', -1, 'character', boundaryState)),
      canAdjustEndNext: Boolean(this.adjustedBoundary('end', 1, 'character', boundaryState)),
      ...this.extensionState(),
      canUndoExtension: this.extensionHistory.length > 0,
      rangeType: this.rangeType,
      trigger: this.trigger,
      canMovePrevious: this.rangeType === 'character'
        ? this.adjacentCharacter(-1, false)
        : this.adjacentSentence(-1, false),
      canMoveNext: this.rangeType === 'character'
        ? this.adjacentCharacter(1, false)
        : this.adjacentSentence(1, false),
      supportsRangeSelection: Boolean(block && buildTextMap(block).entries.length),
    }
  }
}

export const selectionAlgorithms = { characterBounds, wordBounds, sentenceBounds, graphemeSegments }
