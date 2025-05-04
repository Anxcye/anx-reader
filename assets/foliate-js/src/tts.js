const NS = {
    XML: 'http://www.w3.org/XML/1998/namespace',
    SSML: 'http://www.w3.org/2001/10/synthesis',
}

const blockTags = new Set([
    'article', 'aside', 'audio', 'blockquote', 'caption',
    'details', 'dialog', 'div', 'dl', 'dt', 'dd',
    'figure', 'footer', 'form', 'figcaption',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'hgroup', 'hr', 'li',
    'main', 'math', 'nav', 'ol', 'p', 'pre', 'section', 'tr',
])

const getLang = el => {
    const x = el.lang || el?.getAttributeNS?.(NS.XML, 'lang')
    return x ? x : el.parentElement ? getLang(el.parentElement) : null
}

function rangeIsEmpty(range) {
    return range.collapsed || range.toString().trim() === ''
}

const sentenseEndRegex = (lang) => {
    switch (lang) {
        case 'zh':
            return 
        case 'en':
            return /[.!?]["']?/g
        default:
            return /[.!?]["']?/g
    }
}

function* getBlocks(doc) {
    const walker = doc.createTreeWalker(doc.body, NodeFilter.SHOW_TEXT)
    let lastRange = null

    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
        let match
        // it some times cannot get the lang of the parent element
        // const regex = sentenseEndRegex(getLang(node.parentElement))

        const regex = /[.!?。！？]["'“”‘’]?/g
        while ((match = regex.exec(node.textContent)) !== null) {
            const range = doc.createRange()
            if (lastRange) {
                lastRange.setEnd(node, match.index + match[0].length)
                if (!rangeIsEmpty(lastRange)) yield lastRange
            }
            lastRange = doc.createRange()
            lastRange.setStart(node, match.index + match[0].length)
        }

        if (lastRange) {
            lastRange.setEnd(node, node.textContent.length)
            if (!rangeIsEmpty(lastRange)) yield lastRange
        }
        lastRange = doc.createRange()
        lastRange.setStart(node, node.textContent.length)
    }
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
            return [range.toString(), range]
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