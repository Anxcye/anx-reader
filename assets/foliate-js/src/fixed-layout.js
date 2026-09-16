const parseViewport = str => str
    ?.split(/[,;\s]/) // NOTE: technically, only the comma is valid
    ?.filter(x => x)
    ?.map(x => x.split('=').map(x => x.trim()))

const getViewport = (doc, viewport) => {
    // use `viewBox` for SVG
    if (doc.documentElement.localName === 'svg') {
        const [, , width, height] = doc.documentElement
            .getAttribute('viewBox')?.split(/\s/) ?? []
        return { width, height }
    }

    // get `viewport` `meta` element
    const meta = parseViewport(doc.querySelector('meta[name="viewport"]')
        ?.getAttribute('content'))
    if (meta) return Object.fromEntries(meta)

    // fallback to book's viewport
    if (typeof viewport === 'string') return parseViewport(viewport)
    if (viewport) return viewport

    // if no viewport (possibly with image directly in spine), get image size
    const img = doc.querySelector('img')
    if (img) return { width: img.naturalWidth, height: img.naturalHeight }

    // just show *something*, i guess...
    console.warn(new Error('Missing viewport properties'))
    return { width: 1000, height: 2000 }
}

export class FixedLayout extends HTMLElement {
    static observedAttributes = ['flow', 'max-column-count', 'gap']

    #root = this.attachShadow({ mode: 'closed' })
    #observer = new ResizeObserver(() => this.#render())
    #spreads
    #index = -1
    defaultViewport
    spread
    #portrait = false
    #left
    #right
    #center
    #side
    // 'paginated' (one or two pages per screen) or 'scrolled' (continuous
    // vertical scrolling, pages fitted to the width of the view)
    #flow = 'paginated'
    // `spread` from the book's rendition, kept because `#maxColumnCount` can
    // override it
    #metaSpread
    // 0: auto, 1: always a single page, 2: always two pages side by side
    #maxColumnCount = 0
    // side margin of the app, as a percentage of the width
    #gap = 0
    #zoom = 1
    #scroller = null
    #rows = []
    #rowObserver = null
    #pinchStart = null
    #lastReportedIndex = -1
    #loadingRows = new Set()
    #scrollFrame = null
    #aspect = 1000 / 1414
    #aspectInitialized = false
    // page that was asked for but could not be scrolled to yet, because the
    // view had no size; it is applied after the first layout
    #pendingIndex = -1
    // bumped whenever the frames are replaced, so that pages still loading for
    // a previous layout are discarded instead of being inserted
    #generation = 0
    #zoomStep = 0
    constructor() {
        super()

        const sheet = new CSSStyleSheet()
        this.#root.adoptedStyleSheets = [sheet]
        sheet.replaceSync(`:host {
            width: 100%;
            height: 100%;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        :host(.scrolled) {
            display: block;
        }
        .scroller {
            position: relative;
            width: 100%;
            height: 100%;
            overflow: auto;
            overscroll-behavior: contain;
            scrollbar-width: none;
        }
        .scroller::-webkit-scrollbar {
            display: none;
        }
        .row {
            display: flex;
            flex-direction: row;
            justify-content: center;
            align-items: flex-start;
        }
        .holder {
            position: relative;
            overflow: hidden;
            flex: none;
        }
        .holder > div {
            position: absolute;
            top: 0;
            left: 0;
        }`)

        this.#observer.observe(this)
    }
    // `parent` defaults to the root, which is where the pages of the paginated
    // layout live; in scrolled mode they are created inside their own holder so
    // that the iframe is never moved (moving an iframe reloads it)
    async #createFrame(position, { index, src }, parent = this.#root) {
        const element = document.createElement('div')
        const iframe = document.createElement('iframe')
        element.append(iframe)
        Object.assign(iframe.style, {
            border: '0',
            display: 'none',
            overflow: 'hidden',
        })
        // `allow-scripts` is needed for events because of WebKit bug
        // https://bugs.webkit.org/show_bug.cgi?id=218086
        iframe.setAttribute('sandbox', 'allow-same-origin allow-scripts')
        iframe.setAttribute('scrolling', 'no')
        iframe.setAttribute('part', 'filter')
        parent.append(element)
        if (!src) return { blank: true, element, iframe }
        return new Promise(resolve => {
            const onload = () => {
                iframe.removeEventListener('load', onload)
                const doc = iframe.contentDocument
                doc.position = position
                this.dispatchEvent(new CustomEvent('load', { detail: { doc, index } }))
                const { width, height } = getViewport(doc, this.defaultViewport)
                resolve({
                    element, iframe,
                    width: parseFloat(width),
                    height: parseFloat(height),
                })
            }
            iframe.addEventListener('load', onload)
            iframe.src = src
        })
    }
    #render(side = this.#side) {
        if (this.#flow === 'scrolled') return this.#relayoutScroller()
        if (!side) return
        const left = this.#left ?? {}
        const right = this.#center ?? this.#right
        const target = side === 'left' ? left : right
        const { width, height } = this.getBoundingClientRect()
        const portrait = this.spread !== 'both' && this.spread !== 'portrait'
            && height > width
        this.#portrait = portrait
        const blankWidth = left.width ?? right.width
        const blankHeight = left.height ?? right.height

        const scale = portrait || this.#center
            ? Math.min(
                width / (target.width ?? blankWidth),
                height / (target.height ?? blankHeight))
            : Math.min(
                width / ((left.width ?? blankWidth) + (right.width ?? blankWidth)),
                height / Math.max(
                    left.height ?? blankHeight,
                    right.height ?? blankHeight))

        const transform = frame => {
            const { element, iframe, width, height, blank } = frame
            iframe.contentDocument.scale = scale
            Object.assign(iframe.style, {
                width: `${width}px`,
                height: `${height}px`,
                transform: `scale(${scale})`,
                transformOrigin: 'top left',
                display: blank ? 'none' : 'block',
            })
            Object.assign(element.style, {
                width: `${(width ?? blankWidth) * scale}px`,
                height: `${(height ?? blankHeight) * scale}px`,
                overflow: 'hidden',
                display: 'block',
            })
            if (portrait && frame !== target) {
                element.style.display = 'none'
            }
        }
        if (this.#center) {
            transform(this.#center)
        } else {
            transform(left)
            transform(right)
        }
    }
    async #showSpread({ left, right, center, side }) {
        const generation = this.#generation
        this.#root.replaceChildren()
        this.#left = null
        this.#right = null
        this.#center = null
        if (center) {
            const frame = await this.#createFrame('center', center)
            if (generation !== this.#generation) {
                frame.element.remove()
                return
            }
            this.#center = frame
            this.#side = 'center'
            this.#render()
        } else {
            const leftFrame = await this.#createFrame('left', left)
            const rightFrame = await this.#createFrame('right', right)
            if (generation !== this.#generation) {
                leftFrame.element.remove()
                rightFrame.element.remove()
                return
            }
            this.#left = leftFrame
            this.#right = rightFrame
            this.#side = leftFrame.blank ? 'right'
                : rightFrame.blank ? 'left' : side
            this.#render()
        }
    }
    #goLeft() {
        if (this.#center || this.#left?.blank) return
        if (this.#portrait && this.#left?.element?.style?.display === 'none') {
            this.#right.element.style.display = 'none'
            this.#left.element.style.display = 'block'
            this.#side = 'left'
            return true
        }
    }
    #goRight() {
        if (this.#center || this.#right?.blank) return
        if (this.#portrait && this.#right?.element?.style?.display === 'none') {
            this.#left.element.style.display = 'none'
            this.#right.element.style.display = 'block'
            this.#side = 'right'
            return true
        }
    }
    open(book) {
        this.book = book
        const { rendition } = book
        this.#metaSpread = rendition?.spread
        this.defaultViewport = rendition?.viewport

        const rtl = book.dir === 'rtl'
        this.rtl = rtl

        this.spread = this.#effectiveSpread()
        this.#buildSpreads()

        if (this.#flow === 'scrolled') this.#buildScroller()
    }
    // `max-column-count` (set by the app) takes precedence over the book's
    // rendition: 1 forces a single page, 2 forces two pages side by side.
    // In scrolled mode everything is a single page unless two are requested.
    #effectiveSpread() {
        if (this.#maxColumnCount === 1) return 'none'
        if (this.#maxColumnCount === 2) return 'both'
        if (this.#flow === 'scrolled') return 'none'
        return this.#metaSpread
    }
    #buildSpreads() {
        const book = this.book
        if (!book) return
        if (this.spread === 'none')
            this.#spreads = book.sections.map(section => ({ center: section }))
        else this.#spreads = book.sections.reduce((arr, section) => {
            const last = arr[arr.length - 1]
            const { linear, pageSpread } = section
            if (linear === 'no') return arr
            const newSpread = () => {
                const spread = {}
                arr.push(spread)
                return spread
            }
            if (pageSpread === 'center') {
                const spread = last.left || last.right ? newSpread() : last
                spread.center = section
            }
            else if (pageSpread === 'left') {
                const spread = last.center || last.left || !this.rtl ? newSpread() : last
                spread.left = section
            }
            else if (pageSpread === 'right') {
                const spread = last.center || last.right || this.rtl ? newSpread() : last
                spread.right = section
            }
            else if (!this.rtl) {
                if (last.center || last.right) newSpread().left = section
                else if (last.left) last.right = section
                else last.left = section
            }
            else {
                if (last.center || last.left) newSpread().right = section
                else if (last.right) last.left = section
                else last.right = section
            }
            return arr
        }, [{}])
    }
    attributeChangedCallback(name, _, value) {
        if (!this.book) return
        if (name === 'flow') {
            const flow = value === 'scrolled' ? 'scrolled' : 'paginated'
            if (flow === this.#flow) return
            this.#flow = flow
            this.#applyLayout()
        } else if (name === 'max-column-count') {
            const count = parseInt(value)
            const maxColumnCount = Number.isNaN(count) ? 0 : count
            if (maxColumnCount === this.#maxColumnCount) return
            this.#maxColumnCount = maxColumnCount
            this.spread = this.#effectiveSpread()
            this.#buildSpreads()
            this.#applyLayout()
        } else if (name === 'gap') {
            const gap = parseFloat(value)
            const next = Number.isNaN(gap) ? 0 : gap
            if (next === this.#gap) return
            this.#gap = next
            this.#relayoutScroller()
        }
    }
    // rebuild the current layout after a change that affects it
    #applyLayout() {
        const index = this.#index < 0
            ? 0
            : Math.min(this.#index, this.#spreads.length - 1)
        this.#destroyScroller()
        this.#clearFrames()
        if (this.#flow === 'scrolled') {
            this.#index = index
            this.#buildScroller().then(() => this.#reportLocation('page'))
        } else {
            // force `goToSpread` to create the frames again
            this.#index = -1
            this.goToSpread(index, 'center')
        }
    }
    #clearFrames() {
        this.#generation++
        this.#left = null
        this.#right = null
        this.#center = null
        this.#root.replaceChildren()
    }
    get flow() {
        return this.#flow
    }
    get zoom() {
        return this.#zoom
    }
    // fixed layout pages are always laid out horizontally, but `book.js`
    // expects every renderer to report a writing mode
    get writingMode() {
        return 'horizontal-tb'
    }
    // zoom keeps the page fitted to the width of the view at 1
    setZoom(zoom, anchor) {
        if (this.#flow !== 'scrolled') return
        const scroller = this.#scroller
        if (!scroller) return
        const next = Math.min(5, Math.max(0.25, zoom))
        if (Math.abs(next - this.#zoom) < 0.005) return
        const previous = this.#zoom
        const offset = anchor?.offsetY ?? scroller.clientHeight / 2
        this.#zoom = next
        this.#relayoutScroller()
        // keep the point under the cursor in place while zooming
        scroller.scrollTop =
            (scroller.scrollTop + offset) * (next / previous) - offset
    }
    get index() {
        const spread = this.#spreads[this.#index]
        const section = spread?.center ?? (this.side === 'left'
            ? spread.left ?? spread.right : spread.right ?? spread.left)
        return this.book.sections.indexOf(section)
    }
    #reportLocation(reason) {
        this.dispatchEvent(new CustomEvent('relocate', { detail:
            { reason, range: null, index: this.index, fraction: 0, size: 1 } }))
    }
    getSpreadOf(section) {
        const spreads = this.#spreads
        for (let index = 0; index < spreads.length; index++) {
            const { left, right, center } = spreads[index]
            if (left === section) return { index, side: 'left' }
            if (right === section) return { index, side: 'right' }
            if (center === section) return { index, side: 'center' }
        }
    }
    async goToSpread(index, side, reason) {
        if (index < 0 || index > this.#spreads.length - 1) return
        if (this.#flow === 'scrolled') {
            this.#index = index
            this.#lastReportedIndex = index
            await this.#scrollToRow(index, reason !== 'page')
            this.#reportLocation(reason ?? 'page')
            return
        }
        if (index === this.#index) {
            this.#render(side)
            return
        }
        this.#index = index
        const spread = this.#spreads[index]
        if (spread.center) {
            const index = this.book.sections.indexOf(spread.center)
            const src = await spread.center?.load?.()
            await this.#showSpread({ center: { index, src } })
        } else {
            const indexL = this.book.sections.indexOf(spread.left)
            const indexR = this.book.sections.indexOf(spread.right)
            const srcL = await spread.left?.load?.()
            const srcR = await spread.right?.load?.()
            const left = { index: indexL, src: srcL }
            const right = { index: indexR, src: srcR }
            await this.#showSpread({ left, right, side })
        }
        this.#reportLocation(reason)
    }
    async #scrollToRow(index, immediate = false) {
        const scroller = this.#scroller
        const row = this.#rows[index]
        if (!scroller || !row) return
        await this.#loadRow(row)
        if (this.#scroller !== scroller) return
        // if the view has no size yet, or the pages were not laid out, the row
        // offsets are meaningless: remember the page and apply it later
        if (!this.#relayoutScroller()) {
            this.#pendingIndex = index
            return
        }
        this.#pendingIndex = -1
        const top = row.element.offsetTop
        if (immediate) scroller.scrollTop = top
        else scroller.scrollTo({ top, behavior: 'smooth' })
    }
    #reportVisibleRow() {
        const scroller = this.#scroller
        // do not report (and do not move the current page) while the page the
        // reader asked for is still waiting for the first layout
        if (!scroller || this.#pendingIndex >= 0) return
        const top = scroller.scrollTop
        let row = this.#rows[this.#index]
        for (const candidate of this.#rows)
            if (candidate.element.offsetTop + candidate.element.offsetHeight > top + 1) {
                row = candidate
                break
            }
        if (!row) return
        const index = this.#rows.indexOf(row)
        if (index === this.#lastReportedIndex) return
        this.#lastReportedIndex = index
        this.#index = index
        this.#reportLocation('scroll')
    }
    #onScroll = () => {
        if (this.#flow !== 'scrolled' || !this.#scroller) return
        if (this.#scrollFrame) return
        this.#scrollFrame = requestAnimationFrame(() => {
            this.#scrollFrame = null
            this.#reportVisibleRow()
        })
    }
    // pinch to zoom on touch screens; Ctrl/⌘ + wheel (or a trackpad pinch,
    // which browsers report as a wheel event with `ctrlKey`) on desktop
    #onWheel = event => {
        if (this.#flow !== 'scrolled') return
        const scroller = this.#scroller
        if (!scroller) return
        if (event.ctrlKey || event.metaKey) {
            event.preventDefault()
            this.#zoomByWheel(event)
            return
        }
        // wheel events over a page are dispatched to that page's own document
        // and do not always reach the scroller, so scroll here instead
        const unit = event.deltaMode === 1 ? 32
            : event.deltaMode === 2 ? scroller.clientHeight : 1
        let deltaX = event.deltaX * unit
        let deltaY = event.deltaY * unit
        const canScrollX = scroller.scrollWidth > scroller.clientWidth + 1
        const canScrollY = scroller.scrollHeight > scroller.clientHeight + 1
        if (!canScrollX && canScrollY && Math.abs(deltaX) > Math.abs(deltaY)) {
            // some precision touchpads report a two finger vertical swipe with
            // deltaX; with nothing to scroll sideways, treat it as vertical
            deltaY = -deltaX
            deltaX = 0
        }
        if (!deltaX && !deltaY) return
        if (!(deltaY && canScrollY) && !(deltaX && canScrollX)) return
        event.preventDefault()
        if (deltaX) scroller.scrollLeft += deltaX
        if (deltaY) scroller.scrollTop += deltaY
    }
    #zoomByWheel(event) {
        const scroller = this.#scroller
        const anchor = event.currentTarget === scroller
            ? { offsetY: event.clientY - scroller.getBoundingClientRect().top }
            : undefined
        const unit = event.deltaMode === 1 ? 16 : 1
        let delta = event.deltaY * unit
        if (!delta && event.deltaX) {
            // a trackpad pinch (or Ctrl + two finger swipe) can be reported on
            // the horizontal axis and with a jittery sign, so it is accumulated
            // and applied in steps
            this.#zoomStep += event.deltaX * unit
            if (Math.abs(this.#zoomStep) < 40) return
            delta = -this.#zoomStep / 4
            this.#zoomStep = 0
        }
        this.setZoom(this.#zoom * Math.exp(-delta * 0.002), anchor)
    }
    #onKeyDown = event => {
        if (this.#flow !== 'scrolled') return
        if (!event.ctrlKey && !event.metaKey) return
        const zoom = event.key === '=' || event.key === '+'
            ? this.#zoom * 1.25
            : event.key === '-' || event.key === '_'
                ? this.#zoom / 1.25
                : event.key === '0' ? 1 : null
        if (zoom === null) return
        event.preventDefault()
        this.setZoom(zoom)
    }
    #pinchDistance = touches => Math.hypot(
        touches[0].clientX - touches[1].clientX,
        touches[0].clientY - touches[1].clientY)
    #onTouchStart = event => {
        if (event.touches.length !== 2) return
        this.#pinchStart = {
            distance: this.#pinchDistance(event.touches),
            zoom: this.#zoom,
        }
    }
    #onTouchMove = event => {
        if (!this.#pinchStart || event.touches.length !== 2) return
        if (!this.#pinchStart.distance) return
        event.preventDefault()
        const anchor = event.currentTarget === this.#scroller
            ? {
                offsetY: (event.touches[0].clientY + event.touches[1].clientY) / 2
                    - this.#scroller.getBoundingClientRect().top,
            }
            : undefined
        this.setZoom(
            this.#pinchStart.zoom * this.#pinchDistance(event.touches)
                / this.#pinchStart.distance,
            anchor)
    }
    #onTouchEnd = () => {
        this.#pinchStart = null
    }
    #buildScroller() {
        if (!this.book) return Promise.resolve()
        this.#destroyScroller()

        const scroller = document.createElement('div')
        scroller.className = 'scroller'
        this.#scroller = scroller
        this.classList.add('scrolled')
        this.#root.append(scroller)

        this.#rows = this.#spreads.map(spread => {
            const row = document.createElement('div')
            row.className = 'row'
            const pages = spread.center
                ? [{ section: spread.center, position: 'center' }]
                : [
                    spread.left && { section: spread.left, position: 'left' },
                    spread.right && { section: spread.right, position: 'right' },
                ].filter(Boolean)
            const entry = {
                element: row,
                index: this.book.sections.indexOf(
                    spread.center ?? spread.left ?? spread.right),
                pages: [],
            }
            for (const page of pages) {
                const holder = document.createElement('div')
                holder.className = 'holder'
                row.append(holder)
                entry.pages.push({ ...page, holder, frame: null })
            }
            scroller.append(row)
            return entry
        })

        this.#rowObserver = new IntersectionObserver(entries => {
            for (const { target, isIntersecting } of entries) {
                const index = this.#rows.findIndex(row => row.element === target)
                const row = this.#rows[index]
                if (!row) continue
                if (isIntersecting) this.#loadRow(row)
                else if (Math.abs(index - this.#index) > 3) this.#unloadRow(row)
            }
        }, { root: scroller, rootMargin: '200% 0px' })
        for (const row of this.#rows) this.#rowObserver.observe(row.element)

        scroller.addEventListener('scroll', this.#onScroll, { passive: true })
        scroller.addEventListener('wheel', this.#onWheel, { passive: false })
        scroller.addEventListener('touchstart', this.#onTouchStart, { passive: true })
        scroller.addEventListener('touchmove', this.#onTouchMove, { passive: false })
        scroller.addEventListener('touchend', this.#onTouchEnd, { passive: true })
        document.addEventListener('keydown', this.#onKeyDown)

        this.#index = this.#index < 0 ? 0 : this.#index
        this.#lastReportedIndex = this.#index
        this.#relayoutScroller()
        // a page's aspect ratio is needed to reserve its space before the
        // image is loaded, so that scrolling and the scrollbar stay stable
        if (!this.#aspectInitialized) {
            this.book.getPageSize?.(0)?.then(size => {
                if (this.#flow !== 'scrolled' || !this.#scroller || !size?.height)
                    return
                this.#aspect = size.width / size.height
                this.#aspectInitialized = true
                this.#relayoutScroller()
            })
        }
        return this.#scrollToRow(this.#index, true)
    }
    #destroyScroller() {
        const scroller = this.#scroller
        this.#generation++
        if (scroller) {
            scroller.removeEventListener('scroll', this.#onScroll)
            scroller.removeEventListener('wheel', this.#onWheel)
            scroller.removeEventListener('touchstart', this.#onTouchStart)
            scroller.removeEventListener('touchmove', this.#onTouchMove)
            scroller.removeEventListener('touchend', this.#onTouchEnd)
            scroller.remove()
        }
        document.removeEventListener('keydown', this.#onKeyDown)
        this.#rowObserver?.disconnect()
        this.#rowObserver = null
        this.#scroller = null
        this.#rows = []
        this.#loadingRows.clear()
        this.#zoom = 1
        this.#pendingIndex = -1
        this.#pinchStart = null
        this.#lastReportedIndex = -1
        this.classList.remove('scrolled')
    }
    async #loadRow(row) {
        // frames are not created until the view has a size, otherwise every row
        // would look visible and the whole book would be loaded at once
        if (!row || !this.#scroller?.clientWidth) return
        if (this.#loadingRows.has(row)) return
        const generation = this.#generation
        this.#loadingRows.add(row)
        try {
            await Promise.all(row.pages.map(async page => {
                if (page.frame || this.#flow !== 'scrolled') return
                const index = this.book.sections.indexOf(page.section)
                const src = await page.section?.load?.()
                if (this.#flow !== 'scrolled' || generation !== this.#generation)
                    return
                const frame = await this.#createFrame(page.position, { index, src },
                    page.holder)
                if (generation !== this.#generation) {
                    frame.element.remove()
                    return
                }
                page.frame = frame
                // wheel/touch events over a page go to its own document, so
                // listen there as well to support zooming while reading
                const doc = frame.iframe.contentDocument
                if (doc) {
                    doc.addEventListener('wheel', this.#onWheel, { passive: false })
                    doc.addEventListener('touchstart', this.#onTouchStart, { passive: true })
                    doc.addEventListener('touchmove', this.#onTouchMove, { passive: false })
                    doc.addEventListener('touchend', this.#onTouchEnd, { passive: true })
                }
            }))
        } finally {
            this.#loadingRows.delete(row)
        }
        this.#relayoutScroller()
    }
    #unloadRow(row) {
        if (!row) return
        for (const page of row.pages) {
            if (!page.frame) continue
            const doc = page.frame.iframe.contentDocument
            if (doc) {
                doc.removeEventListener('wheel', this.#onWheel)
                doc.removeEventListener('touchstart', this.#onTouchStart)
                doc.removeEventListener('touchmove', this.#onTouchMove)
                doc.removeEventListener('touchend', this.#onTouchEnd)
            }
            page.frame.iframe.src = 'about:blank'
            page.frame.element.remove()
            page.frame = null
        }
        this.#relayoutScroller()
    }
    // fit every page to the width of the view (times the zoom level)
    #relayoutScroller() {
        const scroller = this.#scroller
        if (!scroller) return false
        const width = scroller.clientWidth
        if (!width) return false
        // the side margin of the app, half of it on each side of a page
        const inset = Math.min(this.#gap, 20) / 200 * width
        const contentWidth = Math.max(width - inset * 2, 1)
        for (const row of this.#rows) {
            const columnWidth = contentWidth / row.pages.length
            let rowHeight = 0
            for (const { frame, holder } of row.pages) {
                const pageWidth = frame?.width ?? columnWidth
                const pageHeight = frame?.height ?? columnWidth / this.#aspect
                const scale = columnWidth * this.#zoom / pageWidth
                holder.style.width = `${pageWidth * scale}px`
                holder.style.height = `${pageHeight * scale}px`
                if (frame) {
                    Object.assign(frame.iframe.style, {
                        width: `${frame.width}px`,
                        height: `${frame.height}px`,
                        transform: `scale(${scale})`,
                        transformOrigin: 'top left',
                        display: 'block',
                    })
                    frame.iframe.contentDocument.scale = scale
                }
                rowHeight = Math.max(rowHeight, pageHeight * scale)
            }
            row.element.style.height = `${rowHeight}px`
        }
        // the page that was asked for before the view had a size is applied now
        if (this.#pendingIndex >= 0) {
            const index = this.#pendingIndex
            this.#pendingIndex = -1
            this.#scrollToRow(index, true)
        }
        return true
    }
    async select(target) {
        await this.goTo(target)
        // TODO
    }
    async goTo(target) {
        const { book } = this
        const resolved = await target
        const section = book.sections[resolved.index]
        if (!section) return
        const { index, side } = this.getSpreadOf(section)
        await this.goToSpread(index, side)
    }
    async next() {
        if (this.#flow === 'scrolled') {
            const scroller = this.#scroller
            const row = this.#rows[this.#index]
            if (!scroller || !row) return
            // reveal the rest of the current page before moving on
            const remaining = row.element.offsetTop + row.element.offsetHeight
                - scroller.scrollTop - scroller.clientHeight
            if (remaining > 1) {
                this.#scrollTo(scroller, scroller.scrollTop
                    + Math.min(remaining, scroller.clientHeight))
                this.#reportLocation('page')
                return
            }
            if (this.#index < this.#rows.length - 1)
                this.goToSpread(this.#index + 1, 'left', 'page')
            return
        }
        const s = this.rtl ? this.#goLeft() : this.#goRight()
        if (s) this.#reportLocation('page')
        else return this.goToSpread(this.#index + 1, this.rtl ? 'right' : 'left', 'page')
    }
    async prev() {
        if (this.#flow === 'scrolled') {
            const scroller = this.#scroller
            const row = this.#rows[this.#index]
            if (!scroller || !row) return
            // go back to the top of the current page first
            const offset = scroller.scrollTop - row.element.offsetTop
            if (offset > 1) {
                this.#scrollTo(scroller, scroller.scrollTop
                    - Math.min(offset, scroller.clientHeight))
                this.#reportLocation('page')
                return
            }
            if (this.#index > 0) this.goToSpread(this.#index - 1, 'left', 'page')
            return
        }
        const s = this.rtl ? this.#goRight() : this.#goLeft()
        if (s) this.#reportLocation('page')
        else return this.goToSpread(this.#index - 1, this.rtl ? 'left' : 'right', 'page')
    }
    #scrollTo(scroller, top) {
        scroller.scrollTo({ top, behavior: 'smooth' })
    }
    getContents() {
        return Array.from(this.#root.querySelectorAll('iframe'), frame => ({
            doc: frame.contentDocument,
            // TODO: index, overlayer
        }))
    }
    destroy() {
        this.#observer.unobserve(this)
        this.#destroyScroller()
    }
}

customElements.define('foliate-fxl', FixedLayout)
