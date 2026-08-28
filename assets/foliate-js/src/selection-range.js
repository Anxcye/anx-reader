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
  if (preferEnd && safe === map.entries[entryIndex].start && entryIndex > 0) entryIndex--
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
  return entry ? entry.start + offset : -1
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

export class SelectionRangeController {
  constructor({ doc, index, emitSelection, requestWordBoundary, longPressMode = 'sentence' }) {
    this.doc = doc
    this.index = index
    this.emitSelection = emitSelection
    this.requestWordBoundary = requestWordBoundary
    this.longPressMode = longPressMode
    this.sessionId = 0
    this.rangeType = 'custom'
    this.trigger = 'manual'
    this.anchor = null
    this.programmatic = false
    this.lastTouch = null
    this.pendingWordTimer = null
    // Android can report the temporary native selection before the configured
    // long-press range (word/sentence) has been applied. Keep that state in
    // the controller so the temporary range never opens a second menu.
    this.nativeSelectionStarted = false
    this.longPressExpandedForTouch = false
    this.lastReportedSelection = null
  }

  configure(config) {
    if (config.longPressMode === 'word' || config.longPressMode === 'sentence') {
      this.longPressMode = config.longPressMode
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
      this.sessionId = ++nextSelectionSessionId
      this.rangeType = 'custom'
      this.trigger = 'manual'
      this.nativeSelectionStarted = false
      this.lastReportedSelection = null
    })
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
    this.sessionId = ++nextSelectionSessionId
    this.trigger = trigger
    if (type === 'paragraph') return this.applyBounds(0, map.text.length, 'paragraph')
    if (type === 'sentence') {
      const bounds = sentenceBounds(map.text, offset)
      return bounds ? this.applyBounds(bounds.start, bounds.end, 'sentence') : false
    }
    const bounds = wordBounds(map.text, offset)
    if (!bounds) return false
    if (!bounds.needsDictionary || !this.requestWordBoundary) {
      return this.applyBounds(bounds.start, bounds.end, 'word')
    }
    const contextStart = Math.max(0, offset - 12)
    const contextEnd = Math.min(map.text.length, offset + 13)
    const requestSession = this.sessionId
    this.requestWordBoundary({
      sessionId: requestSession,
      text: map.text.slice(contextStart, contextEnd),
      offset: offset - contextStart,
    })
    clearTimeout(this.pendingWordTimer)
    this.pendingWordTimer = setTimeout(() => {
      if (this.sessionId === requestSession) this.applyBounds(bounds.start, bounds.end, 'word')
    }, 180)
    return true
  }

  applyResolvedWord({ sessionId, startOffset, endOffset }) {
    if (!this.anchor || sessionId !== this.sessionId) return false
    clearTimeout(this.pendingWordTimer)
    const contextStart = Math.max(0, this.anchor.offset - 12)
    return this.applyBounds(contextStart + startOffset, contextStart + endOffset, 'word')
  }

  applyBounds(start, end, type) {
    if (!this.anchor) return false
    const range = rangeFromOffsets(this.doc, this.anchor.map, start, end)
    if (!range || !range.toString().trim()) return false
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
    if (!['word', 'sentence', 'paragraph'].includes(type)) return false
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
    const bounds = type === 'word' ? wordBounds(map.text, offset) : sentenceBounds(map.text, offset)
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

  snapshot() {
    const selection = this.doc.getSelection()
    const range = selection && !selection.isCollapsed && selection.rangeCount ? selection.getRangeAt(0) : null
    const block = range ? nearestBlock(this.doc, range.startContainer) : null
    return {
      sessionId: this.sessionId,
      rangeType: this.rangeType,
      trigger: this.trigger,
      canMovePrevious: this.adjacentSentence(-1, false),
      canMoveNext: this.adjacentSentence(1, false),
      supportsRangeSelection: Boolean(block && buildTextMap(block).entries.length),
    }
  }
}

export const selectionAlgorithms = { wordBounds, sentenceBounds }
