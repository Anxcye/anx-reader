const blockTags = new Set([
    'article', 'aside', 'audio', 'blockquote', 'caption',
    'details', 'dialog', 'div', 'dl', 'dt', 'dd',
    'figure', 'footer', 'form', 'figcaption',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'hgroup', 'hr', 'li',
    'main', 'math', 'nav', 'ol', 'p', 'pre', 'section', 'tr',
])

function rangeIsEmpty(range) {
    return range.collapsed || range.toString().trim() === ''
}

const quoteChars = new Set(['"', "'", '“', '”', '‘', '’'])

const isLocalLink = href => {
    if (!href) return false
    const trimmed = href.trim()
    if (!trimmed) return false
    if (trimmed.startsWith('#')) return true
    return !/^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(trimmed)
}

const shouldSkipTextNode = node => {
    const parent = node.parentElement
    if (!parent) return false
    const anchor = parent.closest('a')
    if (!anchor) return false
    return isLocalLink(anchor.getAttribute('href'))
}

const getRangeText = range => {
    const fragment = range.cloneContents()
    const walker = document.createTreeWalker(fragment, NodeFilter.SHOW_TEXT)
    let text = ''
    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
        if (shouldSkipTextNode(node)) continue
        text += node.textContent ?? ''
    }
    return text
}

const findBlockAncestor = node => {
    let el = node.parentElement
    while (el && !blockTags.has(el.tagName?.toLowerCase?.())) {
        el = el.parentElement
    }
    return el ?? node.ownerDocument?.body ?? null
}

const isSentenceTerminator = (char, nextChar) => {
    if (char === '.') {
        if (!nextChar) return true
        if (quoteChars.has(nextChar)) return true
        if (/\s/.test(nextChar)) return true
        return false
    }
    return char === '!' || char === '?' || char === '。' || char === '！' || char === '？'
}

const advancePastQuotes = (text, index) => {
    let end = index
    while (end < text.length && quoteChars.has(text[end])) end++
    return end
}

function* getBlocks(doc) {
    const walker = doc.createTreeWalker(doc.body, NodeFilter.SHOW_TEXT)
    let startNode = null
    let startOffset = 0
    let currentBlock = null
    let lastNode = null
    let lastOffset = 0

    const flushRange = () => {
        if (!startNode || !lastNode) return null
        const range = doc.createRange()
        range.setStart(startNode, startOffset)
        range.setEnd(lastNode, lastOffset)
        startNode = null
        startOffset = 0
        currentBlock = null
        lastNode = null
        lastOffset = 0
        if (rangeIsEmpty(range)) return null
        return range
    }

    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
        if (!node.textContent) continue
        if (shouldSkipTextNode(node)) continue

        const block = findBlockAncestor(node)

        if (!startNode) {
            startNode = node
            startOffset = 0
            currentBlock = block
        } else if (block !== currentBlock) {
            const range = flushRange()
            if (range) yield range
            startNode = node
            startOffset = 0
            currentBlock = block
        }

        const text = node.textContent
        let index = 0
        while (index < text.length) {
            const char = text[index]
            const nextChar = text[index + 1]
            if (isSentenceTerminator(char, nextChar)) {
                const endOffset = advancePastQuotes(text, index + 1)
                const range = doc.createRange()
                range.setStart(startNode, startOffset)
                range.setEnd(node, endOffset)
                if (!rangeIsEmpty(range)) yield range
                startNode = node
                startOffset = endOffset
                lastNode = node
                lastOffset = endOffset
                index = endOffset
                continue
            }
            index += 1
        }

        lastNode = node
        lastOffset = text.length

        if (startNode === node && startOffset === text.length) {
            startNode = null
            startOffset = 0
            currentBlock = null
        }
    }

    const remaining = flushRange()
    if (remaining) yield remaining
}

class ListIterator {
    #arr = []
    #iter
    #index = -1
    #f
    constructor(iter, f = x => x) {
        this.#iter = iter
        this.#f = f
    }
    current() {
        if (this.#arr[this.#index]) return this.#f(this.#arr[this.#index])
    }
    first() {
        const newIndex = 0
        if (this.#arr[newIndex]) {
            this.#index = newIndex
            return this.#f(this.#arr[newIndex])
        }
    }
    last() {
        for (const value of this.#iter) this.#arr.push(value)
        const newIndex = this.#arr.length - 1
        if (this.#arr[newIndex]) {
            this.#index = newIndex
            return this.#f(this.#arr[newIndex])
        }
    }
    prev() {
        const newIndex = this.#index - 1
        if (this.#arr[newIndex]) {
            this.#index = newIndex
            return this.#f(this.#arr[newIndex])
        }
    }
    next() {
        const newIndex = this.#index + 1
        if (this.#arr[newIndex]) {
            this.#index = newIndex
            return this.#f(this.#arr[newIndex])
        }
        while (true) {
            const { done, value } = this.#iter.next()
            if (done) break
            this.#arr.push(value)
            if (this.#arr[newIndex]) {
                this.#index = newIndex
                return this.#f(this.#arr[newIndex])
            }
        }
    }
    prepare() {
        const newIndex = this.#index + 1
        if (this.#arr[newIndex]) return this.#f(this.#arr[newIndex])
        while (true) {
            const { done, value } = this.#iter.next()
            if (done) break
            this.#arr.push(value)
            if (this.#arr[newIndex]) return this.#f(this.#arr[newIndex])
        }
    }
    find(f) {
        const index = this.#arr.findIndex(x => f(x))
        if (index > -1) {
            this.#index = index
            return this.#f(this.#arr[index])
        }
        while (true) {
            const { done, value } = this.#iter.next()
            if (done) break
            this.#arr.push(value)
            if (f(value)) {
                this.#index = this.#arr.length - 1
                return this.#f(value)
            }
        }
    }
}

export class TTS {
    #list
    #lastMark
    constructor(doc, textWalker, highlight) {
        this.doc = doc
        this.highlight = highlight
        this.#list = new ListIterator(getBlocks(doc), range => {
            return [getRangeText(range), range]
        })
    }

    #getText(text, getNode) {
        if (!text) return ''
        if (!getNode) return text
        const tempElement = document.createElement('div')
        tempElement.innerHTML = text
        let node = getNode(tempElement)?.previousSibling
        while (node) {
            const next = node.previousSibling ?? node.parentNode?.previousSibling
            node.parentNode.removeChild(node)
            node = next
        }
        return tempElement.textContent
    }

    start() {
        this.#lastMark = null
        const [text, range] = this.#list.first() ?? []
        if (!text) return this.next()
        this.highlight(range.cloneRange())
        return this.#getText(text)
    }

    end() {
        this.#lastMark = null
        const [text, range] = this.#list.last() ?? []
        if (!text) return this.next()
        this.highlight(range.cloneRange())
        return this.#getText(text)
    }

    resume() {
        const [text] = this.#list.current() ?? []
        if (!text) return this.next()
        return this.#getText(text)
    }

    prev(paused) {
        this.#lastMark = null
        const [text, range] = this.#list.prev() ?? []
        if (paused && range) this.highlight(range.cloneRange())
        return this.#getText(text)
    }

    next(paused) {
        this.#lastMark = null
        const [text, range] = this.#list.next() ?? []
        if (paused && range) this.highlight(range.cloneRange())
        return this.#getText(text)
    }

    // get next text without moving the iterator
    prepare() {
        const [text] = this.#list.prepare() ?? []
        return this.#getText(text)
    }

    from(range) {
        this.#lastMark = null
        const [text, newRange] = this.#list.find(range_ =>
            range.compareBoundaryPoints(Range.END_TO_START, range_) <= 0)
        if (newRange) this.highlight(newRange.cloneRange())
        return this.#getText(text)
    }
}
