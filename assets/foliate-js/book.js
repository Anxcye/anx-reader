import './view.js'
import { FootnoteHandler } from './footnotes.js'
import { Overlayer } from './overlayer.js'
const { configure, ZipReader, BlobReader, TextWriter, BlobWriter } =
    await import('./vendor/zip.js')
const { EPUB } = await import('./epub.js')

// https://github.com/johnfactotum/foliate
const debounce = (f, wait, immediate) => {
    let timeout
    return (...args) => {
        const later = () => {
            timeout = null
            if (!immediate) f(...args)
        }
        const callNow = immediate && !timeout
        if (timeout) clearTimeout(timeout)
        timeout = setTimeout(later, wait)
        if (callNow) f(...args)
    }
}

const pointIsInView = ({ x, y }) =>
    x > 0 && y > 0 && x < window.innerWidth && y < window.innerHeight;

const frameRect = (frame, rect, sx = 1, sy = 1) => {
    const left = sx * rect.left + frame.left;
    const right = sx * rect.right + frame.left;
    const top = sy * rect.top + frame.top;
    const bottom = sy * rect.bottom + frame.top;
    return { left, right, top, bottom };
};

const getLang = el => {
    const lang = el.lang || el?.getAttributeNS?.('http://www.w3.org/XML/1998/namespace', 'lang');
    if (lang) return lang;
    if (el.parentElement) return getLang(el.parentElement);
};

const getPosition = target => {
    const frameElement = (target.getRootNode?.() ?? target?.endContainer?.getRootNode?.())
        ?.defaultView?.frameElement;

    const transform = frameElement ? getComputedStyle(frameElement).transform : '';
    const match = transform.match(/matrix\((.+)\)/);
    const [sx, , , sy] = match?.[1]?.split(/\s*,\s*/)?.map(x => parseFloat(x)) ?? [];

    const frame = frameElement?.getBoundingClientRect() ?? { top: 0, left: 0 };
    const rects = Array.from(target.getClientRects());
    const first = frameRect(frame, rects[0], sx, sy);
    const last = frameRect(frame, rects.at(-1), sx, sy);
    const screenWidth = window.innerWidth;
    const screenHeight = window.innerHeight;
    const start = {
        point: { x: ((first.left + first.right) / 2) / screenWidth, y: first.top / screenHeight },
        dir: 'up',
    };
    const end = {
        point: { x: ((last.left + last.right) / 2) / screenWidth, y: last.bottom / screenHeight },
        dir: 'down',
    };
    const startInView = pointIsInView(start.point);
    const endInView = pointIsInView(end.point);
    if (!startInView && !endInView) return { point: { x: 0, y: 0 } };
    if (!startInView) return end;
    if (!endInView) return start;
    return start.point.y * screenHeight > window.innerHeight - end.point.y * screenHeight ? start : end;
};

const getSelectionRange = sel => {
    if (!sel.rangeCount) return;
    const range = sel.getRangeAt(0);
    if (range.collapsed) return;
    return range;
};

//    let isSelecting = false;

const handleSelection = (view, doc, index) => {
    //    isSelecting = false;
    const sel = doc.getSelection();
    const range = getSelectionRange(sel);
    if (!range) return;
    const pos = getPosition(range);
    const cfi = view.getCFI(index, range);
    const lang = getLang(range.commonAncestorContainer);
    const text = sel.toString();
    if (!text) {
        const newSel = range.startContainer.ownerDocument.getSelection()
        newSel.removeAllRanges()
        newSel.addRange(range)
        text = newSel.toString()
    }
    onSelectionEnd({ index, range, lang, cfi, pos, text });
}

const setSelectionHandler = (view, doc, index) => {
    //    doc.addEventListener('pointerdown', () => isSelecting = true);
    //    doc.addEventListener('pointerup', () => handleSelection(view, doc, index));

    if (!view.isFixedLayout)
        // go to the next page when selecting to the end of a page
        // this makes it possible to select across pages
        doc.addEventListener('selectionchange', debounce(() => {
            //            if (!isSelecting) return
            if (view.renderer.getAttribute('flow') !== 'paginated') return
            const { lastLocation } = view
            if (!lastLocation) return
            const selRange = getSelectionRange(doc.getSelection())
            if (!selRange) return
            if (selRange.compareBoundaryPoints(Range.END_TO_END, lastLocation.range) >= 0) {
                view.next()
            }
        }, 1000))

};

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
    letterSpacing,
    spacing,
    paragraphSpacing,
    fontColor,
    backgroundColor,
    justify,
    hyphenate }) => `
    @namespace epub "http://www.idpf.org/2007/ops";
    html {
        color: ${fontColor} !important;
        background: none !important;
        background-color: ${backgroundColor} !important;
        font-size: ${fontSize}em;
        letter-spacing: ${letterSpacing}px;
    }
    /* https://github.com/whatwg/html/issues/5426 */
    @media (prefers-color-scheme: dark) {
        a:link {
            color: lightblue !important;
        }
    }
    p, li, blockquote, dd, div{
        line-height: ${spacing};
        padding-bottom: ${paragraphSpacing}em;
        text-align: ${justify ? 'justify' : 'start'};
        -webkit-hyphens: ${hyphenate ? 'auto' : 'manual'};
        hyphens: ${hyphenate ? 'auto' : 'manual'};
        -webkit-hyphenate-limit-before: 3;
        -webkit-hyphenate-limit-after: 2;
        -webkit-hyphenate-limit-lines: 2;
        hanging-punctuation: allow-end last;
        widows: 2;
    }
    /* prevent the above from overriding the align attribute */
    [align="left"] { text-align: left; }
    [align="right"] { text-align: right; }
    [align="center"] { text-align: center; }
    [align="justify"] { text-align: justify; }

    pre {
        white-space: pre-wrap !important;
    }
    aside[epub|type~="endnote"],
    aside[epub|type~="footnote"],
    aside[epub|type~="note"],
    aside[epub|type~="rearnote"] {
        display: none;
    }
`

const footnoteDialog = document.getElementById('footnote-dialog')
footnoteDialog.addEventListener('close', () => {
    // emit({ type: 'dialog-close' })
    const view = footnoteDialog.querySelector('foliate-view')
    view.close()
    view.remove()
})
footnoteDialog.addEventListener('click', e =>
    e.target === footnoteDialog ? footnoteDialog.close() : null)

class Reader {
    annotations = new Map()
    annotationsByValue = new Map()
    #footnoteHandler = new FootnoteHandler()
    #doc
    #index
    constructor() {
        this.#footnoteHandler.addEventListener('before-render', e => {
            const { view } = e.detail

            view.addEventListener('link', e => {
                e.preventDefault()
                const { href } = e.detail
                this.view.goTo(href)
            })
            view.addEventListener('external-link', e => {
                e.preventDefault()
                // emit({ type: 'external-link', ...e.detail })
            })

            footnoteDialog.querySelector('main').replaceChildren(view)

            const { renderer } = view
            renderer.setAttribute('flow', 'scrolled')
            renderer.setAttribute('gap', '5%')
            const footNoteStyle = {
                fontSize: style.fontSize * 0.8,
                spacing: style.spacing,
                fontColor: style.fontColor,
                backgroundColor: 'transparent',
                justify: true,
                hyphenate: true,
            }
            renderer.setStyles(getCSS(footNoteStyle))
            // set background color of dialog
            // if #rrggbbaa, replace aa to dd
            footnoteDialog.style.backgroundColor = style.backgroundColor.slice(0, 7) + 'ee'

            footnoteDialog.style.overflow = 'hidden'

        })
        this.#footnoteHandler.addEventListener('render', e => {
            console.log(e.detail)
            // const { href, hidden, type } = e.detail
            const { view } = e.detail
            console.log(view)


            footnoteDialog.showModal()
        })
    }
    async open(file, cfi) {
        this.view = await getView(file)

        this.view.addEventListener('load', this.#onLoad.bind(this))
        this.view.addEventListener('relocate', this.#onRelocate.bind(this))
        this.view.addEventListener('click-view', this.#onClickView.bind(this))

        setStyle()
        if (!cfi)
            this.view.renderer.next()

        const bookmarks = allAnnotations ?? []
        for (const bookmark of bookmarks) {
            const { value, type, color, note } = bookmark
            const annotation = {
                id: bookmark.id,
                value,
                type,
                color,
                note
            }
            const spineCode = (value.split('/')[2].split('!')[0] - 2) / 2

            const list = this.annotations.get(spineCode)
            if (list) list.push(annotation)
            else this.annotations.set(spineCode, [annotation])

            this.annotationsByValue.set(value, annotation)
        }


        this.view.addEventListener('create-overlay', e => {
            const { index } = e.detail
            const list = this.annotations.get(index)
            if (list) for (const annotation of list)
                this.view.addAnnotation(annotation)
        })

        this.view.addEventListener('draw-annotation', e => {
            const { draw, annotation } = e.detail
            const { color, type } = annotation
            if (type === 'highlight') draw(Overlayer.highlight, { color })
            else if (type === 'underline') draw(Overlayer.underline, { color })
        })

        this.view.addEventListener('show-annotation', e => {
            const annotation = this.annotationsByValue.get(e.detail.value)
            const pos = getPosition(e.detail.range)
            onAnnotationClick({ annotation, pos})
        })
        this.view.addEventListener('external-link', e => {
            e.preventDefault()
            onExternalLink(e.detail)
        })

        this.view.addEventListener('link', e =>
            this.#footnoteHandler.handle(this.view.book, e)?.catch(err => {
                console.warn(err)
                this.view.goTo(e.detail.href)
            }))

        await this.view.init({ lastLocation: cfi })
    }

    showContextMenu() {
        handleSelection(this.view, this.#doc, this.#index)
    }

    addAnnotation(annotation) {
        const { value } = annotation
        const spineCode = (value.split('/')[2].split('!')[0] - 2) / 2

        const list = this.annotations.get(spineCode)
        if (list) list.push(annotation)
        else this.annotations.set(spineCode, [annotation])

        this.annotationsByValue.set(value, annotation)

        this.view.addAnnotation(annotation)
    }

    removeAnnotation(cfi) {
        const annotation = this.annotationsByValue.get(cfi)
        const { value } = annotation
        const spineCode = (value.split('/')[2].split('!')[0] - 2) / 2

        const list = this.annotations.get(spineCode)
        if (list) {
            const index = list.findIndex(a => a.id === annotation.id)
            if (index !== -1) list.splice(index, 1)
        }

        this.annotationsByValue.delete(value)

        this.view.addAnnotation(annotation, true)
    }

    #onLoad({ detail: { doc, index } }) {
        this.#doc = doc
        this.#index = index
        setSelectionHandler(this.view, doc, index)
    }

    #onRelocate({ detail }) {
        const { cfi, fraction, location, tocItem, pageItem, chapterLocation } = detail
        const loc = pageItem
            ? `Page ${pageItem.label}`
            : `Loc ${location.current}`
        onRelocated({ cfi, fraction, loc, tocItem, pageItem, location, chapterLocation })
    }

    #onClickView({ detail: { x, y } }) {
        const coordinatesX = x / window.innerWidth
        const coordinatesY = y / window.innerHeight
        onClickView(coordinatesX, coordinatesY)
    }
}

const open = async (file, cfi) => {
    const reader = new Reader()
    globalThis.reader = reader
    await reader.open(file, cfi)
    onSetToc()
}

// //////// use for test //////////
// const allAnnotations = [
//     { id: 1, type: 'highlight', value: "epubcfi(/6/4!/4/4,/1:4,/1:9)", color: 'blue', note: 'this is' },
//     { id: 2, type: 'highlight', value: "epubcfi(/6/4!/4/4,/1:222,/1:226)", color: 'yellow', note: 'this is' },
//     { id: 3, type: 'underline', value: "epubcfi(/6/4!/4/4,/1:294,/1:301)", color: 'red', note: 'this is' },
// ]
// let url = '../local/shiji.epub'
// let cfi = ''
// let style = {
//     fontSize: 1.2,
//     letterSpacing: 0,
//     spacing: '1.5',
//     paragraphSpacing: 5,
//     fontColor: '#66ccff',
//     backgroundColor: '#ffffff',
//     topMargin: 100,
//     bottomMargin: 100,
//     sideMargin: 5,
//     justify: true,
//     hyphenate: true,
//     scroll: false,
//     animated: true
// }
// window.flutter_inappwebview = {}
// window.flutter_inappwebview.callHandler = (name, data) => {
//     console.log(name, data)
// }
// ///////////////////////////////
fetch(url)
    .then(res => res.blob())
    .then(blob => open(new File([blob], new URL(url, window.location.origin).pathname), cfi))
    .catch(e => console.error(e))

const callFlutter = (name, data) => window.flutter_inappwebview.callHandler(name, data)

const setStyle = () => {
    reader.view.renderer.setAttribute('flow', style.scroll ? 'scrolled' : 'paginated')
    reader.view.renderer.setAttribute('top-margin', `${style.topMargin}px`)
    reader.view.renderer.setAttribute('bottom-margin', `${style.bottomMargin}px`)
    reader.view.renderer.setAttribute('gap', `${style.sideMargin}%`)
    reader.view.renderer.setAttribute('animated', style.animated)
    const newStyle = {
        fontSize: style.fontSize,
        letterSpacing: style.letterSpacing,
        spacing: style.spacing,
        paragraphSpacing: style.paragraphSpacing,
        fontColor: style.fontColor,
        backgroundColor: style.backgroundColor,
        justify: style.justify,
        hyphenate: style.hyphenate
    }
    reader.view.renderer.setStyles?.(getCSS(newStyle))
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
        percentage
    })
}

const onAnnotationClick = (annotation) => callFlutter('onAnnotationClick', annotation)

const onSelectionEnd = (selection) => callFlutter('onSelectionEnd', selection)

const onClickView = (x, y) => callFlutter('onClick', { x, y })

const onExternalLink = (link) => console.log(link)

const onSetToc = () => callFlutter('onSetToc', reader.view.book.toc)

window.changeStyle = (newStyle) => {
    style = {
        ...style,
        ...newStyle
    }
    setStyle()
}

window.goToHref = href => reader.view.goTo(href)

window.goToPercent = percent => reader.view.goToFraction(percent)

window.nextPage = () => reader.view.next()

window.prevPage = () => reader.view.prev()

window.setScroll = (scroll) => reader.view.renderer.setAttribute('flow', scroll ? 'scrolled' : 'paginated')

window.showContextMenu = () => reader.showContextMenu()

window.clearSelection = () => reader.view.deselect()

window.addAnnotation = (annotation) => reader.addAnnotation(annotation)

window.removeAnnotation = (cfi) => reader.removeAnnotation(cfi)

window.prevSection = () => reader.view.renderer.prevSection()

window.nextSection = () => reader.view.renderer.nextSection()


