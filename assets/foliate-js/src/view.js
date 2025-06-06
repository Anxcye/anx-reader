import * as CFI from './epubcfi.js'
import { TOCProgress, SectionProgress } from './progress.js'
import { Overlayer } from './overlayer.js'
import { textWalker } from './text-walker.js'
const { TTS } = await import('./tts.js')

const SEARCH_PREFIX = 'foliate-search:'

class History extends EventTarget {
  #arr = []
  #index = -1
  pushState(x) {
    const last = this.#arr[this.#index]
    if (last === x || last?.fraction && last.fraction === x.fraction) return
    this.#arr[++this.#index] = x
    this.#arr.length = this.#index + 1
    this.dispatchEvent(new Event('index-change'))
    this.dispatchEvent(new CustomEvent('pushstate', { detail: x }))
  }
  replaceState(x) {
    const index = this.#index
    this.#arr[index] = x
  }
  back() {
    const index = this.#index
    if (index <= 0) return
    const detail = { state: this.#arr[index - 1] }
    this.#index = index - 1
    this.dispatchEvent(new CustomEvent('popstate', { detail }))
    this.dispatchEvent(new Event('index-change'))
  }
  forward() {
    const index = this.#index
    if (index >= this.#arr.length - 1) return
    const detail = { state: this.#arr[index + 1] }
    this.#index = index + 1
    this.dispatchEvent(new CustomEvent('popstate', { detail }))
    this.dispatchEvent(new Event('index-change'))
  }
  get canGoBack() {
    return this.#index > 0
  }
  get canGoForward() {
    return this.#index < this.#arr.length - 1
  }
  clear() {
    this.#arr = []
    this.#index = -1
  }
}

const languageInfo = lang => {
  if (!lang) return {}
  try {
    const canonical = Intl.getCanonicalLocales(lang)[0] ?? 'en'
    const locale = new Intl.Locale(canonical)
    const isCJK = ['zh', 'ja', 'kr'].includes(locale.language)
    const direction = (locale.getTextInfo?.() ?? locale.textInfo)?.direction
    return { canonical, locale, isCJK, direction }
  } catch (e) {
    console.warn(e)
    return {}
  }
}

export class View extends HTMLElement {
  #root = this.attachShadow({ mode: 'open' })
  #sectionProgress
  #tocProgress
  #pageProgress
  #searchResults = new Map()
  #index
  isFixedLayout = false
  lastLocation
  history = new History()
  #lastCfi = null
  constructor() {
    super()
    this.history.addEventListener('popstate', ({ detail }) => {
      const resolved = this.resolveNavigation(detail.state)
      this.renderer.goTo(resolved)
    })
  }
  async open(book) {
    this.book = book
    this.language = languageInfo(book.metadata?.language)

    if (book.splitTOCHref && book.getTOCFragment) {
      const ids = book.sections.map(s => s.id)
      this.#sectionProgress = new SectionProgress(book.sections, 1500, 1600)
      const splitHref = book.splitTOCHref.bind(book)
      const getFragment = book.getTOCFragment.bind(book)
      this.#tocProgress = new TOCProgress()
      await this.#tocProgress.init({
        toc: book.toc ?? [], ids, splitHref, getFragment
      })
      this.#pageProgress = new TOCProgress()
      await this.#pageProgress.init({
        toc: book.pageList ?? [], ids, splitHref, getFragment
      })
    }

    this.isFixedLayout = this.book.rendition?.layout === 'pre-paginated'
    if (this.isFixedLayout) {
      await import('./fixed-layout.js')
      this.renderer = document.createElement('foliate-fxl')
    } else {
      await import('./paginator.js')
      this.renderer = document.createElement('foliate-paginator')
    }
    this.renderer.setAttribute('exportparts', 'head,foot,filter')
    this.renderer.addEventListener('load', e => this.#onLoad(e.detail))
    this.renderer.addEventListener('relocate', e => this.#onRelocate(e.detail))
    this.renderer.addEventListener('create-overlayer', e =>
      e.detail.attach(this.#createOverlayer(e.detail)))
    this.renderer.open(book)
    this.#root.append(this.renderer)

    if (book.sections.some(section => section.mediaOverlay)) {
      book.media.activeClass ||= '-epub-media-overlay-active'
      const activeClass = book.media.activeClass
      this.mediaOverlay = book.getMediaOverlay()
      let lastActive
      this.mediaOverlay.addEventListener('highlight', e => {
        const resolved = this.resolveNavigation(e.detail.text)
        this.renderer.goTo(resolved)
          .then(() => {
            const { doc } = this.renderer.getContents()
              .find(x => x.index = resolved.index)
            const el = resolved.anchor(doc)
            el.classList.add(activeClass)
            lastActive = new WeakRef(el)
          })
      })
      this.mediaOverlay.addEventListener('unhighlight', () => {
        lastActive?.deref()?.classList?.remove(activeClass)
      })
    }
  }
  close() {
    this.renderer?.destroy()
    this.renderer?.remove()
    this.#sectionProgress = null
    this.#tocProgress = null
    this.#pageProgress = null
    this.#searchResults = new Map()
    this.lastLocation = null
    this.history.clear()
    this.tts = null
    this.mediaOverlay = null
  }
  goToTextStart() {
    return this.goTo(this.book.landmarks
      ?.find(m => m.type.includes('bodymatter') || m.type.includes('text'))
      ?.href ?? this.book.sections.findIndex(s => s.linear !== 'no'))
  }
  async init({ lastLocation, showTextStart }) {
    const resolved = lastLocation ? this.resolveNavigation(lastLocation) : null
    if (resolved) {
      await this.renderer.goTo(resolved)
      this.history.pushState(lastLocation)
    }
    else if (showTextStart) await this.goToTextStart()
    else {
      this.history.pushState(0)
      await this.next()
    }
  }
  #emit(name, detail, cancelable) {
    return this.dispatchEvent(new CustomEvent(name, { detail, cancelable }))
  }
  #onRelocate({ reason, range, index, fraction, size }) {
    this.#index = index
    const progress = this.#sectionProgress?.getProgress(index, fraction, size) ?? {}
    const tocItem = this.#tocProgress?.getProgress(index, range)
    const pageItem = this.#pageProgress?.getProgress(index, range)
    const cfi = this.getCFI(index, range)
    const totalPages = this.renderer.pages ? this.renderer.pages - 2 : progress.section.total
    const currentPage = this.renderer.page ?? progress.section.current
    const chapterLocation = {
      current: currentPage,
      total: totalPages
    }

    this.lastLocation = { ...progress, tocItem, pageItem, cfi, range, chapterLocation }
    if (reason === 'snap' || reason === 'page' || reason === 'scroll')
      this.history.replaceState(cfi)

    if (cfi && (!this.#lastCfi || cfi !== this.#lastCfi)) {
      this.#lastCfi = cfi
      this.#emit('relocate', this.lastLocation)
    }
  }

  #onLoad({ doc, index }) {
    // set language and dir if not already set
    doc.documentElement.lang ||= this.language.canonical ?? ''
    if (!this.language.isCJK)
      doc.documentElement.dir ||= this.language.direction ?? ''

    this.#handleLinks(doc, index)
    this.#handleClick(doc)
    this.#handleImage(doc)
    this.#emit('load', { doc, index })
  }
  #handleLinks(doc, index) {
    const { book } = this
    const section = book.sections[index]
    for (const a of doc.querySelectorAll('a[href]'))
      a.addEventListener('click', e => {
        e.preventDefault()
        e.stopPropagation()
        const href_ = a.getAttribute('href')
        const href = section?.resolveHref?.(href_) ?? href_
        if (book?.isExternal?.(href))
          Promise.resolve(this.#emit('external-link', { a, href }, true))
            .then(x => x ? globalThis.open(href, '_blank') : null)
            .catch(e => console.error(e))
        else Promise.resolve(this.#emit('link', { a, href }, true))
          .then(x => x ? this.goTo(href) : null)
          .catch(e => console.error(e))
      })
  }

  #handleImage(doc) {
    for (const img of doc.querySelectorAll('img')) {
      // disable for a link
      if (img.closest('a[href]')) continue;
      img.addEventListener('click', e => {
        e.preventDefault()
        e.stopPropagation()
        this.#emit('click-image', { img })
      })
    }
  }

  #handleClick(doc) {
    doc.addEventListener('click', e => {
      if (window.isFootNoteOpen()) {
        window.closeFootNote()
        return
      }

      if (doc.getSelection().type === "Range")
        return

      const position = doc.position
      const scale = doc.scale
      let { clientX, clientY } = e

      // if the position is not null, it is fixed layout
      if (position) {
        clientX *= scale
        clientY *= scale

        const docWidth = doc.documentElement.getBoundingClientRect().width * scale
        if (position === 'right' && docWidth * 2.2 < window.innerWidth) {
          clientX += window.innerWidth * 0.5
        }
        this.#emit('click-view', { x: clientX, y: clientY })
        return
      }
      if (this.renderer.vertical) {
        this.renderer.scrollProp == 'scrollLeft'
          ? clientX = this.renderer.size - (this.renderer.viewSize - this.renderer.start - clientX)
          : clientY -= (this.renderer.start - this.renderer.size)
      }
      else {
        this.renderer.scrollProp == 'scrollLeft'
          ? clientX -= (this.renderer.start - this.renderer.size)
          : clientY -= (this.renderer.start)
      }

      this.#emit('click-view', { x: clientX, y: clientY })
    })
    this.renderer.addEventListener('click', e => {
      const { clientX, clientY } = e
      while (clientX > window.innerWidth) {
        clientX -= window.innerWidth
      }
      this.#emit('click-view', { x: clientX, y: clientY })
    })
  }
  async addAnnotation(annotation, remove) {
    const { value } = annotation
    if (value.startsWith(SEARCH_PREFIX)) {
      const cfi = value.replace(SEARCH_PREFIX, '')
      const { index, anchor } = await this.resolveNavigation(cfi)
      const obj = this.#getOverlayer(index)
      if (obj) {
        const { overlayer, doc } = obj
        if (remove) {
          overlayer.remove(value)
          return
        }
        const range = doc ? anchor(doc) : anchor
        overlayer.add(value, range, Overlayer.outline, { color: '#39c5bbaa' });
      }
      return
    }
    const { index, anchor } = await this.resolveNavigation(value)
    const obj = this.#getOverlayer(index)
    if (obj) {
      const { overlayer, doc } = obj
      overlayer.remove(value)
      if (!remove) {
        const range = doc ? anchor(doc) : anchor
        const draw = (func, opts) => overlayer.add(value, range, func, opts)
        this.#emit('draw-annotation', { draw, annotation, doc, range })
      }
    }
    const label = this.#tocProgress.getProgress(index)?.label ?? ''
    return { index, label }
  }
  deleteAnnotation(annotation) {
    return this.addAnnotation(annotation, true)
  }
  #getOverlayer(index) {
    return this.renderer.getContents()
      .find(x => x.index === index && x.overlayer)
  }
  #createOverlayer({ doc, index }) {
    const overlayer = new Overlayer()
    doc.addEventListener('click', e => {
      const [value, range] = overlayer.hitTest(e)
      if (value && !value.startsWith(SEARCH_PREFIX)) {
        e.preventDefault()
        e.stopPropagation()
        this.#emit('show-annotation', { value, index, range })
      }
    }, true)

    const list = this.#searchResults.get(index)
    if (list) for (const item of list) this.addAnnotation(item)

    this.#emit('create-overlay', { index })
    return overlayer
  }
  async showAnnotation(annotation) {
    const { value } = annotation
    const resolved = await this.goTo(value)
    if (resolved) {
      const { index, anchor } = resolved
      const { doc } = this.#getOverlayer(index)
      const range = anchor(doc)
      this.#emit('show-annotation', { value, index, range })
    }
  }
  getCFI(index, range) {
    const baseCFI = this.book.sections[index].cfi ?? CFI.fake.fromIndex(index)
    if (!range) return baseCFI
    return CFI.joinIndir(baseCFI, CFI.fromRange(range))
  }
  resolveCFI(cfi) {
    if (this.book.resolveCFI)
      return this.book.resolveCFI(cfi)
    else {
      const parts = CFI.parse(cfi)
      const index = CFI.fake.toIndex((parts.parent ?? parts).shift())
      const anchor = doc => CFI.toRange(doc, parts)
      return { index, anchor }
    }
  }
  resolveNavigation(target) {
    try {
      if (typeof target === 'number') return { index: target }
      if (typeof target.fraction === 'number') {
        const [index, anchor] = this.#sectionProgress.getSection(target.fraction)
        return { index, anchor }
      }
      if (CFI.isCFI.test(target)) return this.resolveCFI(target)
      return this.book.resolveHref(target)
    } catch (e) {
      console.error(e)
      console.error(`Could not resolve target ${target}`)
    }
  }
  async goTo(target) {
    const resolved = this.resolveNavigation(target)
    try {
      await this.renderer.goTo(resolved)
      this.history.pushState(target)
      return resolved
    } catch (e) {
      console.error(e)
      console.error(`Could not go to ${target}`)
    }
  }
  async goToFraction(frac) {
    const [index, anchor] = this.#sectionProgress.getSection(frac)
    await this.renderer.goTo({ index, anchor })
    this.history.pushState({ fraction: frac })
  }
  async select(target) {
    try {
      const obj = await this.resolveNavigation(target)
      await this.renderer.goTo({ ...obj, select: true })
      this.history.pushState(target)
    } catch (e) {
      console.error(e)
      console.error(`Could not go to ${target}`)
    }
  }
  deselect() {
    for (const { doc } of this.renderer.getContents())
      doc.defaultView.getSelection().removeAllRanges()
  }
  getSectionFractions() {
    const hrefList = this.#tocProgress?.ids ?? []
    return (this.#sectionProgress?.sectionFractions ?? [])
    // .map(x => x + Number.EPSILON)
      .map((fraction, index) => ({
        fraction,
        href: hrefList[index] ?? '',
        index
      }))
  }
  getProgressOf(index, range) {
    const tocItem = this.#tocProgress?.getProgress(index, range)
    const pageItem = this.#pageProgress?.getProgress(index, range)
    return { tocItem, pageItem }
  }
  async getTOCItemOf(target) {
    try {
      const { index, anchor } = await this.resolveNavigation(target)
      const doc = await this.book.sections[index].createDocument()
      const frag = anchor(doc)
      const isRange = frag instanceof Range
      const range = isRange ? frag : doc.createRange()
      if (!isRange) range.selectNodeContents(frag)
      return this.#tocProgress.getProgress(index, range)
    } catch (e) {
      console.error(e)
      console.error(`Could not get ${target}`)
    }
  }
  async prev(distance) {
    await this.renderer.prev(distance)
  }
  async next(distance) {
    await this.renderer.next(distance)
  }
  goLeft() {
    return this.book.dir === 'rtl' ? this.next() : this.prev()
  }
  goRight() {
    return this.book.dir === 'rtl' ? this.prev() : this.next()
  }
  async * #searchSection(matcher, query, index) {
    const doc = await this.book.sections[index].createDocument()
    for (const { range, excerpt } of matcher(doc, query))
      yield { cfi: this.getCFI(index, range), excerpt }
  }
  async * #searchBook(matcher, query) {
    const { sections } = this.book
    for (const [index, { createDocument }] of sections.entries()) {
      if (!createDocument) continue
      const doc = await createDocument()
      const subitems = Array.from(matcher(doc, query), ({ range, excerpt }) =>
        ({ cfi: this.getCFI(index, range), excerpt }))
      const progress = (index + 1) / sections.length
      yield { progress }
      if (subitems.length) yield { index, subitems }
    }
  }
  async * search(opts) {
    console.log('search', opts)
    this.clearSearch()
    const { searchMatcher } = await import('./search.js')
    const { query, index } = opts
    const matcher = searchMatcher(textWalker,
      { defaultLocale: this.language, ...opts })
    const iter = index != null
      ? this.#searchSection(matcher, query, index)
      : this.#searchBook(matcher, query)

    const list = []
    this.#searchResults.set(index, list)

    for await (const result of iter) {
      if (result.subitems) {
        const list = result.subitems
          .map(({ cfi }) => ({ value: SEARCH_PREFIX + cfi }))
        this.#searchResults.set(result.index, list)
        for (const item of list) this.addAnnotation(item)
        yield {
          label: this.#tocProgress.getProgress(result.index)?.label ?? '',
          subitems: result.subitems,
        }
      }
      else {
        if (result.cfi) {
          const item = { value: SEARCH_PREFIX + result.cfi }
          list.push(item)
          this.addAnnotation(item)
        }
        yield result
      }
    }
    yield 'done'
  }
  clearSearch() {
    for (const list of this.#searchResults.values())
      for (const item of list) this.deleteAnnotation(item)
    this.#searchResults.clear()
  }
  oldValue = null
  initTTS(stop) {
    if (stop)
      return this.#getOverlayer(this.#index)?.overlayer.remove(this.oldValue)

    const doc = this.renderer.getContents()[0].doc;
    if (this.tts && this.tts.doc === doc) return;
    this.tts = new TTS(doc, textWalker, (range) => {
      const obj = this.#getOverlayer(this.#index);
      if (obj) {
        const { overlayer } = obj;
        if (this.oldValue) {
          overlayer.remove(this.oldValue);
        }
        const value = this.getCFI(this.#index, range);
        overlayer.add(value, range, Overlayer.squiggly, { color: '#39c5bb' });
        this.oldValue = value;
      }
      this.renderer.scrollToAnchor(range);
    });
  }
  startMediaOverlay() {
    const { index } = this.renderer.getContents()[0]
    return this.mediaOverlay.start(index)
  }
}

customElements.define('foliate-view', View)
