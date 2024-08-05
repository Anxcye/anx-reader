This folder forked from [johnfactotum/foliate-js](https://github.com/johnfactotum/foliate-js) which is MIT licensed.

# foliate-js

Library for rendering e-books in the browser.

Features:
- Supports EPUB, MOBI, KF8 (AZW3), FB2, CBZ, PDF (experimental; requires PDF.js), or add support for other formats yourself by implementing the book interface
- Pure JavaScript
- Small and modular
- No dependencies
- Does not depend on or include any library for unzipping; bring your own Zip library
- Does not require loading whole file into memory
- Does not care about older browsers

## Demo

The repo includes a demo viewer that can be used to open local files. To use it, serve the files with a server, and navigate to `reader.html`. Or visit the [online demo](https://johnfactotum.github.io/foliate-js/reader.html) hosted on GitHub. Note that it is very incomplete at the moment, and lacks many basic features such as keyboard shortcuts.

Also note that deobfuscating fonts with the IDPF algorithm requires a SHA-1 function. By default it uses Web Crypto, which is only available in secure contexts. Without HTTPS, you will need to modify `reader.js` and pass your own SHA-1 implementation.

## Current Status

It's far from complete or stable yet, though it should have near feature parity with [Epub.js](https://github.com/futurepress/epub.js). There's no support for continuous scrolling, however.

Among other things, the fixed-layout renderer is notably unfinished at the moment.

## Documentation

### Overview

This project uses native ES modules. There's no build step, and you can import them directly.

There are mainly three kinds of modules:

- Modules that parse and load books, implementing the "book" interface
    - `comic-book.js`, for comic book archives (CBZ)
    - `epub.js` and `epubcfi.js`, for EPUB
    - `fb2.js`, for FictionBook 2
    - `mobi.js`, for both Mobipocket files and KF8 (commonly known as AZW3) files
- Modules that handle pagination, implementing the "renderer" interface
    - `fixed-layout.js`, for fixed layout books
    - `paginator.js`, for reflowable books
- Auxiliary modules used to add additional functionalities
    - `overlayer.js`, for rendering annotations
    - `progress.js`, for getting reading progress
    - `search.js`, for searching

The modules are designed to be modular. In general, they don't directly depend on each other. Instead they depend on certain interfaces, detailed below. The exception is `view.js`. It is the higher level renderer that strings most of the things together, and you can think of it as the main entry point of the library. See "Basic Usage" below.

The repo also includes a still higher level reader, though strictly speaking, `reader.html` (along with `reader.js` and its associated files in `ui/` and `vendor/`) is not considered part of the library itself. It's akin to [Epub.js Reader](https://github.com/futurepress/epubjs-reader). You are expected to modify it or replace it with your own code.

### Basic Usage

```js
import './view.js'

const view = document.createElement('foliate-view')
document.body.append(view)

view.addEventListener('relocate', e => {
    console.log('location changed')
    console.log(e.detail)
})

const book = /* an object implementing the "book" interface */
await view.open(book)
await view.goTo(/* path, section index, or CFI */)
```

### Security

Scripting is not supported, as it is currently impossible to do so securely due to the content being served from the same origin (using `blob:` URLs).

Furthermore, while the renderers do use the `sandox` attribute on iframes, it is useless, as it requires `allow-scripts` due to a WebKit bug: https://bugs.webkit.org/show_bug.cgi?id=218086.

It is therefore imperative that you use [Content Security Policy (CSP)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP) to block all scripts except `'self'`. An EPUB file for testing can be found at https://github.com/johnfactotum/epub-test.

> [!CAUTION]
> Do NOT use this library without CSP unless you completely trust the content you're rendering or can block scripts by other means.

### The Main Interface for Books


Processors for each book(`reader.view.book`) format return an object that implements the following interface:
- `.sections`: an array of sections in the book. Each item has the following properties:
    - `.load()`: returns a string containing the URL that will be rendered. May be async.
    - `.unload()`: returns nothing. If present, can be used to free the section.
    - `.createDocument()`: returns a `Document` object of the section. Used for searching. May be async.
    - `.size`: a number, the byte size of the section. Used for showing reading progress.
    - `.linear`: a string. If it is `"no"`, the section is not part of the linear reading sequence (see the [`linear`](https://www.w3.org/publishing/epub32/epub-packages.html#attrdef-itemref-linear) attribute in EPUB).
    - `.cfi`: base CFI string of the section. The part that goes before the `!` in CFIs.
    - `.id`: an identifier for the section, used for getting TOC item (see below). Can be anything, as long as they can be used as keys in a `Map`.
- `.dir`: a string representing the page progression direction of the book (`"rtl"` or `"ltr"`).
- `.toc`: an array representing the table of contents of the book. Each item has
    - `.label`: a string label for the item
    - `.href`: a string representing the destination of the item. Does not have to be a valid URL.
    - `.subitems`: a array that contains TOC items
- `.pageList`: same as the TOC, but for the [page list](https://www.w3.org/publishing/epub32/epub-packages.html#sec-nav-pagelist).
- `.metadata`: an object representing the metadata of the book. Currently, it follows more or less the metadata schema of [Readium's webpub manifest](https://github.com/readium/webpub-manifest).
- `.rendition`: an object that contains properties that correspond to the [rendition properties](https://www.w3.org/publishing/epub32/epub-packages.html#sec-package-metadata-rendering) in EPUB. If `.layout` is `"pre-paginated"`, the book is rendered with the fixed layout renderer.
- `.resolveHref(href)`: given an href string, returns an object representing the destination referenced by the href, which has the following properties:
    - `.index`: the index of the referenced section in the `.section` array
    - `.anchor(doc)`: given a `Document` object, returns the document fragment referred to by the href (can either be an `Element` or a `Range`), or `null`
- `.resolveCFI(cfi)`: same as above, but with a CFI string instead of href
- `.isExternal(href)`: returns a boolean. If `true`, the link should be opened externally.

The following methods are consumed by `progress.js`, for getting the correct TOC and page list item when navigating:
- `.splitTOCHref(href)`: given an href string (from the TOC), returns an array, the first element of which is the `id` of the section (see above), and the second element is the fragment identifier (can be any type; see below). May be async.
- `.getTOCFragment(doc, id)`: given a `Document` object and a fragment identifier (the one provided by `.splitTOCHref()`; see above), returns a `Node` representing the target linked by the TOC item

Almost all of the properties and methods are optional. At minimum it needs `.sections` and the `.load()` method for the sections, as otherwise there won't be anything to render.

### Archived Files

Reading Zip-based formats will require adapting an external library. Both `epub.js` and `comic-book.js` expect a `loader` object that implements the following interface:

- `.entries`: (only used by `comic-book.js`) an array, each element of which has a `filename` property, which is a string containing the filename (the full path).
- `.loadText(filename)`: given the path, returns the contents of the file as string.  May be async.
- `.loadBlob(filename)`: given the path, returns the file as a `Blob` object. May be async.
- `.getSize(filename)`: returns the file size in bytes. Used to set the `.size` property for `.sections` (see above).

In the demo, this is implemented using [zip.js](https://github.com/gildas-lormeau/zip.js), which is highly recommended because it seems to be the only library that supports random access for `File` objects (as well as HTTP range requests).

One advantage of having such an interface is that one can easily use it for reading unarchived files as well. For example, the demo has a loader that allows you to open unpacked EPUBs as directories.

### Mobipocket and Kindle Files

It can read both MOBI and KF8 (.azw3, and combo .mobi files) from a `File` (or `Blob`) object. For MOBI files, it decompresses all text at once and splits the raw markup into sections at every `<mbp:pagebreak>`, instead of outputing one long page for the whole book, which drastically improves rendering performance. For KF8 files, it tries to decompress as little text as possible when loading a section, but it can still be quite slow due to the slowness of the current HUFF/CDIC decompressor implementation. In all cases, images and other resources are not loaded until they are needed.

Note that KF8 files can contain fonts that are zlib-compressed. They need to be decompressed with an external library. The demo uses [fflate](https://github.com/101arrowz/fflate) to decompress them.

### PDF and Other Fixed-Layout Formats

There is a proof-of-concept, highly experimental adapter for [PDF.js](https://mozilla.github.io/pdf.js/), with which you can show PDFs using the same fixed-layout renderer for EPUBs.

CBZs are similarly handled like fixed-layout EPUBs.

### The Renderers

It has two renderers, one for paginating reflowable books, and one for fixed-layout. They are custom elements (web components).

A renderer's interface is currently mainly:
- `.open(book)`: open a book object.
- `.goTo({ index, anchor })`: navigate to a destination. The argument has the same type as the one returned by `.resolveHref()` in the book object.
- `.prev()`: go to previous page.
- `.next()`: go to next page.

It has the following custom events:
- `load`, when a section is loaded. Its `event.detail` has two properties, `doc`, the `Document` object, and `index`, the index of the section.
- `relocate`, when the location changes. Its `event.detail` has the properties `range`, `index`, and `fraction`, where `range` is a `Range` object containing the current visible area, and `fraction` is a number between 0 and 1, representing the reading progress within the section.
- `create-overlayer`, which allows adding an overlay to the page. The `event.detail` has the properties `doc`, `index`, and a function `attach(overlay)`, which should be called with an overlayer object (see the description for `overlayer.js` below).

The paginator uses the same pagination strategy as [Epub.js](https://github.com/futurepress/epub.js): it uses CSS multi-column. As such it shares much of the same limitations (it's slow, some CSS styles do not work as expected, and other bugs). There are a few differences:
- It is a totally standalone module. You can use it to paginate any content.
- It is much simpler, but currently there's no support for continuous scrolling.
- It has no concept of CFIs and operates on `Range` objects directly. 
- It uses bisecting to find the current visible range, which is more accurate than what Epub.js does.
- It has an internal `#anchor` property, which can be a `Range`, `Element`, or a fraction that represents the current location. The view is *anchored* to it no matter how you resize the window.
- It supports more than two columns.
- It supports switching between scrolled and paginated mode without reloading (I can't figure out how to do this in Epub.js).

To simplify things, it has a totally separate renderer for fixed layout books. As such there's no support for mixed layout books.

Both renderers have the [`part`](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/part) named `filter`, which you can apply CSS filters to, to e.g. invert colors or adjust brightness:

```css
foliate-view::part(filter) {
    filter: invert(1) hue-rotate(180deg);
}
```

The filter only applies to the book itself, leaving overlaid elements such as highlights unaffected.

### The Paginator

The layout can be configured by setting the following attributes:
- `animated`: a [boolean attribute](https://developer.mozilla.org/en-US/docs/Glossary/Boolean/HTML). If present, adds a sliding transition effect.
- `flow`: either `paginated` or `scrolled`.
- `margin`: a CSS `<length>`. The unit must be `px`. The height of the header and footer.
- `gap`: a CSS `<percentage>`. The size of the space between columns, relative to page size.
- `max-inline-size`: a CSS `<length>`. The unit must be `px`. The maximum inline size of the text (column width in paginated mode).
- `max-block-size`: same as above, but for the size in the block direction.
- `max-column-count`: integer. The maximum number of columns. Has no effect in scrolled mode, or when the orientation of the renderer element is `portrait` (or, for vertical writing, `landscape`).

(Note: there's no JS property API. You must use `.setAttribute()`.)

It has built-in header and footer regions accessible via the `.heads` and `.feet` properties of the paginator instance. These can be used to display running heads and reading progress. They are only available in paginated mode, and there will be one element for each column. They are styleable with `::part(head)` and `::part(foot)`. E.g., to add a border under the running heads,

```css
foliate-view::part(head) {
    padding-bottom: 4px;
    border-bottom: 1px solid graytext;
}
```

### EPUB CFI

Parsed CFIs are represented as a plain array or object. The basic type is called a "part", which is an object with the following structure: `{ index, id, offset, temporal, spatial, text, side }`, corresponding to a step + offset in the CFI.

A collapsed, non-range CFI is represented as an array whose elements are arrays of parts, each corresponding to a full path. That is, `/6/4!/4` is turned into

```json
[
    [
        { "index": 6 },
        { "index": 4 }
    ],
    [
        { "index": 4 }
    ]
]
```

A range CFI is an object `{ parent, start, end }`, each property being the same type as a collapsed CFI. For example, `/6/4!/2,/2,/4` is represented as

```json
{
    "parent": [
        [
            { "index": 6 },
            { "index": 4 }
        ],
        [
            { "index": 2 }
        ]
    ],
    "start": [
        [
            { "index": 2 }
        ]
    ],
    "end": [
        [
            { "index": 4 }
        ]
    ]
}
```

The parser uses a state machine rather than regex, and should handle assertions that contain escaped characters correctly (see tests for examples of this).

It has the ability ignore nodes, which is needed if you want to inject your own nodes into the document without affecting CFIs. To do this, you need to pass the optional filter function that works similarily to the filter function of [`TreeWalker`s](https://developer.mozilla.org/en-US/docs/Web/API/Document/createTreeWalker):

```js
const filter = node => node.nodeType !== 1 ? NodeFilter.FILTER_ACCEPT
    : node.matches('.reject') ? NodeFilter.FILTER_REJECT
    : node.matches('.skip') ? NodeFilter.FILTER_SKIP
    : NodeFilter.FILTER_ACCEPT

CFI.toRange(doc, 'epubcfi(...)', filter)
CFI.fromRange(range, filter)
```

It can parse and stringify spatial and temporal offsets, as well as text location assertions and side bias, but there's no support for employing them when rendering yet.

### Highlighting Text

There is a generic module for overlaying arbitrary SVG elements, `overlayer.js`. It can be used to implement highlighting text for annotations. It's the same technique used by [marks-pane](https://github.com/fchasen/marks), used by Epub.js, but it's designed to be easily extensible. You can return any SVG element in the `draw` function, making it possible to add custom styles such as squiggly lines or even free hand drawings.

The overlay has no event listeners by default. It only provides a `.hitTest(event)` method, that can be used to do hit tests. Currently it does this with the client rects of `Range`s, not the element returned by `draw()`.

An overlayer object implements the following interface for the consumption of renderers:
- `.element`: the DOM element of the overlayer. This element will be inserted, resized, and positioned automatically by the renderer on top of the page.
- `.redraw()`: called by the renderer when the overlay needs to be redrawn.

### The Text Walker

Not a particularly descriptive name, but essentially, `text-walker.js` is a small DOM utility that allows you to

1. Gather all text nodes in a `Range`, `Document` or `DocumentFragment` into an array of strings.
2. Perform splitting or matching on the strings.
3. Get back the results of these string operations as `Range`s.

E.g. you can join all the text nodes together, use `Intl.Segmenter` to segment the string into words, and get the results in DOM Ranges, so you can mark up those words in the original document.

In foliate-js, this is used for searching and TTS.

### Searching

It provides a search module, which can in fact be used as a standalone module for searching across any array of strings. There's no limit on the number of strings a match is allowed to span. It's based on `Intl.Collator` and `Intl.Segmenter`, to support ignoring diacritics and matching whole words only. It's extrenely slow, and you'd probably want to load results incrementally.

### Text-to-Speech (TTS)

The TTS module doesn't directly handle speech output. Rather, its methods return SSML documents (as strings), which you can then feed to your speech synthesizer.

The SSML attributes `ssml:ph` and `ssml:alphabet` are supported. There's no support for PLS and CSS Speech.

### Offline Dictionaries

The `dict.js` module can be used to load dictd and StarDict dictionaries. Usage:

```js
import { StarDict } from './dict.js'
import { inflate } from 'your inflate implementation'

const { ifo, dz, idx, syn } = { /* `File` (or `Blob`) objects */ }
const dict = new StarDict()
await dict.loadIfo(ifo)
await dict.loadDict(dz, inflate)
await dict.loadIdx(idx)
await dict.loadSyn(syn)

// look up words
const query = '...'
await dictionary.lookup(query)
await dictionary.synonyms(query)
```

Note that you must supply your own `inflate` function. Here is an example using [fflate](https://github.com/101arrowz/fflate):
```js
const inflate = data => new Promise(resolve => {
    const inflate = new fflate.Inflate()
    inflate.ondata = data => resolve(data)
    inflate.push(data)
})
```

### OPDS

The `opds.js` module can be used to implement OPDS clients. It can convert OPDS 1.x documents to OPDS 2.0:

- `getFeed(doc)`: converts an OPDS 1.x feed to OPDS 2.0. The argument must be a DOM Document object. You need to use a `DOMParser` to obtain a Document first if you have a string.
- `getPublication(entry)`: converts a OPDS 1.x entry in acquisition feeds to an OPDS 2.0 publication. The argument must be a DOM Element object.

It exports the following symbols for properties unsupported by OPDS 2.0:
- `SYMBOL.SUMMARY`: used on navigation links to represent the summary/content (see https://github.com/opds-community/drafts/issues/51)
- `SYMBOL.CONTENT`: used on publications to represent the content/description and its type. This is mainly for preserving the type info for XHTML. The value of this property is an object whose properties are:
    - `.type`: either "text", "html", or "xhtml"
    - `.value`: the value of the content

There are also two functions that can be used to implement search forms:

- `getOpenSearch(doc)`: for OpenSearch. The argument is a DOM Document object of an OpenSearch search document.
- `getSearch(link)` for templated search in OPDS 2.0. The argument must be an OPDS 2.0 Link object. Note that this function will import `uri-template.js`.

These two functions return an object that implements the following interface:
- `.metadata`: an object with the string properties `title` and `description`
- `.params`: an array, representing the search parameters, whose elements are objects whose properties are
    - `ns`: a string; the namespace of the parameter
    - `name`: a string; the name of the parameter
    - `required`: a boolean, whether the parameter is required
    - `value`: a string; the default value of the parameter
- `.search(map)`: a function, whose argument is a `Map` whose values are `Map`s (i.e. a two-dimensional map). The first key is the namespace of the search parameter. For non-namespaced parameters, the first key must be `null`. The second key is the parameter's name. Returns a string representing the URL of the search results.

### Supported Browsers

The main use of the library is for use in [Foliate](https://github.com/johnfactotum/foliate), which uses WebKitGTK. As such it's the only engine that has been tested extensively. But it should also work in Chromium and Firefox.

Apart from the renderers, using the modules outside browsers is also possible. Most features depend on having the global objects `Blob`, `TextDecoder`, `TextEncoder`, `DOMParser`, `XMLSerializer`, and `URL`, and should work if you polyfill them. Note that `epubcfi.js` can be used as is in any envirnoment if you only need to parse or sort CFIs.

## License

MIT.

Vendored libraries for the demo:
- [zip.js](https://github.com/gildas-lormeau/zip.js) is licensed under the BSD-3-Clause license.
- [fflate](https://github.com/101arrowz/fflate) is MIT licensed.
- [PDF.js](https://mozilla.github.io/pdf.js/) is licensed under Apache.
