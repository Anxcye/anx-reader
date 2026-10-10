const wait = ms => new Promise(resolve => setTimeout(resolve, ms))

// Page turns are driven by a transform on the view element instead of native
// scrolling, so the browser must not pan the paginated axis by itself.
const TOUCH_ACTION_SUPPORTED = (() => {
  try {
    return !!globalThis.CSS?.supports?.('touch-action', 'pan-y pinch-zoom')
  } catch {
    return false
  }
})()
const HAS_WAAPI = typeof Element !== 'undefined'
  && typeof Element.prototype.animate === 'function'

// approximation of `easeOutSine`, which page turns have always used
const EASE_OUT_SINE_BEZIER = [0.61, 1, 0.88, 1]

// cubic-bezier timing function, only used by the rAF fallback
const cubicBezier = (x1, y1, x2, y2) => {
  const f = (a, b, t) => 3 * a * t * (1 - t) * (1 - t) + 3 * b * t * t * (1 - t) + t * t * t
  return x => {
    if (x <= 0) return 0
    if (x >= 1) return 1
    let lo = 0, hi = 1, t = x
    for (let i = 0; i < 24; i++) {
      const v = f(x1, x2, t)
      if (Math.abs(v - x) < 1e-4) break
      if (v < x) lo = t
      else hi = t
      t = (lo + hi) / 2
    }
    return f(y1, y2, t)
  }
}

const translateCss = (axis, px) => axis === 'x'
  ? `translate3d(${px}px, 0, 0)` : `translate3d(0, ${px}px, 0)`

// identifies a non-collapsed selection, to notice a touch that selects text
const selectionKey = doc => {
  const sel = doc?.getSelection?.()
  if (!sel || sel.isCollapsed || !sel.rangeCount) return null
  return [sel.anchorNode, sel.anchorOffset, sel.focusNode, sel.focusOffset]
}
const sameSelection = (a, b) => a === b
  || (!!a && !!b && a.every((x, i) => x === b[i]))

const parseTranslate = (transform, axis) => {
  if (!transform || transform === 'none') return 0
  const m = transform.match(/matrix(3d)?\(([^)]+)\)/)
  if (!m) return 0
  const v = m[2].split(',').map(Number)
  const value = m[1] ? v[axis === 'x' ? 12 : 13] : v[axis === 'x' ? 4 : 5]
  return Number.isFinite(value) ? value : 0
}

// collapsed range doesn't return client rects sometimes (or always?)
// try make get a non-collapsed range or element
const uncollapse = range => {
  if (!range?.collapsed) return range
  const { endOffset, endContainer } = range
  if (endContainer.nodeType === 1) return endContainer
  if (endOffset + 1 < endContainer.length) range.setEnd(endContainer, endOffset + 1)
  else if (endOffset > 1) range.setStart(endContainer, endOffset - 1)
  else return endContainer.parentNode
  return range
}

const makeRange = (doc, node, start, end = start) => {
  const range = doc.createRange()
  range.setStart(node, start)
  range.setEnd(node, end)
  return range
}

// use binary search to find an offset value in a text node
const bisectNode = (doc, node, cb, start = 0, end = node.nodeValue.length) => {
  if (end - start === 1) {
    const result = cb(makeRange(doc, node, start), makeRange(doc, node, end))
    return result < 0 ? start : end
  }
  const mid = Math.floor(start + (end - start) / 2)
  const result = cb(makeRange(doc, node, start, mid), makeRange(doc, node, mid, end))
  return result < 0 ? bisectNode(doc, node, cb, start, mid)
    : result > 0 ? bisectNode(doc, node, cb, mid, end) : mid
}

const { SHOW_ELEMENT, SHOW_TEXT, SHOW_CDATA_SECTION,
  FILTER_ACCEPT, FILTER_REJECT, FILTER_SKIP } = NodeFilter

const filter = SHOW_ELEMENT | SHOW_TEXT | SHOW_CDATA_SECTION

const getVisibleRange = (doc, start, end, mapRect) => {
  // first get all visible nodes
  const acceptNode = node => {
    const name = node.localName?.toLowerCase()
    // ignore all scripts, styles, and their children
    if (name === 'script' || name === 'style') return FILTER_REJECT
    if (node.nodeType === 1) {
      const { left, right } = mapRect(node.getBoundingClientRect())
      // no need to check child nodes if it's completely out of view
      if (right < start || left > end) return FILTER_REJECT
      // elements must be completely in view to be considered visible
      // because you can't specify offsets for elements
      if (left >= start && right <= end) return FILTER_ACCEPT
      // TODO: it should probably allow elements that do not contain text
      // because they can exceed the whole viewport in both directions
      // especially in scrolled mode
    } else {
      // ignore empty text nodes
      if (!node.nodeValue?.trim()) return FILTER_REJECT
      // create range to get rect
      const range = doc.createRange()
      range.selectNodeContents(node)
      const { left, right } = mapRect(range.getBoundingClientRect())
      // it's visible if any part of it is in view
      if (right >= start && left <= end) return FILTER_ACCEPT
    }
    return FILTER_SKIP
  }
  if (!doc) return
  const walker = doc.createTreeWalker(doc.body, filter, { acceptNode })
  const nodes = []
  for (let node = walker.nextNode(); node; node = walker.nextNode())
    nodes.push(node)

  // we're only interested in the first and last visible nodes
  const from = nodes[0] ?? doc.body
  const to = nodes[nodes.length - 1] ?? from

  // find the offset at which visibility changes
  const startOffset = from.nodeType === 1 ? 0
    : bisectNode(doc, from, (a, b) => {
      const p = mapRect(a.getBoundingClientRect())
      const q = mapRect(b.getBoundingClientRect())
      if (p.right < start && q.left > start) return 0
      return q.left > start ? -1 : 1
    })
  const endOffset = to.nodeType === 1 ? 0
    : bisectNode(doc, to, (a, b) => {
      const p = mapRect(a.getBoundingClientRect())
      const q = mapRect(b.getBoundingClientRect())
      if (p.right < end && q.left > end) return 0
      return q.left > end ? -1 : 1
    })

  const range = doc.createRange()
  range.setStart(from, startOffset)
  range.setEnd(to, endOffset)
  return range
}

const getDirection = doc => {
  const { defaultView } = doc
  const { writingMode, direction } = defaultView.getComputedStyle(doc.body)
  const vertical = writingMode === 'vertical-rl'
    || writingMode === 'vertical-lr'
  const rtl = doc.body.dir === 'rtl'
    || direction === 'rtl'
    || doc.documentElement.dir === 'rtl'
  return { vertical, rtl, writingMode }
}

// const getBackground = doc => {
//   const bodyStyle = doc.defaultView.getComputedStyle(doc.body)
//   return bodyStyle.backgroundColor === 'rgba(0, 0, 0, 0)'
//     && bodyStyle.backgroundImage === 'none'
//     ? doc.defaultView.getComputedStyle(doc.documentElement).background
//     : bodyStyle.background
// }
const getBackground = (bgimgUrl) => {
  let bg
  if (bgimgUrl === 'none') {
    bg = `none`
  } else {
    bg = `url(${bgimgUrl})`
  }
  return bg
}

const applyBackground = (el, bgimgUrl, blur, opacity, fit) => {
  el.style.background = getBackground(bgimgUrl)
  el.style.backgroundPosition = 'center center'
  el.style.backgroundRepeat = 'no-repeat'
  el.style.backgroundAttachment = 'scroll'
  el.style.backgroundSize = fit === 'stretch' ? '100% 100%' : 'cover'
  el.style.filter = (blur && blur > 0) ? `blur(${blur}px)` : ''
  el.style.opacity = (opacity != null) ? opacity : 1
  // Expand the background element beyond its grid cell when blur is active so
  // the blurred edges are not clipped by the parent overflow:hidden boundary.
  if (blur && blur > 0) {
    const expand = `${blur * 2}px`
    el.style.margin = `-${expand}`
    el.style.width = `calc(100% + ${expand} * 2)`
    el.style.height = `calc(100% + ${expand} * 2)`
    // Keep the visual fill identical to the unblurred state; only the
    // element bounds expand so blurred edges can bleed outside the viewport.
  } else {
    el.style.margin = ''
    el.style.width = ''
    el.style.height = ''
  }
}

const makeMarginals = (length, part) => Array.from({ length }, () => {
  const div = document.createElement('div')
  const child = document.createElement('div')
  div.append(child)
  child.setAttribute('part', part)
  return div
})

const setStylesImportant = (el, styles) => {
  const { style } = el
  for (const [k, v] of Object.entries(styles)) style.setProperty(k, v, 'important')
}

class View {
  #observer = new ResizeObserver(() => this.expand())
  #element = document.createElement('div')
  #iframe = document.createElement('iframe')
  #contentRange = document.createRange()
  #overlayer
  #vertical = false
  #rtl = false
  #writingMode = 'horizontal-ltr'
  #column = true
  #size
  #layout = {}
  #loaded = null
  constructor({ container, onExpand }) {
    this.container = container
    this.onExpand = onExpand
    this.#iframe.setAttribute('part', 'filter')
    this.#element.append(this.#iframe)
    Object.assign(this.#element.style, {
      boxSizing: 'content-box',
      position: 'relative',
      overflow: 'hidden',
      flex: '0 0 auto',
      width: '100%', height: '100%',
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      contain: 'layout paint size',
      contentVisibility: 'auto',
      willChange: 'transform',
    })
    Object.assign(this.#iframe.style, {
      overflow: 'hidden',
      border: '0',
      display: 'none',
      width: '100%', height: '100%',
    })
    // `allow-scripts` is needed for events because of WebKit bug
    // https://bugs.webkit.org/show_bug.cgi?id=218086
    this.#iframe.setAttribute('sandbox', 'allow-same-origin allow-scripts')
    this.#iframe.setAttribute('scrolling', 'no')
  }
  get element() {
    return this.#element
  }
  get document() {
    return this.#iframe.contentDocument
  }
  async load(src, afterLoad, beforeRender) {
    if (typeof src !== 'string') throw new Error(`${src} is not string`)
    return new Promise(resolve => {
      // a view replaced before its document loaded must not keep the
      // navigation that created it waiting forever
      this.#loaded = resolve
      this.#iframe.addEventListener('load', () => {
        if (!this.#loaded) return
        this.#loaded = null
        const doc = this.document
        afterLoad?.(doc)

        // it needs to be visible for Firefox to get computed style
        this.#iframe.style.display = 'block'
        const { vertical, rtl, writingMode } = getDirection(doc)
        this.#iframe.style.display = 'none'

        this.#vertical = vertical
        this.#rtl = rtl
        this.#writingMode = writingMode

        this.#contentRange.selectNodeContents(doc.body)
        const layout = beforeRender?.({ vertical, rtl })
        this.#iframe.style.display = 'block'
        this.render(layout)
        this.#observer.observe(doc.body)

        // the resize observer above doesn't work in Firefox
        // (see https://bugzilla.mozilla.org/show_bug.cgi?id=1832939)
        // until the bug is fixed we can at least account for font load
        doc.fonts.ready.then(() => this.expand())

        resolve()
      }, { once: true })
      this.#iframe.src = src
    })
  }
  render(layout) {
    if (!layout) return
    this.#column = layout.flow !== 'scrolled'
    this.#layout = layout
    if (this.#column) this.columnize(layout)
    else this.scrolled(layout)
  }
  scrolled({ gap, columnWidth }) {
    const vertical = this.#vertical
    const doc = this.document
    if (!doc) return
    setStylesImportant(doc.documentElement, {
      'box-sizing': 'border-box',
      'padding': vertical ? `${gap}px 0` : `0 ${gap}px`,
      'column-width': 'auto',
      'height': 'auto',
      'width': 'auto',
      ...(TOUCH_ACTION_SUPPORTED ? { 'touch-action': 'auto' } : {}),
    })
    setStylesImportant(doc.body, {
      [vertical ? 'max-height' : 'max-width']: `${columnWidth}px`,
      'margin': 'auto',
    })
    this.setImageSize()
    this.expand()
  }
  columnize({ width, height, gap, columnWidth, topMargin, bottomMargin }) {
    const vertical = this.#vertical
    this.#size = vertical ? height : width

    const doc = this.document

    const verticlePadding = `${gap / 2}px ${topMargin}px ${gap / 2}px ${bottomMargin}px`
    const horizontalPadding = `${topMargin}px ${gap / 2}px ${bottomMargin}px ${gap / 2}px`

    setStylesImportant(doc.documentElement, {
      'box-sizing': 'border-box',
      'column-width': `${Math.trunc(columnWidth)}px`,
      'column-gap': `${gap}px`,
      'column-fill': 'auto',
      ...(vertical
        ? { 'width': `${width}px` }
        : { 'height': `${height}px` }),
      'padding': vertical ? verticlePadding : horizontalPadding,
      'overflow': 'hidden',
      // force wrap long words
      'overflow-wrap': 'break-word',
      // reset some potentially problematic props
      'position': 'static', 'border': '0', 'margin': '0',
      'max-height': 'none', 'max-width': 'none',
      'min-height': 'none', 'min-width': 'none',
      // fix glyph clipping in WebKit
      '-webkit-line-box-contain': 'block glyphs replaced',
      // the paginator moves pages itself; only allow panning across the
      // paginated axis (nothing scrolls there) so the browser never fights it
      ...(TOUCH_ACTION_SUPPORTED
        ? { 'touch-action': vertical ? 'pan-x pinch-zoom' : 'pan-y pinch-zoom' }
        : {}),
    })
    setStylesImportant(doc.body, {
      'max-height': 'none',
      'max-width': 'none',
      'margin': '0',
    })
    this.setImageSize()
    this.expand()
  }
  setImageSize() {
    const { width, height, margin, columnWidth } = this.#layout
    const vertical = this.#vertical
    const doc = this.document
    for (const el of doc.body.querySelectorAll('img, svg, video')) {
      // preserve max size if they are already set
      const { maxHeight, maxWidth } = doc.defaultView.getComputedStyle(el)
      // Cap max-width to the column width to prevent images from overflowing
      // into the next page when the EPUB embeds a large inline max-width value.
      const effectiveMaxWidth = vertical
        ? `${width - margin * 2}px`
        : columnWidth
          ? `${columnWidth}px`
          : (maxWidth !== 'none' && maxWidth !== '0px' ? maxWidth : '100%')
      setStylesImportant(el, {
        'max-height': vertical
          ? (maxHeight !== 'none' && maxHeight !== '0px' ? maxHeight : '100%')
          : `${height - margin * 2}px`,
        'max-width': effectiveMaxWidth,
        'object-fit': 'contain',
        'page-break-inside': 'avoid',
        'break-inside': 'avoid',
        'box-sizing': 'border-box',
      })
    }
  }
  expand() {
    const { documentElement } = this.document
    if (this.#column) {
      const side = this.#vertical ? 'height' : 'width'
      const otherSide = this.#vertical ? 'width' : 'height'
      this.#contentRange.selectNodeContents(this.document.body)
      const contentRect = this.#contentRange.getBoundingClientRect()
      const rootRect = documentElement.getBoundingClientRect()
      // offset caused by column break at the start of the page
      // which seem to be supported only by WebKit and only for horizontal writing
      const contentStart = this.#vertical ? 0
        : this.#rtl ? rootRect.right - contentRect.right : contentRect.left - rootRect.left
      const contentSize = contentStart + contentRect[side]
      const pageCount = Math.ceil(contentSize / this.#size)
      const expandedSize = pageCount * this.#size
      this.#element.style.padding = '0'
      this.#iframe.style[side] = `${expandedSize}px`
      this.#element.style[side] = `${expandedSize + this.#size * 2}px`
      this.#iframe.style[otherSide] = '100%'
      this.#element.style[otherSide] = '100%'
      documentElement.style[side] = `${this.#size}px`
      if (this.#overlayer) {
        this.#overlayer.element.style.margin = '0'
        this.#overlayer.element.style.left = this.#vertical ? '0' : `${this.#size}px`
        this.#overlayer.element.style.top = this.#vertical ? `${this.#size}px` : '0'
        this.#overlayer.element.style[side] = `${expandedSize}px`
        this.#overlayer.redraw()
      }
    } else {
      const side = this.#vertical ? 'width' : 'height'
      const otherSide = this.#vertical ? 'height' : 'width'
      const contentSize = documentElement.getBoundingClientRect()[side]
      const expandedSize = contentSize
      const { margin } = this.#layout
      const padding = this.#vertical ? `0 ${margin}px` : `${margin}px 0`
      this.#element.style.padding = padding
      this.#iframe.style[side] = `${expandedSize}px`
      this.#element.style[side] = `${expandedSize}px`
      this.#iframe.style[otherSide] = '100%'
      this.#element.style[otherSide] = '100%'
      if (this.#overlayer) {
        this.#overlayer.element.style.margin = padding
        this.#overlayer.element.style.left = '0'
        this.#overlayer.element.style.top = '0'
        this.#overlayer.element.style[side] = `${expandedSize}px`
        this.#overlayer.redraw()
      }
    }
    this.onExpand()
  }
  set overlayer(overlayer) {
    this.#overlayer = overlayer
    this.#element.append(overlayer.element)
  }
  get overlayer() {
    return this.#overlayer
  }
  get writingMode() {
    return this.#writingMode
  }
  destroy() {
    if (this.document?.body) this.#observer.unobserve(this.document.body)
    const loaded = this.#loaded
    this.#loaded = null
    loaded?.()
  }
}

// NOTE: everything here assumes the so-called "negative scroll type" for RTL
export class Paginator extends HTMLElement {
  static observedAttributes = [
    'flow', 'gap', 'top-margin', 'bottom-margin', 'background-color',
    'max-inline-size', 'max-block-size', 'max-column-count', 'column-threshold', 'bgimg-url',
    'bgimg-blur', 'bgimg-opacity', 'bgimg-fit',
  ]
  #root = this.attachShadow({ mode: 'open' })
  #observer = new ResizeObserver(() => this.render())
  #top
  #background
  #container
  // #header
  // #footer
  #view
  #vertical = false
  #rtl = false
  #margin = 0
  #index = -1
  #anchor = 0 // anchor view to a fraction (0-1), Range, or Element
  #justAnchored = false
  #locked = false // while true, prevent any further navigation
  #styles
  #styleMap = new WeakMap()
  #mediaQuery = matchMedia('(prefers-color-scheme: dark)')
  #mediaQueryListener
  #ignoreNativeScroll = false
  #pendingScrollFrame = null
  #scrollEndTimer = null
  #touchState
  // paginated drag: { axis, origin, base, size, bounds, samples, cancelled }
  #drag = null
  // current inline translate of the view element along the paging axis
  #translate = 0
  // in-flight page turn animation (runs on the compositor when possible)
  #turnAnim = null
  // scroll offset we set ourselves; its scroll event must not relocate again
  #ignoreScrollAt = null
  #relocatePending = false
  #relocateReason = null
  #relocateScheduled = false
  #relocateWaiters = []
  // number of turns in progress that end on a blank boundary page and then
  // replace the view with the adjacent section; the old view must not be
  // grabbed or dragged meanwhile
  #sectionChange = 0
  #sectionChangeWaiters = []
  // the latest navigation; an older one that is still loading gives up
  #displayToken = 0
  constructor() {
    super()
    this.#root.innerHTML = `<style>
        :host {
            display: block;
            container-type: size;
        }
        :host, #top {
            box-sizing: border-box;
            position: relative;
            overflow: hidden;
            width: 100%;
            height: 100%;
        }
        #top {
            height: 100%;
            // --_gap: 7%;
            background-color: var(--_background-color);
            --_max-inline-size: 720px;
            --_max-block-size: 1440px;
            --_max-column-count: 2;
            --_max-column-count-portrait: 1;
            --_max-column-count-spread: var(--_max-column-count);
            --_half-gap: calc(var(--_gap) / 2);
            --_max-width: calc(var(--_max-inline-size) * var(--_max-column-count-spread));
            --_max-height: var(--_max-block-size);
            display: grid;
            grid-template-columns:
                minmax(var(--_half-gap), 1fr)
                var(--_half-gap)
                minmax(0, calc(var(--_max-width) - var(--_gap)))
                var(--_half-gap)
                minmax(var(--_half-gap), 1fr);
            grid-template-rows:
                var(--_top-margin)
                1fr
                var(--_bottom-margin);
            &.vertical {
                --_max-column-count-spread: var(--_max-column-count-portrait);
                --_max-width: var(--_max-block-size);
                --_max-height: calc(var(--_max-inline-size) * var(--_max-column-count-spread));
            }
            @container (orientation: portrait) {
                & {
                    --_max-column-count-spread: var(--_max-column-count-portrait);
                }
                &.vertical {
                    --_max-column-count-spread: var(--_max-column-count);
                }
            }
        }
        #background {
            grid-column: 1 / -1;
            grid-row: 1 / -1;
        }
        #container {
            grid-column: 1 / -1;
            grid-row: 1 / -1;
            overflow-x: auto;
            overflow-y: hidden;
            -webkit-overflow-scrolling: touch;
            -ms-overflow-style: none;  /* Internet Explorer 10+ */
            scrollbar-width: none;  /* Firefox */
        }
        #container::-webkit-scrollbar {
            display: none;  /* Safari and Chrome */
        }
        :host([flow="scrolled"]) #container {
            grid-column: 1 / -1;
            grid-row: 2;
            overflow: auto;
        }
        #header {
            grid-column: 3 / 4;
            grid-row: 1;
        }
        #footer {
            grid-column: 3 / 4;
            grid-row: 3;
            align-self: end;
        }
        #header, #footer {
            display: grid;
            height: var(--_margin);
        }
        :is(#header, #footer) > * {
            display: flex;
            align-items: center;
            min-width: 0;
        }
        :is(#header, #footer) > * > * {
            width: 100%;
            overflow: hidden;
            white-space: nowrap;
            text-overflow: ellipsis;
            text-align: center;
            font-size: .75em;
            opacity: .6;
        }
        </style>
        <div id="top">
            <div id="background" part="filter"></div>
            <div id="container"></div>
        </div>
        `

    this.#top = this.#root.getElementById('top')
    this.#background = this.#root.getElementById('background')
    this.#container = this.#root.getElementById('container')
    // this.#header = this.#root.getElementById('header')
    // this.#footer = this.#root.getElementById('footer')

    this.#observer.observe(this.#container)
    this.#container.addEventListener('scroll', () => {
      if (this.#ignoreNativeScroll) return
      if (this.#ignoreScrollAt != null) {
        const at = this.#ignoreScrollAt
        this.#ignoreScrollAt = null
        if (Math.abs(this.#container[this.scrollProp] - at) < 1) return
      }
      if (this.#justAnchored) {
        this.#justAnchored = false
        return
      }
      if (this.#pendingScrollFrame)
        cancelAnimationFrame(this.#pendingScrollFrame)
      this.#pendingScrollFrame = requestAnimationFrame(() => {
        this.#pendingScrollFrame = null
        this.#afterScroll('scroll')
        if (this.scrolled) this.#handleScrollBoundaries()
      })
    })

    // Passive listeners never block native (scroll mode) scrolling. When
    // `touch-action` is unsupported, touchmove has to stay cancelable so the
    // paginated drag can stop the browser from panning.
    const passive = { passive: true }
    const moveOpts = { passive: TOUCH_ACTION_SUPPORTED }
    const onTouchStart = this.#onTouchStart.bind(this)
    const onTouchMove = this.#onTouchMove.bind(this)
    const onTouchEnd = this.#onTouchEnd.bind(this)
    const listen = target => {
      target.addEventListener('touchstart', onTouchStart, passive)
      target.addEventListener('touchmove', onTouchMove, moveOpts)
      target.addEventListener('touchend', onTouchEnd, passive)
      target.addEventListener('touchcancel', onTouchEnd, passive)
    }
    listen(this)
    this.addEventListener('load', ({ detail: { doc } }) => listen(doc))

    this.#mediaQueryListener = () => {
      if (!this.#view) return
      this.#applyBackground()
    }
    this.#mediaQuery.addEventListener('change', this.#mediaQueryListener)
  }
  attributeChangedCallback(name, _, value) {
    switch (name) {
      case 'flow':
        this.render()
        break
      case 'top-margin':
      case 'max-block-size':
      case 'background-color':
        this.#top.style.setProperty('--_' + name, value)
        break
      case 'bottom-margin':
      case 'gap':
      case 'max-column-count':
      case 'column-threshold':
      case 'max-inline-size':
        // needs explicit `render()` as it doesn't necessarily resize
        this.#top.style.setProperty('--_' + name, value)
        this.render()
        break
      case 'bgimg-url':
      case 'bgimg-blur':
      case 'bgimg-opacity':
      case 'bgimg-fit':
        if (this.#background) this.#applyBackground()
        break
    }
  }
  open(book) {
    this.bookDir = book.dir
    this.sections = book.sections
  }
  #applyBackground() {
    const url = this.getAttribute('bgimg-url') ?? 'none'
    const blur = parseFloat(this.getAttribute('bgimg-blur') ?? '0')
    const opacity = parseFloat(this.getAttribute('bgimg-opacity') ?? '1')
    const fit = this.getAttribute('bgimg-fit') ?? 'cover'
    applyBackground(this.#background, url, blur, opacity, fit)
  }
  #createView() {
    if (this.#view) {
      this.#view.destroy()
      this.#container.removeChild(this.#view.element)
    }
    this.#view = new View({
      container: this,
      onExpand: () => this.#onExpand(),
    })
    this.#container.append(this.#view.element)
    return this.#view
  }
  #beforeRender({ vertical, rtl }) {
    this.#vertical = vertical
    this.#rtl = rtl
    this.#top.classList.toggle('vertical', vertical)

    // set background to `doc` background
    // this is needed because the iframe does not fill the whole element
    this.#applyBackground()

    const { width, height } = this.#container.getBoundingClientRect()
    const size = vertical ? height : width

    const style = getComputedStyle(this.#top)
    const maxInlineSize = parseFloat(style.getPropertyValue('--_column-threshold')) || parseFloat(style.getPropertyValue('--_max-inline-size'))
    const maxColumnCount = parseInt(style.getPropertyValue('--_max-column-count'))
    const margin = parseFloat(style.getPropertyValue('--_top-margin'))
    this.#margin = margin

    const g = parseFloat(style.getPropertyValue('--_gap')) / 100
    // The gap will be a percentage of the #container, not the whole view.
    // This means the outer padding will be bigger than the column gap. Let
    // `a` be the gap percentage. The actual percentage for the column gap
    // will be (1 - a) * a. Let us call this `b`.
    //
    // To make them the same, we start by shrinking the outer padding
    // setting to `b`, but keep the column gap setting the same at `a`. Then
    // the actual size for the column gap will be (1 - b) * a. Repeating the
    // process again and again, we get the sequence
    //     x₁ = (1 - b) * a
    //     x₂ = (1 - x₁) * a
    //     ...
    // which converges to x = (1 - x) * a. Solving for x, x = a / (1 + a).
    // So to make the spacing even, we must shrink the outer padding with
    //     f(x) = x / (1 + x).
    // But we want to keep the outer padding, and make the inner gap bigger.
    // So we apply the inverse, f⁻¹ = -x / (x - 1) to the column gap.
    const gap = -g / (g - 1) * size

    const topMargin = parseFloat(style.getPropertyValue('--_top-margin'))
    const bottomMargin = parseFloat(style.getPropertyValue('--_bottom-margin'))

    const flow = this.getAttribute('flow')
    if (TOUCH_ACTION_SUPPORTED) this.#container.style.touchAction = flow === 'scrolled'
      ? '' : vertical ? 'pan-x pinch-zoom' : 'pan-y pinch-zoom'
    if (flow === 'scrolled') {
      this.#container.style.overflowX = 'auto'
      this.#container.style.overflowY = 'auto'
    } else if (vertical) {
      this.#container.style.overflowX = 'hidden'
      this.#container.style.overflowY = 'auto'
    } else {
      this.#container.style.overflowX = 'auto'
      this.#container.style.overflowY = 'hidden'
    }
    if (flow === 'scrolled') {
      // FIXME: vertical-rl only, not -lr
      this.setAttribute('dir', vertical ? 'rtl' : 'ltr')
      this.#top.style.padding = '0'
      const columnWidth = maxInlineSize

      this.heads = null
      this.feet = null
      // this.#header.replaceChildren()
      // this.#footer.replaceChildren()

      return { flow, margin, gap, columnWidth, topMargin, bottomMargin }
    }

    const divisor = maxColumnCount == 0
      ? Math.min(2, Math.ceil(size / maxInlineSize))
      : maxColumnCount

    const columnWidth = (size / divisor) - gap
    this.setAttribute('dir', rtl ? 'rtl' : 'ltr')

    const marginalDivisor = vertical
      ? Math.min(2, Math.ceil(width / maxInlineSize))
      : divisor
    const marginalStyle = {
      gridTemplateColumns: `repeat(${marginalDivisor}, 1fr)`,
      gap: `${gap}px`,
      direction: this.bookDir === 'rtl' ? 'rtl' : 'ltr',
    }
    // Object.assign(this.#header.style, marginalStyle)
    // Object.assign(this.#footer.style, marginalStyle)
    const heads = makeMarginals(marginalDivisor, 'head')
    const feet = makeMarginals(marginalDivisor, 'foot')
    this.heads = heads.map(el => el.children[0])
    this.feet = feet.map(el => el.children[0])
    // this.#header.replaceChildren(...heads)
    // this.#footer.replaceChildren(...feet)

    return { height, width, margin, gap, columnWidth, topMargin, bottomMargin }
  }
  render() {
    if (!this.#view) return
    const stale = this.#anchorIsStale()
    this.#cancelTurn()
    // a turn that has not been relocated yet: #anchor still points at the
    // page that was left, so take the anchor from the committed page while
    // the old layout is still there
    if (stale) this.#anchor = this.#getVisibleRange()
    this.#view.render(this.#beforeRender({
      vertical: this.#vertical,
      rtl: this.#rtl,
    }))
    this.scrollToAnchor(this.#anchor)
  }
  get scrolled() {
    return this.getAttribute('flow') === 'scrolled'
  }
  get scrollProp() {
    const { scrolled } = this
    return this.#vertical ? (scrolled ? 'scrollLeft' : 'scrollTop')
      : scrolled ? 'scrollTop' : 'scrollLeft'
  }
  get sideProp() {
    const { scrolled } = this
    return this.#vertical ? (scrolled ? 'width' : 'height')
      : scrolled ? 'height' : 'width'
  }
  get vertical() {
    return this.#vertical
  }
  get size() {
    return this.#container.getBoundingClientRect()[this.sideProp]
  }
  get viewSize() {
    return this.#view.element.getBoundingClientRect()[this.sideProp]
  }
  get start() {
    return Math.abs(this.#container[this.scrollProp])
  }
  get end() {
    return this.start + this.size
  }
  get page() {
    return Math.floor(((this.start + this.end) / 2) / this.size)
  }
  get pages() {
    return Math.round(this.viewSize / this.size)
  }
  scrollBy(dx, dy) {
    const element = this.#container
    const prop = this.scrollProp
    const horizontal = prop === 'scrollLeft'
    const delta = horizontal ? dx : dy
    if (horizontal) element.scrollBy({ left: delta, top: 0, behavior: 'auto' })
    else element.scrollBy({ left: 0, top: delta, behavior: 'auto' })
  }
  get #axis() {
    return this.scrollProp === 'scrollLeft' ? 'x' : 'y'
  }
  #setTranslate(px) {
    this.#translate = px
    const el = this.#view?.element
    if (!el) return
    el.style.transform = px ? translateCss(this.#axis, px) : ''
  }
  // Stop the running turn animation, keeping the page where it currently is
  // on screen (as an inline translate), so a new drag can pick it up.
  #stopTurnAnimation() {
    const turn = this.#turnAnim
    if (!turn) return
    this.#turnAnim = null
    let current = 0
    clearTimeout(turn.timer)
    if (turn.anim) {
      const el = this.#view?.element
      if (el) current = parseTranslate(getComputedStyle(el).transform, turn.axis)
      turn.anim.onfinish = null
      turn.anim.cancel()
    } else {
      cancelAnimationFrame(turn.raf)
      current = turn.current ?? 0
    }
    this.#setTranslate(current)
    turn.done()
  }
  // Jump to the end state of any turn/drag (used before layout changes).
  #cancelTurn() {
    this.#stopTurnAnimation()
    if (this.#translate) this.#setTranslate(0)
    if (this.#drag) this.#drag.superseded = true
  }
  #isDragging() {
    const drag = this.#drag
    return !!drag && drag.samples.length > 0 && !drag.cancelled && !drag.superseded
  }
  #turnTiming(distance, velocity) {
    const size = this.size || 1
    let duration = Math.max(200, Math.min(300, 250 * (distance / size)))
    let bezier = EASE_OUT_SINE_BEZIER
    // Carry the finger's release speed into the animation instead of
    // restarting from the default curve: the initial slope of
    // cubic-bezier(x1, y1, ...) is y1 / x1.
    const normalized = distance > 0 ? velocity * duration / distance : 0
    if (normalized > 1.6) {
      let s = normalized
      if (s > 3) {
        duration = Math.max(120, 3 * distance / velocity)
        s = velocity * duration / distance
      }
      bezier = [0.33, Math.min(1, 0.33 * s), 0.6, 1]
    }
    return { duration, bezier }
  }
  // Animate the view element's translate from `from` to 0. With the Web
  // Animations API the animation runs on the compositor, so it stays smooth
  // even when the main thread is busy, and it ends at the committed scroll
  // position without any final main-thread step.
  #animateTranslate(from, duration, bezier) {
    const el = this.#view?.element
    const axis = this.#axis
    this.#setTranslate(0)
    if (!el || !from || !(duration > 0)) return Promise.resolve()
    return new Promise(resolve => {
      const turn = { axis, done: resolve }
      this.#turnAnim = turn
      if (HAS_WAAPI) {
        const anim = el.animate([
          { transform: translateCss(axis, from) },
          { transform: translateCss(axis, 0) },
        ], { duration, easing: `cubic-bezier(${bezier.join(',')})`, fill: 'none' })
        turn.anim = anim
        const end = () => {
          clearTimeout(turn.timer)
          anim.onfinish = null
          if (this.#turnAnim === turn) this.#turnAnim = null
          resolve()
        }
        anim.onfinish = end
        // animations are not serviced in a hidden document; don't hang
        turn.timer = setTimeout(() => {
          if (this.#turnAnim !== turn) return
          anim.cancel()
          end()
        }, duration + 250)
      } else {
        const ease = cubicBezier(...bezier)
        let start
        turn.current = from
        const step = now => {
          start ??= now
          const fraction = Math.min(1, (now - start) / duration)
          turn.current = from * (1 - ease(fraction))
          el.style.transform = fraction < 1 ? translateCss(axis, turn.current) : ''
          if (fraction < 1) turn.raf = requestAnimationFrame(step)
          else {
            clearTimeout(turn.timer)
            if (this.#turnAnim === turn) this.#turnAnim = null
            resolve()
          }
        }
        turn.raf = requestAnimationFrame(step)
        turn.timer = setTimeout(() => {
          if (this.#turnAnim !== turn) return
          cancelAnimationFrame(turn.raf)
          el.style.transform = ''
          this.#turnAnim = null
          resolve()
        }, duration + 250)
      }
    })
  }
  // Commit the scroll position right away and animate the visual offset to
  // it. `velocity` (px/ms, towards the target) keeps a flick's momentum.
  #commitAndAnimate(offset, { animate, velocity = 0, duration } = {}) {
    const element = this.#container
    const prop = this.scrollProp
    this.#stopTurnAnimation()
    if (this.#drag) this.#drag.superseded = true
    const visual = element[prop] - this.#translate
    this.#ignoreScrollAt = offset
    element[prop] = offset
    const committed = element[prop]
    this.#ignoreScrollAt = committed
    const from = committed - visual
    if (!animate || Math.abs(from) < 0.5) {
      this.#setTranslate(0)
      return Promise.resolve()
    }
    const timing = this.#turnTiming(Math.abs(from), velocity)
    return this.#animateTranslate(from, duration ?? timing.duration, timing.bezier)
  }
  // Relocation (visible range, CFI, progress, bridge call to Flutter) is
  // expensive. Run it after the frame showing the new page has been produced,
  // and never during a touch or a running turn animation.
  #requestRelocate(reason) {
    return new Promise(resolve => {
      this.#relocatePending = true
      this.#relocateReason = reason
      this.#relocateWaiters.push(resolve)
      this.#scheduleRelocate()
    })
  }
  #scheduleRelocate() {
    if (!this.#relocatePending || this.#relocateScheduled) return
    if (this.#isDragging() || this.#turnAnim) return
    this.#relocateScheduled = true
    let ran = false
    const run = () => {
      if (ran) return
      ran = true
      this.#relocateScheduled = false
      if (!this.#relocatePending) return
      // rescheduled when the drag or animation ends
      if (this.#isDragging() || this.#turnAnim) return
      this.#relocatePending = false
      const waiters = this.#relocateWaiters.splice(0)
      try {
        if (this.#view) this.#afterScroll(this.#relocateReason)
      } finally {
        for (const resolve of waiters) resolve()
      }
    }
    requestAnimationFrame(() => setTimeout(run, 0))
    // rAF does not fire in a hidden document
    setTimeout(run, 150)
  }
  #beginSectionChange() {
    this.#sectionChange++
  }
  #endSectionChange() {
    if (--this.#sectionChange > 0) return
    this.#sectionChange = 0
    for (const resolve of this.#sectionChangeWaiters.splice(0)) resolve()
  }
  async #waitSectionChange() {
    while (this.#sectionChange > 0)
      await new Promise(resolve => this.#sectionChangeWaiters.push(resolve))
  }
  // A page turn commits the scroll position at once but updates #anchor only
  // when it relocates (after the animation and the next frame).
  #anchorIsStale() {
    return !this.scrolled && !!this.#view
      && (!!this.#turnAnim || this.#relocatePending)
  }
  // The content was resized (late images, fonts, styles applied after load).
  #onExpand() {
    // Re-anchoring now would use the anchor of the page the reader just
    // turned away from and cancel the turn, so e.g. the first swipe in a
    // chapter whose images or fonts are still loading jumped back to its
    // first page. Keep the committed page; the pending relocate takes the
    // anchor from it.
    if (this.#anchorIsStale()) {
      this.#scheduleRelocate()
      return
    }
    this.scrollToAnchor(this.#anchor)
  }
  #isBoundaryPage(offset) {
    const size = this.size
    if (!size || this.scrolled) return 0
    const index = Math.round(Math.abs(offset) / size)
    const dir = index <= 0 ? -1 : index >= this.pages - 1 ? 1 : 0
    return dir && this.#adjacentIndex(dir) != null ? dir : 0
  }
  // Allowed visual scroll range for a drag; the blank pages before/after the
  // section are only reachable when there is a section to go to.
  #dragBounds(size) {
    const pages = this.pages
    if (!size || !pages) return null
    const sign = this.scrollProp === 'scrollLeft' && this.#rtl ? -1 : 1
    const first = this.#adjacentIndex(-1) != null ? 0 : Math.min(1, pages - 1)
    const last = Math.max(first, this.#adjacentIndex(1) != null ? pages - 1 : pages - 2)
    const a = sign * first * size, b = sign * last * size
    return { min: Math.min(a, b), max: Math.max(a, b) }
  }
  #resist(drag, translate) {
    const { bounds, origin } = drag
    if (!bounds) return translate
    const visual = origin - translate
    if (visual < bounds.min) return origin - (bounds.min - (bounds.min - visual) * 0.3)
    if (visual > bounds.max) return origin - (bounds.max + (visual - bounds.max) * 0.3)
    return translate
  }
  #releaseVelocity(drag, now) {
    const samples = drag.samples
    const last = samples[samples.length - 1]
    if (!last || now - last.t > 80) return 0
    const first = samples.find(s => last.t - s.t <= 100) ?? last
    const dt = last.t - first.t
    return dt >= 8 ? (last.p - first.p) / dt : 0
  }
  // Decide the target page after a drag and animate there.
  #settleDrag(drag, velocity, allowTurn) {
    const { size, origin, bounds } = drag
    const translate = this.#translate
    if (drag.superseded) {
      this.#scheduleRelocate()
      return
    }
    if (!size) {
      this.#setTranslate(0)
      this.#scheduleRelocate()
      return
    }
    // a page further along the scroll axis is shown when the content moves
    // towards negative translate; this holds for LTR, RTL and vertical alike
    let step = 0
    if (allowTurn) {
      step = Math.round(-translate / size)
      if (Math.abs(velocity) > 0.3) step += velocity < 0 ? 1 : -1
      step = Math.max(-1, Math.min(1, step))
    }
    let target = origin + step * size
    if (bounds) target = Math.max(bounds.min, Math.min(bounds.max, target))
    const visual = origin - translate
    const towards = Math.sign(target - visual)
    const speed = Math.max(0, -velocity * towards)
    const animate = this.hasAttribute('animated')
    const boundary = target !== origin ? this.#isBoundaryPage(target) : 0
    if (boundary) this.#beginSectionChange()
    const moved = target !== origin
    return this.#commitAndAnimate(target, { animate, velocity: speed })
      .then(() => {
        if (boundary) return this.#goTo({
          index: this.#adjacentIndex(boundary),
          anchor: boundary < 0 ? () => 1 : () => 0,
        })
        if (moved) return this.#requestRelocate('snap')
        this.#scheduleRelocate()
      })
      .catch(e => console.warn(e))
      .finally(() => {
        if (boundary) this.#endSectionChange()
      })
  }
  #onTouchStart(e) {
    const touch = e.changedTouches[0]
    const scrollProp = this.scrollProp
    // A turn onto a blank boundary page is about to be replaced by the
    // adjacent section: let it finish instead of freezing it mid-flight
    // until the section has loaded (its view is going away anyway).
    const changingSection = this.#sectionChange > 0
    if (this.#turnAnim && !changingSection) {
      // grab the page mid-flight; in scroll mode just finish the animation
      this.#stopTurnAnimation()
      if (this.scrolled) this.#setTranslate(0)
    }
    if (this.#drag && e.touches.length > 1) this.#drag.cancelled = true
    this.#touchState = {
      x: touch?.screenX, y: touch?.screenY,
      t: e.timeStamp,
      vx: 0, vy: 0,
      pinched: false,
      direction: 'none',
      startTouch: {
        x: e.touches[0].screenX,
        y: e.touches[0].screenY,
      },
      delta: { x: 0, y: 0 },
      startScroll: this.#container[scrollProp],
      startPage: this.page,
      lockedOffset: null,
      axis: scrollProp,
    }
    if (!this.scrolled && this.#view && !changingSection && e.touches.length === 1) {
      const size = this.size
      this.#drag = {
        axis: this.#axis,
        origin: this.#container[scrollProp],
        base: this.#translate,
        size,
        bounds: this.#dragBounds(size),
        samples: [],
        cancelled: false,
        superseded: false,
        doc: e.currentTarget?.nodeType === 9 ? e.currentTarget : null,
      }
      this.#drag.selection = selectionKey(this.#drag.doc)
    } else if (e.touches.length === 1) this.#drag = null
    this.dispatchEvent(new CustomEvent('doctouchstart', {
      detail: {
        touch: e.changedTouches[0],
        touchState: this.#touchState,
      },
      bubbles: true,
      composed: true
    }))
  }
  #onTouchMove(e) {
    // without `touch-action` support the browser would pan the paginated
    // axis natively at the same time as the drag below
    if (!TOUCH_ACTION_SUPPORTED && !this.scrolled && e.cancelable) e.preventDefault()

    if (window.getSelection()?.toString()) return

    const touch = e.changedTouches[0]
    const state = this.#touchState
    if (!state) return

    const deltaX = touch.screenX - state.startTouch.x
    const deltaY = touch.screenY - state.startTouch.y

    const absDeltaX = Math.abs(deltaX)
    const absDeltaY = Math.abs(deltaY)

    state.delta.x = deltaX
    state.delta.y = deltaY

    const threshold = 5

    const notHorizontal = state.direction === 'horizontal' && absDeltaY > absDeltaX
    const notVertical = state.direction === 'vertical' && absDeltaX > absDeltaY

    if (state.direction !== 'none' || (notHorizontal && notVertical)) {
      if (absDeltaX < threshold && absDeltaY < threshold) return
    }

    if ((absDeltaX > threshold || absDeltaY > threshold) && state.direction === 'none') {
      if (absDeltaX > absDeltaY) {
        state.direction = 'horizontal'
      } else {
        state.direction = 'vertical'
        if (this.scrollProp === 'scrollLeft' && state.lockedOffset == null)
          state.lockedOffset = state.startScroll ?? this.#container.scrollLeft
      }
    }

    state.axis = this.scrollProp

    this.dispatchEvent(new CustomEvent('doctouchmove', {
      detail: {
        touch,
        touchState: state,
      },
      bubbles: true,
      composed: true
    }))

    if (state.pinched) return
    state.pinched = globalThis.visualViewport?.scale > 1
    if (state.pinched || e.touches.length > 1) {
      if (this.#drag) this.#drag.cancelled = true
      return
    }

    const dt = e.timeStamp - state.t || 16.7
    const stepX = state.x - touch.screenX
    const stepY = state.y - touch.screenY
    state.x = touch.screenX
    state.y = touch.screenY
    state.t = e.timeStamp
    state.vx = stepX / dt
    state.vy = stepY / dt

    if (this.scrolled) return

    // Paginated: the page follows the finger through a compositor-only
    // transform; nothing is laid out or scrolled until the finger lifts.
    const drag = this.#drag
    if (!drag || drag.cancelled || drag.superseded) return
    // the touch is selecting text (e.g. touch selection on desktop WebViews)
    if (drag.doc && !sameSelection(drag.selection, selectionKey(drag.doc))) {
      drag.cancelled = true
      if (this.#translate) this.#settleDrag(drag, 0, false)
      return
    }
    const along = drag.axis === 'x' ? 'horizontal' : 'vertical'
    // a perpendicular gesture (e.g. the bookmark pull-down) leaves the page
    if (state.direction !== along) return
    const pos = drag.axis === 'x' ? touch.screenX : touch.screenY
    const start = drag.axis === 'x' ? state.startTouch.x : state.startTouch.y
    const samples = drag.samples
    samples.push({ t: e.timeStamp, p: pos })
    while (samples.length > 2 && e.timeStamp - samples[0].t > 120) samples.shift()
    this.#setTranslate(this.#resist(drag, drag.base + pos - start))
  }
  #onTouchEnd(e) {
    const state = this.#touchState
    const cancelled = e.type === 'touchcancel'
    if (!cancelled) this.dispatchEvent(new CustomEvent('doctouchend', {
      detail: {
        touch: e.changedTouches[0],
        touchState: state,
      },
      bubbles: true,
      composed: true
    }))
    // wait for the last finger
    if (e.touches?.length) return

    const drag = this.#drag
    this.#touchState = null
    this.#drag = null

    if (this.scrolled) {
      // Fire a final relocate after touch ends in scrolled mode
      this.#afterScroll('scroll')
      this.#scheduleRelocate()
      return
    }

    if (!drag || (!drag.samples.length && !drag.base)) {
      this.#scheduleRelocate()
      return
    }
    const pinched = state?.pinched || globalThis.visualViewport?.scale > 1
    const allowTurn = !cancelled && !pinched && !drag.cancelled && !drag.superseded
      && state?.direction === (drag.axis === 'x' ? 'horizontal' : 'vertical')
    const velocity = allowTurn ? this.#releaseVelocity(drag, e.timeStamp) : 0
    this.#settleDrag(drag, velocity, allowTurn)
  }
  // allows one to process rects as if they were LTR and horizontal
  #getRectMapper() {
    if (this.scrolled) {
      const size = this.viewSize
      const margin = this.#margin
      return this.#vertical
        ? ({ left, right }) =>
          ({ left: size - right - margin, right: size - left - margin })
        : ({ top, bottom }) => ({ left: top + margin, right: bottom + margin })
    }
    const pxSize = this.pages * this.size
    return this.#rtl
      ? ({ left, right }) =>
        ({ left: pxSize - right, right: pxSize - left })
      : this.#vertical
        ? ({ top, bottom }) => ({ left: top, right: bottom })
        : f => f
  }
  async #scrollToRect(rect, reason) {
    if (this.scrolled) {
      const offset = this.#getRectMapper()(rect).left - this.#margin
      return this.#scrollTo(offset, reason)
    }
    const mappedRect = this.#getRectMapper()(rect)
    const left = mappedRect.left
    const pageIndex = Math.floor(left / this.size)
    const pageStart = pageIndex * this.size
    const pageEnd = pageStart + this.size
    const nudgedLeft = Math.min(left + this.#margin / 2, pageEnd - 1)
    const normalizedLeft = Math.max(pageStart, nudgedLeft)
    return this.#scrollToPage(Math.floor(normalizedLeft / this.size) + (this.#rtl ? -1 : 1), reason)
  }
  async #scrollTo(offset, reason, smooth) {
    const element = this.#container
    const { scrollProp } = this

    const opts = typeof smooth === 'object' ? smooth ?? {} : {}
    const shouldAnimate = opts.animate ?? (reason === 'snap' || smooth === true)

    const finish = () => {
      this.#afterScroll(reason)
      this.#ignoreNativeScroll = false
    }

    // If already at target position
    if (Math.abs(element[scrollProp] - offset) < 1 && !this.#translate && !this.#turnAnim) {
      this.#ignoreNativeScroll = true
      finish()
      return
    }

    // FIXME: vertical-rl only, not -lr
    if (this.scrolled && this.#vertical) offset = -offset

    if (reason === 'anchor') {
      // layout-driven repositioning: jump there; an active drag continues
      // from the new position
      this.#stopTurnAnimation()
      if (!this.#drag) this.#setTranslate(0)
      this.#ignoreNativeScroll = true
      element[scrollProp] = offset
      if (this.#drag) this.#drag.origin = element[scrollProp]
      finish()
      return
    }

    // Page turn: commit the scroll position at once, animate the visual
    // offset on the compositor, and relocate after the page has settled.
    const useAnimation = shouldAnimate && this.hasAttribute('animated')
    // a boundary page is replaced by the adjacent section right away, which
    // relocates by itself
    const boundary = this.#isBoundaryPage(offset)
    await this.#commitAndAnimate(offset, { animate: useAnimation, duration: opts.duration })
    if (!boundary) await this.#requestRelocate(reason)
  }
  async #scrollToPage(page, reason, smooth) {
    const offset = this.size * (this.#rtl ? -page : page)
    return this.#scrollTo(offset, reason, smooth)
  }
  async scrollToAnchor(anchor, select) {
    this.#anchor = anchor
    const rects = uncollapse(anchor)?.getClientRects?.()
    // if anchor is an element or a range
    if (rects) {
      // when the start of the range is immediately after a hyphen in the
      // previous column, there is an extra zero width rect in that column
      const rect = Array.from(rects)
        .find(r => r.width > 0 && r.height > 0) || rects[0]
      if (!rect) return
      await this.#scrollToRect(rect, 'anchor')
      if (select) this.#selectAnchor()
      return
    }
    // if anchor is a fraction
    if (this.scrolled) {
      await this.#scrollTo(anchor * this.viewSize, 'anchor')
      return
    }
    const { pages } = this
    if (!pages) return
    const textPages = pages - 2
    const newPage = Math.round(anchor * (textPages - 1))
    await this.#scrollToPage(newPage + 1, 'anchor')
  }
  #selectAnchor() {
    const { defaultView } = this.#view.document
    if (this.#anchor.startContainer) {
      const sel = defaultView.getSelection()
      sel.removeAllRanges()
      sel.addRange(this.#anchor)
    }
  }
  #getVisibleRange() {
    if (this.scrolled) return getVisibleRange(this.#view.document,
      this.start + this.#margin, this.end - this.#margin, this.#getRectMapper())
    const size = this.#rtl ? -this.size : this.size
    return getVisibleRange(this.#view.document,
      this.start - size, this.end - size, this.#getRectMapper())
  }
  #afterScroll(reason) {
    // During active touch scrolling, defer all relocation work
    // to avoid expensive DOM traversal (getVisibleRange) per frame
    if (reason === 'scroll' && this.#touchState) return

    // For scrolled mode, debounce relocate to also skip during momentum scroll
    // Only compute after scrolling has stopped for 200ms
    if (this.scrolled && reason === 'scroll') {
      if (this.#scrollEndTimer) clearTimeout(this.#scrollEndTimer)
      this.#scrollEndTimer = setTimeout(() => {
        this.#scrollEndTimer = null
        this.#doRelocate(reason)
      }, 200)
      return
    }

    this.#doRelocate(reason)
  }
  #doRelocate(reason) {
    const range = this.#getVisibleRange()
    // don't set new anchor if relocation was to scroll to anchor
    if (reason !== 'anchor') this.#anchor = range
    else this.#justAnchored = true

    const index = this.#index
    const detail = { reason, range, index }
    if (this.scrolled) detail.fraction = this.start / this.viewSize
    else if (this.pages > 0) {
      const { page, pages } = this
      detail.fraction = (page - 1) / (pages - 2)
      detail.size = 1 / (pages - 2)
    }

    this.dispatchEvent(new CustomEvent('relocate', { detail }))
  }
  #handleScrollBoundaries() {
    // if (!this.scrolled || this.#locked) return
    
    // // Only trigger transitions when very close to boundaries (95% through)
    // const threshold = Math.min(50, this.size * 0.05) // Small threshold or 5% of size
    // const atEnd = this.viewSize - this.end <= threshold
    // const atStart = this.start <= threshold
    
    // // Only auto-load if we're actually at the boundary, not just approaching
    // if (atEnd && !this.#loadingNext) {
    //   const nextIndex = this.#adjacentIndex(1)
    //   if (nextIndex != null) {
    //     this.#loadingNext = true
    //     // Small delay to ensure scroll has finished
    //     setTimeout(() => {
    //       this.#goTo({
    //         index: nextIndex,
    //         anchor: () => 0,
    //       }).then(() => {
    //         this.#loadingNext = false
    //       }).catch(() => {
    //         this.#loadingNext = false
    //       })
    //     }, 200)
    //   }
    // }
    
    // if (atStart && !this.#loadingPrev) {
    //   const prevIndex = this.#adjacentIndex(-1)
    //   if (prevIndex != null) {
    //     this.#loadingPrev = true
    //     setTimeout(() => {
    //       this.#goTo({
    //         index: prevIndex,
    //         anchor: () => 1,
    //       }).then(() => {
    //         this.#loadingPrev = false
    //       }).catch(() => {
    //         this.#loadingPrev = false
    //       })
    //     }, 200)
    //   }
    // }
  }
  async #display(promise) {
    const token = ++this.#displayToken
    const { index, src, anchor, onLoad, select } = await promise
    // a later navigation started while this section was loading
    if (token !== this.#displayToken) return
    this.#index = index
    if (src) {
      this.#cancelTurn()
      const view = this.#createView()
      const afterLoad = doc => {
        if (doc.head) {
          const $styleBefore = doc.createElement('style')
          doc.head.prepend($styleBefore)
          const $style = doc.createElement('style')
          doc.head.append($style)
          this.#styleMap.set(doc, [$styleBefore, $style])
        }
        onLoad?.({ doc, index })
      }
      const beforeRender = this.#beforeRender.bind(this)
      await view.load(src, afterLoad, beforeRender)
      if (token !== this.#displayToken) return
      this.dispatchEvent(new CustomEvent('create-overlayer', {
        detail: {
          doc: view.document, index,
          attach: overlayer => view.overlayer = overlayer,
        },
      }))
      this.#view = view
    }
    await this.scrollToAnchor((typeof anchor === 'function'
      ? anchor(this.#view.document) : anchor) ?? 0, select)
  }
  #canGoToIndex(index) {
    return index >= 0 && index <= this.sections.length - 1
  }
  async #goTo({ index, anchor, select }) {
    if (index === this.#index) await this.#display({ index, anchor, select })
    else {
      const oldIndex = this.#index
      const onLoad = detail => {
        this.sections[oldIndex]?.unload?.()
        this.setStyles(this.#styles)
        this.dispatchEvent(new CustomEvent('load', { detail }))
      }
      await this.#display(Promise.resolve(this.sections[index].load())
        .then(src => ({ index, src, anchor, onLoad, select }))
        .catch(e => {
          console.warn(e)
          console.warn(new Error(`Failed to load section ${index}`))
          return {}
        }))
    }
  }
  async goTo(target) {
    if (this.#locked) return
    const resolved = await target
    if (this.#canGoToIndex(resolved.index)) return this.#goTo(resolved)
  }
  #scrollPrev(distance) {
    if (!this.#view) return true
    if (this.scrolled) {
      if (this.start > 0) return this.#scrollTo(
        Math.max(0, this.start - (distance ?? this.size)), null, { animate: true })
      return true
    }
    if (this.atStart) return
    const page = this.page - 1
    return this.#scrollToPage(page, 'page', { animate: true }).then(() => page <= 0)
  }
  #scrollNext(distance) {
    if (!this.#view) return true
    if (this.scrolled) {
      if (this.viewSize - this.end > 2) return this.#scrollTo(
        Math.min(this.viewSize, distance ? this.start + distance : this.end), null, { animate: true })
      return true
    }
    if (this.atEnd) return
    const page = this.page + 1
    const pages = this.pages
    return this.#scrollToPage(page, 'page', { animate: true }).then(() => page >= pages - 1)
  }
  get atStart() {
    return this.#adjacentIndex(-1) == null && this.page <= 1
  }
  get atEnd() {
    return this.#adjacentIndex(1) == null && this.page >= this.pages - 2
  }
  #adjacentIndex(dir) {
    for (let index = this.#index + dir; this.#canGoToIndex(index); index += dir)
      if (this.sections[index]?.linear !== 'no') return index
  }
  async #turnPage(dir, distance) {
    // if (this.#locked) return
    this.#locked = true
    // a turn requested while the view is being replaced by the adjacent
    // section (e.g. a second tap at the end of a chapter) continues from the
    // new section instead of from the blank page of the old one
    await this.#waitSectionChange()
    const prev = dir === -1
    // a paginated turn onto the blank page before/after the section goes on
    // to the adjacent section
    const crossing = !this.scrolled && !!this.#view && this.pages > 0
      && (prev ? !this.atStart && this.page - 1 <= 0
        : !this.atEnd && this.page + 1 >= this.pages - 1)
    if (crossing) this.#beginSectionChange()
    try {
      const shouldGo = await (prev ? this.#scrollPrev(distance) : this.#scrollNext(distance))

      if (shouldGo) await this.#goTo({
        index: this.#adjacentIndex(dir),
        anchor: prev ? () => 1 : () => 0,
      })
      if (shouldGo || !this.hasAttribute('animated')) await wait(100)
    } finally {
      if (crossing) this.#endSectionChange()
      this.#locked = false
    }
  }
  prev(distance) {
    return this.#turnPage(-1, distance)
  }
  next(distance) {
    return this.#turnPage(1, distance)
  }
  prevSection() {
    return this.goTo({ index: this.#adjacentIndex(-1) })
  }
  nextSection() {
    return this.goTo({ index: this.#adjacentIndex(1) })
  }
  firstSection() {
    const index = this.sections.findIndex(section => section.linear !== 'no')
    return this.goTo({ index })
  }
  lastSection() {
    const index = this.sections.findLastIndex(section => section.linear !== 'no')
    return this.goTo({ index })
  }
  getContents() {
    if (this.#view) return [{
      index: this.#index,
      overlayer: this.#view.overlayer,
      doc: this.#view.document,
    }]
    return []
  }
  setStyles(styles) {
    this.#styles = styles
    const $$styles = this.#styleMap.get(this.#view?.document)
    if (!$$styles) return
    const [$beforeStyle, $style] = $$styles
    if (Array.isArray(styles)) {
      const [beforeStyle, style] = styles
      $beforeStyle.textContent = beforeStyle
      $style.textContent = style
    } else $style.textContent = styles

    this.#applyBackground()

    // needed because the resize observer doesn't work in Firefox
    this.#view?.document?.fonts?.ready?.then(() => this.#view.expand())
  }
  get writingMode() {
    return this.#view?.writingMode
  }
  destroy() {
    // a section still loading must not install its view afterwards
    this.#displayToken++
    this.#cancelTurn()
    this.#observer.unobserve(this)
    this.#view.destroy()
    this.#view = null
    this.sections[this.#index]?.unload?.()
    this.#mediaQuery.removeEventListener('change', this.#mediaQueryListener)
    if (this.#pendingScrollFrame) {
      cancelAnimationFrame(this.#pendingScrollFrame)
      this.#pendingScrollFrame = null
    }
    if (this.#scrollEndTimer) {
      clearTimeout(this.#scrollEndTimer)
      this.#scrollEndTimer = null
    }
    this.#relocatePending = false
    for (const resolve of this.#relocateWaiters.splice(0)) resolve()
  }
}

customElements.define('foliate-paginator', Paginator)
