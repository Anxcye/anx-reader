import * as CFI from './epubcfi.js'

const NS = {
    CONTAINER: 'urn:oasis:names:tc:opendocument:xmlns:container',
    XHTML: 'http://www.w3.org/1999/xhtml',
    OPF: 'http://www.idpf.org/2007/opf',
    EPUB: 'http://www.idpf.org/2007/ops',
    DC: 'http://purl.org/dc/elements/1.1/',
    DCTERMS: 'http://purl.org/dc/terms/',
    ENC: 'http://www.w3.org/2001/04/xmlenc#',
    NCX: 'http://www.daisy.org/z3986/2005/ncx/',
    XLINK: 'http://www.w3.org/1999/xlink',
    SMIL: 'http://www.w3.org/ns/SMIL',
}

const MIME = {
    XML: 'application/xml',
    NCX: 'application/x-dtbncx+xml',
    XHTML: 'application/xhtml+xml',
    HTML: 'text/html',
    CSS: 'text/css',
    SVG: 'image/svg+xml',
    JS: /\/(x-)?(javascript|ecmascript)/,
}

// convert to camel case
const camel = x => x.toLowerCase().replace(/[-:](.)/g, (_, g) => g.toUpperCase())

// strip and collapse ASCII whitespace
// https://infra.spec.whatwg.org/#strip-and-collapse-ascii-whitespace
const normalizeWhitespace = str => str ? str
    .replace(/[\t\n\f\r ]+/g, ' ')
    .replace(/^[\t\n\f\r ]+/, '')
    .replace(/[\t\n\f\r ]+$/, '') : ''

const filterAttribute = (attr, value, isList) => isList
    ? el => el.getAttribute(attr)?.split(/\s/)?.includes(value)
    : typeof value === 'function'
        ? el => value(el.getAttribute(attr))
        : el => el.getAttribute(attr) === value

const getAttributes = (...xs) => el =>
    el ? Object.fromEntries(xs.map(x => [camel(x), el.getAttribute(x)])) : null

const getElementText = el => normalizeWhitespace(el?.textContent)

const childGetter = (doc, ns) => {
    // ignore the namespace if it doesn't appear in document at all
    const useNS = doc.lookupNamespaceURI(null) === ns || doc.lookupPrefix(ns)
    const f = useNS
        ? (el, name) => el => el.namespaceURI === ns && el.localName === name
        : (el, name) => el => el.localName === name
    return {
        $: (el, name) => [...el.children].find(f(el, name)),
        $$: (el, name) => [...el.children].filter(f(el, name)),
        $$$: useNS
            ? (el, name) => [...el.getElementsByTagNameNS(ns, name)]
            : (el, name) => [...el.getElementsByTagName(name)],
    }
}

const resolveURL = (url, relativeTo) => {
    try {
        if (relativeTo.includes(':')) return new URL(url, relativeTo)
        // the base needs to be a valid URL, so set a base URL and then remove it
        const root = 'https://invalid.invalid/'
        const obj = new URL(url, root + relativeTo)
        obj.search = ''
        return decodeURI(obj.href.replace(root, ''))
    } catch(e) {
        console.warn(e)
        return url
    }
}

const isExternal = uri => /^(?!blob)\w+:/i.test(uri)

// like `path.relative()` in Node.js
const pathRelative = (from, to) => {
    if (!from) return to
    const as = from.replace(/\/$/, '').split('/')
    const bs = to.replace(/\/$/, '').split('/')
    const i = (as.length > bs.length ? as : bs).findIndex((_, i) => as[i] !== bs[i])
    return i < 0 ? '' : Array(as.length - i).fill('..').concat(bs.slice(i)).join('/')
}

const pathDirname = str => str.slice(0, str.lastIndexOf('/') + 1)

// replace asynchronously and sequentially
// same techinque as https://stackoverflow.com/a/48032528
const replaceSeries = async (str, regex, f) => {
    const matches = []
    str.replace(regex, (...args) => (matches.push(args), null))
    const results = []
    for (const args of matches) results.push(await f(...args))
    return str.replace(regex, () => results.shift())
}

const regexEscape = str => str.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&')

const LANGS = { attrs: ['dir', 'xml:lang'] }
const ALTS = { name: 'alternate-script', many: true, ...LANGS, props: ['file-as'] }
const CONTRIB = {
    many: true, ...LANGS,
    props: [{ name: 'role', many: true, attrs: ['scheme'] }, 'file-as', ALTS],
    setLegacyAttrs: (obj, el) => {
        if (!obj.role?.length) {
            const value = el.getAttributeNS(NS.OPF, 'role')
            if (value) obj.role = [{ value }]
        }
        obj.fileAs ??= el.getAttributeNS(NS.OPF, 'file-as')
    },
}
const METADATA = [
    {
        name: 'title', many: true, ...LANGS,
        props: ['title-type', 'display-seq', 'file-as', ALTS],
    },
    {
        name: 'identifier', many: true,
        props: [{ name: 'identifier-type', attrs: ['scheme'] }],
        setLegacyAttrs: (obj, el) => {
            if (!obj.identifierType) {
                const value = el.getAttributeNS(NS.OPF, 'scheme')
                if (value) obj.identifierType = { value }
            }
        },
    },
    { name: 'language', many: true },
    { name: 'creator', ...CONTRIB },
    { name: 'contributor', ...CONTRIB },
    { name: 'publisher', ...LANGS, props: ['file-as', ALTS] },
    { name: 'description', ...LANGS, props: [ALTS] },
    { name: 'rights', ...LANGS, props: [ALTS] },
    { name: 'date' },
    { name: 'dcterms:modified', type: 'meta' },
    {
        name: 'subject', many: true, ...LANGS, props: ['term', 'authority', ALTS],
        setLegacyAttrs: (obj, el) => {
            obj.term ??= el.getAttributeNS(NS.OPF, 'term')
            obj.authority ??= el.getAttributeNS(NS.OPF, 'authority')
        },
    },
    { name: 'source', many: true },
    {
        name: 'belongs-to-collection', type: 'meta', many: true, ...LANGS,
        props: [
            'collection-type', 'group-position', 'dcterms:identifier', 'file-as',
            ALTS, { name: 'belongs-to-collection', recursive: true },
        ],
    },
]

const getMetadata = opf => {
    const { $, $$ } = childGetter(opf, NS.OPF)
    const $metadata = $(opf.documentElement, 'metadata')
    const els = Array.from($metadata.children)
    const getValue = (obj, el) => {
        if (!el) return null
        const { props = [], attrs = [] } = obj
        const value = getElementText(el)
        if (!props.length && !attrs.length) return value
        const id = el.getAttribute('id')
        const refines = id ? els.filter(filterAttribute('refines', '#' + id)) : []
        const result = Object.fromEntries([['value', value]]
            .concat(props.map(prop => {
                const { many, recursive } = prop
                const name = typeof prop === 'string' ? prop : prop.name
                const filter = filterAttribute('property', name)
                const subobj = recursive ? obj : prop
                return [camel(name), many
                    ? refines.filter(filter).map(el => getValue(subobj, el))
                    : getValue(subobj, refines.find(filter))]
            }))
            .concat(attrs.map(attr => [camel(attr), el.getAttribute(attr)])))
        obj.setLegacyAttrs?.(result, el)
        return result
    }
    const arr = els.filter(filterAttribute('refines', null))
    const metadata = Object.fromEntries(METADATA.map(obj => {
        const { type, name, many } = obj
        const filter = type === 'meta'
            ? el => el.namespaceURI === NS.OPF && el.getAttribute('property') === name
            : el => el.namespaceURI === NS.DC && el.localName === name
        return [camel(name), many ? arr.filter(filter).map(el => getValue(obj, el))
            : getValue(obj, arr.find(filter))]
    }))

    const $$meta = $$($metadata, 'meta')
    const getMetasByPrefix = prefix => $$meta
        .filter(filterAttribute('property', x => x?.startsWith(prefix)))
        .map(el => [el.getAttribute('property').replace(prefix, ''), el])

    const rendition = Object.fromEntries(getMetasByPrefix('rendition:')
        .map(([k, el]) => [k, getElementText(el)]))

    const media = { narrator: [], duration: {} }
    for (const [k, el] of getMetasByPrefix('media:')) {
        const v = getElementText(el)
        if (k === 'duration') media.duration[
            el.getAttribute('refines')?.split('#')?.[1] ?? ''] = parseClock(v)
        else if (k === 'active-class') media.activeClass = v
        else if (k === 'narrator') media.narrator.push(v)
        else if (k === 'playback-active-class') media.playbackActiveClass = v
    }
    return { metadata, rendition, media }
}

const parseNav = (doc, resolve = f => f) => {
    const { $, $$, $$$ } = childGetter(doc, NS.XHTML)
    const resolveHref = href => href ? decodeURI(resolve(href)) : null
    const parseLI = getType => $li => {
        const $a = $($li, 'a') ?? $($li, 'span')
        const $ol = $($li, 'ol')
        const href = resolveHref($a?.getAttribute('href'))
        const label = getElementText($a) || $a?.getAttribute('title')
        // TODO: get and concat alt/title texts in content
        const result = { label, href, subitems: parseOL($ol) }
        if (getType) result.type = $a?.getAttributeNS(NS.EPUB, 'type')?.split(/\s/)
        return result
    }
    const parseOL = ($ol, getType) => $ol ? $$($ol, 'li').map(parseLI(getType)) : null
    const parseNav = ($nav, getType) => parseOL($($nav, 'ol'), getType)

    const $$nav = $$$(doc, 'nav')
    let toc = null, pageList = null, landmarks = null, others = []
    for (const $nav of $$nav) {
        const type = $nav.getAttributeNS(NS.EPUB, 'type')?.split(/\s/) ?? []
        if (type.includes('toc')) toc ??= parseNav($nav)
        else if (type.includes('page-list')) pageList ??= parseNav($nav)
        else if (type.includes('landmarks')) landmarks ??= parseNav($nav, true)
        else others.push({
            label: getElementText($nav.firstElementChild), type,
            list: parseNav($nav),
        })
    }
    return { toc, pageList, landmarks, others }
}

const parseNCX = (doc, resolve = f => f) => {
    const { $, $$ } = childGetter(doc, NS.NCX)
    const resolveHref = href => href ? decodeURI(resolve(href)) : null
    const parseItem = el => {
        const $label = $(el, 'navLabel')
        const $content = $(el, 'content')
        const label = getElementText($label)
        const href = resolveHref($content.getAttribute('src'))
        if (el.localName === 'navPoint') {
            const els = $$(el, 'navPoint')
            return { label, href, subitems: els.length ? els.map(parseItem) : null }
        }
        return { label, href }
    }
    const parseList = (el, itemName) => $$(el, itemName).map(parseItem)
    const getSingle = (container, itemName) => {
        const $container = $(doc.documentElement, container)
        return $container ? parseList($container, itemName) : null
    }
    return {
        toc: getSingle('navMap', 'navPoint'),
        pageList: getSingle('pageList', 'pageTarget'),
        others: $$(doc.documentElement, 'navList').map(el => ({
            label: getElementText($(el, 'navLabel')),
            list: parseList(el, 'navTarget'),
        })),
    }
}

const parseClock = str => {
    if (!str) return
    const parts = str.split(':').map(x => parseFloat(x))
    if (parts.length === 3) {
        const [h, m, s] = parts
        return h * 60 * 60 + m * 60 + s
    }
    if (parts.length === 2) {
        const [m, s] = parts
        return m * 60 + s
    }
    const [x, unit] = str.split(/(?=[^\d.])/)
    const n = parseFloat(x)
    const f = unit === 'h' ? 60 * 60
        : unit === 'min' ? 60
        : unit === 'ms' ? .001
        : 1
    return n * f
}

class MediaOverlay extends EventTarget {
    #entries
    #lastMediaOverlayItem
    #sectionIndex
    #audioIndex
    #itemIndex
    #audio
    #volume = 1
    #rate = 1
    constructor(book, loadXML) {
        super()
        this.book = book
        this.loadXML = loadXML
    }
    async #loadSMIL(item) {
        if (this.#lastMediaOverlayItem === item) return
        const doc = await this.loadXML(item.href)
        const resolve = href => href ? resolveURL(href, item.href) : null
        const { $, $$$ } = childGetter(doc, NS.SMIL)
        this.#audioIndex = -1
        this.#itemIndex = -1
        this.#entries = $$$(doc, 'par').reduce((arr, $par) => {
            const text = resolve($($par, 'text')?.getAttribute('src'))
            const $audio = $($par, 'audio')
            if (!text || !$audio) return arr
            const src = resolve($audio.getAttribute('src'))
            const begin = parseClock($audio.getAttribute('clipBegin'))
            const end = parseClock($audio.getAttribute('clipEnd'))
            const last = arr.at(-1)
            if (last?.src === src) last.items.push({ text, begin, end })
            else arr.push({ src, items: [{ text, begin, end }] })
            return arr
        }, [])
        this.#lastMediaOverlayItem = item
    }
    get #activeAudio() {
        return this.#entries[this.#audioIndex]
    }
    get #activeItem() {
        return this.#activeAudio?.items?.[this.#itemIndex]
    }
    #error(e) {
        console.error(e)
        this.dispatchEvent(new CustomEvent('error', { detail: e }))
    }
    #highlight() {
        this.dispatchEvent(new CustomEvent('highlight', { detail: this.#activeItem }))
    }
    #unhighlight() {
        this.dispatchEvent(new CustomEvent('unhighlight', { detail: this.#activeItem }))
    }
    async #play(audioIndex, itemIndex) {
        if (this.#audio) {
            this.#audio.pause()
            URL.revokeObjectURL(this.#audio.src)
            this.#audio = null
        }
        this.#audioIndex = audioIndex
        this.#itemIndex = itemIndex
        const src = this.#activeAudio?.src
        if (!src || !this.#activeItem) return this.start(this.#sectionIndex + 1)

        const url = URL.createObjectURL(await this.book.loadBlob(src))
        const audio = new Audio(url)
        this.#audio = audio
        audio.addEventListener('timeupdate', () => {
            if (audio.paused) return
            const t = audio.currentTime
            const { items } = this.#activeAudio
            if (t > this.#activeItem?.end) {
                this.#unhighlight()
                if (this.#itemIndex === items.length - 1) {
                    this.#play(this.#audioIndex + 1, 0).catch(e => this.#error(e))
                    return
                }
            }
            const oldIndex = this.#itemIndex
            while (items[this.#itemIndex + 1]?.begin <= t) this.#itemIndex++
            if (this.#itemIndex !== oldIndex) this.#highlight()
        })
        audio.addEventListener('error', () =>
            this.#error(new Error(`Failed to load ${src}`)))
        audio.addEventListener('playing', () => this.#highlight())
        audio.addEventListener('pause', () => this.#unhighlight())
        audio.addEventListener('ended', () => {
            this.#unhighlight()
            URL.revokeObjectURL(url)
            this.#audio = null
            this.#play(audioIndex + 1, 0).catch(e => this.#error(e))
        })
        audio.addEventListener('canplaythrough', () => {
            audio.currentTime = this.#activeItem.begin ?? 0
            audio.volume = this.#volume
            audio.playbackRate = this.#rate
            audio.play().catch(e => this.#error(e))
        })
    }
    async start(sectionIndex, filter = () => true) {
        this.#audio?.pause()
        const section = this.book.sections[sectionIndex]
        const href = section?.id
        if (!href) return

        const { mediaOverlay } = section
        if (!mediaOverlay) return this.start(sectionIndex + 1)
        this.#sectionIndex = sectionIndex
        await this.#loadSMIL(mediaOverlay)

        for (let i = 0; i < this.#entries.length; i++) {
            const { items } = this.#entries[i]
            for (let j = 0; j < items.length; j++) {
                if (items[j].text.split('#')[0] === href && filter(items[j], j, items))
                    return this.#play(i, j).catch(e => this.#error(e))
            }
        }
    }
    pause() {
        this.#audio?.pause()
    }
    resume() {
        this.#audio?.play().catch(e => this.#error(e))
    }
    prev() {
        if (this.#itemIndex > 0) this.#play(this.#audioIndex, this.#itemIndex - 1)
        else if (this.#audioIndex > 0) this.#play(this.#audioIndex - 1,
            this.#entries[this.#audioIndex - 1].items.length - 1)
        else if (this.#sectionIndex > 0)
            this.start(this.#sectionIndex - 1, (_, i, items) => i === items.length - 1)
    }
    next() {
        this.#play(this.#audioIndex, this.#itemIndex + 1)
    }
    setVolume(volume) {
        this.#volume = volume
        if (this.#audio) this.#audio.volume = volume
    }
    setRate(rate) {
        this.#rate = rate
        if (this.#audio) this.#audio.playbackRate = rate
    }
}

const isUUID = /([0-9a-f]{8})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{12})/

const getUUID = opf => {
    for (const el of opf.getElementsByTagNameNS(NS.DC, 'identifier')) {
        const [id] = getElementText(el).split(':').slice(-1)
        if (isUUID.test(id)) return id
    }
    return ''
}

const getIdentifier = opf => getElementText(
    opf.getElementById(opf.documentElement.getAttribute('unique-identifier'))
    ?? opf.getElementsByTagNameNS(NS.DC, 'identifier')[0])

// https://www.w3.org/publishing/epub32/epub-ocf.html#sec-resource-obfuscation
const deobfuscate = async (key, length, blob) => {
    const array = new Uint8Array(await blob.slice(0, length).arrayBuffer())
    length = Math.min(length, array.length)
    for (var i = 0; i < length; i++) array[i] = array[i] ^ key[i % key.length]
    return new Blob([array, blob.slice(length)], { type: blob.type })
}

const WebCryptoSHA1 = async str => {
    const data = new TextEncoder().encode(str)
    const buffer = await globalThis.crypto.subtle.digest('SHA-1', data)
    return new Uint8Array(buffer)
}

const deobfuscators = (sha1 = WebCryptoSHA1) => ({
    'http://www.idpf.org/2008/embedding': {
        key: opf => sha1(getIdentifier(opf)
            // eslint-disable-next-line no-control-regex
            .replaceAll(/[\u0020\u0009\u000d\u000a]/g, '')),
        decode: (key, blob) => deobfuscate(key, 1040, blob),
    },
    'http://ns.adobe.com/pdf/enc#RC': {
        key: opf => {
            const uuid = getUUID(opf).replaceAll('-', '')
            return Uint8Array.from({ length: 16 }, (_, i) =>
                parseInt(uuid.slice(i * 2, i * 2 + 2), 16))
        },
        decode: (key, blob) => deobfuscate(key, 1024, blob),
    },
})

class Encryption {
    #uris = new Map()
    #decoders = new Map()
    #algorithms
    constructor(algorithms) {
        this.#algorithms = algorithms
    }
    async init(encryption, opf) {
        if (!encryption) return
        const data = Array.from(
            encryption.getElementsByTagNameNS(NS.ENC, 'EncryptedData'), el => ({
                algorithm: el.getElementsByTagNameNS(NS.ENC, 'EncryptionMethod')[0]
                    ?.getAttribute('Algorithm'),
                uri: el.getElementsByTagNameNS(NS.ENC, 'CipherReference')[0]
                    ?.getAttribute('URI'),
            }))
        for (const { algorithm, uri } of data) {
            if (!this.#decoders.has(algorithm)) {
                const algo = this.#algorithms[algorithm]
                if (!algo) {
                    console.warn('Unknown encryption algorithm')
                    continue
                }
                const key = await algo.key(opf)
                this.#decoders.set(algorithm, blob => algo.decode(key, blob))
            }
            this.#uris.set(uri, algorithm)
        }
    }
    getDecoder(uri) {
        return this.#decoders.get(this.#uris.get(uri)) ?? (x => x)
    }
}

class Resources {
    constructor({ opf, resolveHref }) {
        this.opf = opf
        const { $, $$, $$$ } = childGetter(opf, NS.OPF)

        const $manifest = $(opf.documentElement, 'manifest')
        const $spine = $(opf.documentElement, 'spine')
        const $$itemref = $$($spine, 'itemref')

        this.manifest = $$($manifest, 'item')
            .map(getAttributes('href', 'id', 'media-type', 'properties', 'media-overlay'))
            .map(item => {
                item.href = resolveHref(item.href)
                item.properties = item.properties?.split(/\s/)
                return item
            })
        this.spine = $$itemref
            .map(getAttributes('idref', 'id', 'linear', 'properties'))
            .map(item => (item.properties = item.properties?.split(/\s/), item))
        this.pageProgressionDirection = $spine
            .getAttribute('page-progression-direction')

        this.navPath = this.getItemByProperty('nav')?.href
        this.ncxPath = (this.getItemByID($spine.getAttribute('toc'))
            ?? this.manifest.find(item => item.mediaType === MIME.NCX))?.href

        const $guide = $(opf.documentElement, 'guide')
        if ($guide) this.guide = $$($guide, 'reference')
            .map(getAttributes('type', 'title', 'href'))
            .map(({ type, title, href }) => ({
                label: title,
                type: type.split(/\s/),
                href: resolveHref(href),
            }))

        this.cover = this.getItemByProperty('cover-image')
            // EPUB 2 compat
            ?? this.getItemByID($$$(opf, 'meta')
                .find(filterAttribute('name', 'cover'))
                ?.getAttribute('content'))
            ?? this.getItemByHref(this.guide
                ?.find(ref => ref.type.includes('cover'))?.href)

        this.cfis = CFI.fromElements($$itemref)
    }
    getItemByID(id) {
        return this.manifest.find(item => item.id === id)
    }
    getItemByHref(href) {
        return this.manifest.find(item => item.href === href)
    }
    getItemByProperty(prop) {
        return this.manifest.find(item => item.properties?.includes(prop))
    }
    resolveCFI(cfi) {
        const parts = CFI.parse(cfi)
        const top = (parts.parent ?? parts).shift()
        let $itemref = CFI.toElement(this.opf, top)
        // make sure it's an idref; if not, try again without the ID assertion
        // mainly because Epub.js used to generate wrong ID assertions
        // https://github.com/futurepress/epub.js/issues/1236
        if ($itemref && $itemref.nodeName !== 'idref') {
            top.at(-1).id = null
            $itemref = CFI.toElement(this.opf, top)
        }
        const idref = $itemref?.getAttribute('idref')
        const index = this.spine.findIndex(item => item.idref === idref)
        const anchor = doc => CFI.toRange(doc, parts)
        return { index, anchor }
    }
}

class Loader {
    #cache = new Map()
    #children = new Map()
    #refCount = new Map()
    allowScript = false
    constructor({ loadText, loadBlob, resources }) {
        this.loadText = loadText
        this.loadBlob = loadBlob
        this.manifest = resources.manifest
        this.assets = resources.manifest
        // needed only when replacing in (X)HTML w/o parsing (see below)
        //.filter(({ mediaType }) => ![MIME.XHTML, MIME.HTML].includes(mediaType))
    }
    createURL(href, data, type, parent) {
        if (!data) return ''
        const url = URL.createObjectURL(new Blob([data], { type }))
        this.#cache.set(href, url)
        this.#refCount.set(href, 1)
        if (parent) {
            const childList = this.#children.get(parent)
            if (childList) childList.push(href)
            else this.#children.set(parent, [href])
        }
        return url
    }
    ref(href, parent) {
        const childList = this.#children.get(parent)
        if (!childList?.includes(href)) {
            this.#refCount.set(href, this.#refCount.get(href) + 1)
            //console.log(`referencing ${href}, now ${this.#refCount.get(href)}`)
            if (childList) childList.push(href)
            else this.#children.set(parent, [href])
        }
        return this.#cache.get(href)
    }
    unref(href) {
        if (!this.#refCount.has(href)) return
        const count = this.#refCount.get(href) - 1
        //console.log(`unreferencing ${href}, now ${count}`)
        if (count < 1) {
            //console.log(`unloading ${href}`)
            URL.revokeObjectURL(this.#cache.get(href))
            this.#cache.delete(href)
            this.#refCount.delete(href)
            // unref children
            const childList = this.#children.get(href)
            if (childList) while (childList.length) this.unref(childList.pop())
            this.#children.delete(href)
        } else this.#refCount.set(href, count)
    }
    // load manifest item, recursively loading all resources as needed
    async loadItem(item, parents = []) {
        if (!item) return null
        const { href, mediaType } = item

        const isScript = MIME.JS.test(item.mediaType)
        if (isScript && !this.allowScript) return null

        const parent = parents.at(-1)
        if (this.#cache.has(href)) return this.ref(href, parent)

        const shouldReplace =
            (isScript || [MIME.XHTML, MIME.HTML, MIME.CSS, MIME.SVG].includes(mediaType))
            // prevent circular references
            && parents.every(p => p !== href)
        if (shouldReplace) return this.loadReplaced(item, parents)
        return this.createURL(href, await this.loadBlob(href), mediaType, parent)
    }
    async loadHref(href, base, parents = []) {
        if (isExternal(href)) return href
        const path = resolveURL(href, base)
        const item = this.manifest.find(item => item.href === path)
        if (!item) return href
        return this.loadItem(item, parents.concat(base))
    }
    async loadReplaced(item, parents = []) {
        const { href, mediaType } = item
        const parent = parents.at(-1)
        const str = await this.loadText(href)
        if (!str) return null

        // note that one can also just use `replaceString` for everything:
        // ```
        // const replaced = await this.replaceString(str, href, parents)
        // return this.createURL(href, replaced, mediaType, parent)
        // ```
        // which is basically what Epub.js does, which is simpler, but will
        // break things like iframes (because you don't want to replace links)
        // or text that just happen to be paths

        // parse and replace in HTML
        if ([MIME.XHTML, MIME.HTML, MIME.SVG].includes(mediaType)) {
            let doc = new DOMParser().parseFromString(str, mediaType)
            // change to HTML if it's not valid XHTML
            if (mediaType === MIME.XHTML && (doc.querySelector('parsererror')
            || !doc.documentElement?.namespaceURI)) {
                console.warn(doc.querySelector('parsererror')?.innerText ?? 'Invalid XHTML')
                item.mediaType = MIME.HTML
                doc = new DOMParser().parseFromString(str, item.mediaType)
            }
            // replace hrefs in XML processing instructions
            // this is mainly for SVGs that use xml-stylesheet
            if ([MIME.XHTML, MIME.SVG].includes(item.mediaType)) {
                let child = doc.firstChild
                while (child instanceof ProcessingInstruction) {
                    if (child.data) {
                        const replacedData = await replaceSeries(child.data,
                            /(?:^|\s*)(href\s*=\s*['"])([^'"]*)(['"])/i,
                            (_, p1, p2, p3) => this.loadHref(p2, href, parents)
                                .then(p2 => `${p1}${p2}${p3}`))
                        child.replaceWith(doc.createProcessingInstruction(
                            child.target, replacedData))
                    }
                    child = child.nextSibling
                }
            }
            // replace hrefs (excluding anchors)
            // TODO: srcset?
            const replace = async (el, attr) => el.setAttribute(attr,
                await this.loadHref(el.getAttribute(attr), href, parents))
            for (const el of doc.querySelectorAll('link[href]')) await replace(el, 'href')
            for (const el of doc.querySelectorAll('[src]')) await replace(el, 'src')
            for (const el of doc.querySelectorAll('[poster]')) await replace(el, 'poster')
            for (const el of doc.querySelectorAll('object[data]')) await replace(el, 'data')
            for (const el of doc.querySelectorAll('[*|href]:not([href])'))
                el.setAttributeNS(NS.XLINK, 'href', await this.loadHref(
                    el.getAttributeNS(NS.XLINK, 'href'), href, parents))
            // replace inline styles
            for (const el of doc.querySelectorAll('style'))
                if (el.textContent) el.textContent =
                    await this.replaceCSS(el.textContent, href, parents)
            for (const el of doc.querySelectorAll('[style]'))
                el.setAttribute('style',
                    await this.replaceCSS(el.getAttribute('style'), href, parents))
            // TODO: replace inline scripts? probably not worth the trouble
            const result = new XMLSerializer().serializeToString(doc)
            return this.createURL(href, result, item.mediaType, parent)
        }

        const result = mediaType === MIME.CSS
            ? await this.replaceCSS(str, href, parents)
            : await this.replaceString(str, href, parents)
        return this.createURL(href, result, mediaType, parent)
    }
    async replaceCSS(str, href, parents = []) {
        const replacedUrls = await replaceSeries(str,
            /url\(\s*["']?([^'"\n]*?)\s*["']?\s*\)/gi,
            (_, url) => this.loadHref(url, href, parents)
                .then(url => `url("${url}")`))
        // apart from `url()`, strings can be used for `@import` (but why?!)
        const replacedImports = await replaceSeries(replacedUrls,
            /@import\s*["']([^"'\n]*?)["']/gi,
            (_, url) => this.loadHref(url, href, parents)
                .then(url => `@import "${url}"`))
        const w = window?.innerWidth ?? 800
        const h = window?.innerHeight ?? 600
        return replacedImports
            // unprefix as most of the props are (only) supported unprefixed
            .replace(/(?<=[{\s;])-epub-/gi, '')
            // replace vw and vh as they cause problems with layout
            .replace(/(\d*\.?\d+)vw/gi, (_, d) => parseFloat(d) * w / 100 + 'px')
            .replace(/(\d*\.?\d+)vh/gi, (_, d) => parseFloat(d) * h / 100 + 'px')
            // `page-break-*` unsupported in columns; replace with `column-break-*`
            .replace(/page-break-(after|before|inside)\s*:/gi, (_, x) =>
                `-webkit-column-break-${x}:`)
            .replace(/break-(after|before|inside)\s*:\s*(avoid-)?page/gi, (_, x, y) =>
                `break-${x}: ${y ?? ''}column`)
    }
    // find & replace all possible relative paths for all assets without parsing
    replaceString(str, href, parents = []) {
        const assetMap = new Map()
        const urls = this.assets.map(asset => {
            // do not replace references to the file itself
            if (asset.href === href) return
            // href was decoded and resolved when parsing the manifest
            const relative = pathRelative(pathDirname(href), asset.href)
            const relativeEnc = encodeURI(relative)
            const rootRelative = '/' + asset.href
            const rootRelativeEnc = encodeURI(rootRelative)
            const set = new Set([relative, relativeEnc, rootRelative, rootRelativeEnc])
            for (const url of set) assetMap.set(url, asset)
            return Array.from(set)
        }).flat().filter(x => x)
        if (!urls.length) return str
        const regex = new RegExp(urls.map(regexEscape).join('|'), 'g')
        return replaceSeries(str, regex, async match =>
            this.loadItem(assetMap.get(match.replace(/^\//, '')),
                parents.concat(href)))
    }
    unloadItem(item) {
        this.unref(item?.href)
    }
    destroy() {
        for (const url of this.#cache.values()) URL.revokeObjectURL(url)
    }
}

const getHTMLFragment = (doc, id) => doc.getElementById(id)
    ?? doc.querySelector(`[name="${CSS.escape(id)}"]`)

const getPageSpread = properties => {
    for (const p of properties) {
        if (p === 'page-spread-left' || p === 'rendition:page-spread-left')
            return 'left'
        if (p === 'page-spread-right' || p === 'rendition:page-spread-right')
            return 'right'
        if (p === 'rendition:page-spread-center') return 'center'
    }
}

const getDisplayOptions = doc => {
    if (!doc) return null
    return {
        fixedLayout: getElementText(doc.querySelector('option[name="fixed-layout"]')),
        openToSpread: getElementText(doc.querySelector('option[name="open-to-spread"]')),
    }
}

export class EPUB {
    parser = new DOMParser()
    #loader
    #encryption
    constructor({ loadText, loadBlob, getSize, sha1 }) {
        this.loadText = loadText
        this.loadBlob = loadBlob
        this.getSize = getSize
        this.#encryption = new Encryption(deobfuscators(sha1))
    }
    async #loadXML(uri) {
        const str = await this.loadText(uri)
        if (!str) return null
        const doc = this.parser.parseFromString(str, MIME.XML)
        if (doc.querySelector('parsererror'))
            throw new Error(`XML parsing error: ${uri}
${doc.querySelector('parsererror').innerText}`)
        return doc
    }
    async init() {
        const $container = await this.#loadXML('META-INF/container.xml')
        if (!$container) throw new Error('Failed to load container file')

        const opfs = Array.from(
            $container.getElementsByTagNameNS(NS.CONTAINER, 'rootfile'),
            getAttributes('full-path', 'media-type'))
            .filter(file => file.mediaType === 'application/oebps-package+xml')

        if (!opfs.length) throw new Error('No package document defined in container')
        const opfPath = opfs[0].fullPath
        const opf = await this.#loadXML(opfPath)
        if (!opf) throw new Error('Failed to load package document')

        const $encryption = await this.#loadXML('META-INF/encryption.xml')
        await this.#encryption.init($encryption, opf)

        this.resources = new Resources({
            opf,
            resolveHref: url => resolveURL(url, opfPath),
        })
        this.#loader = new Loader({
            loadText: this.loadText,
            loadBlob: uri => Promise.resolve(this.loadBlob(uri))
                .then(this.#encryption.getDecoder(uri)),
            resources: this.resources,
        })
        this.sections = this.resources.spine.map((spineItem, index) => {
            const { idref, linear, properties = [] } = spineItem
            const item = this.resources.getItemByID(idref)
            if (!item) {
                console.warn(`Could not find item with ID "${idref}" in manifest`)
                return null
            }
            return {
                id: item.href,
                load: () => this.#loader.loadItem(item),
                unload: () => this.#loader.unloadItem(item),
                createDocument: () => this.loadDocument(item),
                size: this.getSize(item.href),
                cfi: this.resources.cfis[index],
                linear,
                pageSpread: getPageSpread(properties),
                resolveHref: href => resolveURL(href, item.href),
                mediaOverlay: item.mediaOverlay
                    ? this.resources.getItemByID(item.mediaOverlay) : null,
            }
        }).filter(s => s)

        const { navPath, ncxPath } = this.resources
        if (navPath) try {
            const resolve = url => resolveURL(url, navPath)
            const nav = parseNav(await this.#loadXML(navPath), resolve)
            this.toc = nav.toc
            this.pageList = nav.pageList
            this.landmarks = nav.landmarks
        } catch(e) {
            console.warn(e)
        }
        if (!this.toc && ncxPath) try {
            const resolve = url => resolveURL(url, ncxPath)
            const ncx = parseNCX(await this.#loadXML(ncxPath), resolve)
            this.toc = ncx.toc
            this.pageList = ncx.pageList
        } catch(e) {
            console.warn(e)
        }
        this.landmarks ??= this.resources.guide

        const { metadata, rendition, media } = getMetadata(opf)
        this.rendition = rendition
        this.media = media
        this.dir = this.resources.pageProgressionDirection
        const displayOptions = getDisplayOptions(
            await this.#loadXML('META-INF/com.apple.ibooks.display-options.xml')
            ?? await this.#loadXML('META-INF/com.kobobooks.display-options.xml'))
        if (displayOptions) {
            if (displayOptions.fixedLayout === 'true')
                this.rendition.layout ??= 'pre-paginated'
            if (displayOptions.openToSpread === 'false') this.sections
                .find(section => section.linear !== 'no').pageSpread ??=
                    this.dir === 'rtl' ? 'left' : 'right'
        }

        this.parsedMetadata = metadata // for debugging or advanced use cases
        const title = metadata?.title?.[0]
        this.metadata = {
            title: title?.value,
            subtitle: metadata?.title?.find(x => x.titleType === 'subtitle')?.value,
            sortAs: title?.fileAs,
            language: metadata?.language,
            identifier: getIdentifier(opf),
            description: metadata?.description?.value,
            publisher: metadata?.publisher?.value,
            published: metadata?.date,
            modified: metadata?.dctermsModified,
            subject: metadata?.subject
                ?.filter(({ value, term }) => value || term)
                ?.map(({ value, term, authority }) =>
                    ({ name: value, code: term, scheme: authority })),
            rights: metadata?.rights?.value,
        }
        const relators = {
            art: 'artist',
            aut: 'author',
            bkp: 'producer',
            clr: 'colorist',
            edt: 'editor',
            ill: 'illustrator',
            nrt: 'narrator',
            trl: 'translator',
            pbl: 'publisher',
        }
        const mapContributor = defaultKey => obj => {
            const keys = [...new Set(obj.role?.map(({ value, scheme }) =>
                (!scheme || scheme === 'marc:relators' ? relators[value] : null)
                ?? defaultKey))]
            const value = { name: obj.value, sortAs: obj.fileAs }
            return [keys?.length ? keys : [defaultKey], value]
        }
        metadata?.creator?.map(mapContributor('author'))
            ?.concat(metadata?.contributor?.map?.(mapContributor('contributor')))
            ?.forEach(([keys, value]) => keys.forEach(key => {
                if (this.metadata[key]) this.metadata[key].push(value)
                else this.metadata[key] = [value]
            }))

        return this
    }
    async loadDocument(item) {
        const str = await this.loadText(item.href)
        return this.parser.parseFromString(str, item.mediaType)
    }
    getMediaOverlay() {
        return new MediaOverlay(this, this.#loadXML.bind(this))
    }
    resolveCFI(cfi) {
        return this.resources.resolveCFI(cfi)
    }
    resolveHref(href) {
        const [path, hash] = href.split('#')
        const item = this.resources.getItemByHref(decodeURI(path))
        if (!item) return null
        const index = this.resources.spine.findIndex(({ idref }) => idref === item.id)
        const anchor = hash ? doc => getHTMLFragment(doc, hash) : () => 0
        return { index, anchor }
    }
    splitTOCHref(href) {
        return href?.split('#') ?? []
    }
    getTOCFragment(doc, id) {
        return doc.getElementById(id)
            ?? doc.querySelector(`[name="${CSS.escape(id)}"]`)
    }
    isExternal(uri) {
        return isExternal(uri)
    }
    async getCover() {
        const cover = this.resources?.cover
        return cover?.href
            ? new Blob([await this.loadBlob(cover.href)], { type: cover.mediaType })
            : null
    }
    async getCalibreBookmarks() {
        const txt = await this.loadText('META-INF/calibre_bookmarks.txt')
        const magic = 'encoding=json+base64:'
        if (txt?.startsWith(magic)) {
            const json = atob(txt.slice(magic.length))
            return JSON.parse(json)
        }
    }
    destroy() {
        this.#loader?.destroy()
    }
}
