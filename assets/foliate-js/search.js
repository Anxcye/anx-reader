// length for context in excerpts
const CONTEXT_LENGTH = 50

const normalizeWhitespace = str => str.replace(/\s+/g, ' ')

const makeExcerpt = (strs, { startIndex, startOffset, endIndex, endOffset }) => {
    const start = strs[startIndex]
    const end = strs[endIndex]
    const match = start === end
        ? start.slice(startOffset, endOffset)
        : start.slice(startOffset)
            + strs.slice(start + 1, end).join('')
            + end.slice(0, endOffset)
    const trimmedStart = normalizeWhitespace(start.slice(0, startOffset)).trimStart()
    const trimmedEnd = normalizeWhitespace(end.slice(endOffset)).trimEnd()
    const ellipsisPre = trimmedStart.length < CONTEXT_LENGTH ? '' : '…'
    const ellipsisPost = trimmedEnd.length < CONTEXT_LENGTH ? '' : '…'
    const pre = `${ellipsisPre}${trimmedStart.slice(-CONTEXT_LENGTH)}`
    const post = `${trimmedEnd.slice(0, CONTEXT_LENGTH)}${ellipsisPost}`
    return { pre, match, post }
}

const simpleSearch = function* (strs, query, options = {}) {
    const { locales = 'en', sensitivity } = options
    const matchCase = sensitivity === 'variant'
    const haystack = strs.join('')
    const lowerHaystack = matchCase ? haystack : haystack.toLocaleLowerCase(locales)
    const needle = matchCase ? query : query.toLocaleLowerCase(locales)
    const needleLength = needle.length
    let index = -1
    let strIndex = -1
    let sum = 0
    do {
        index = lowerHaystack.indexOf(needle, index + 1)
        if (index > -1) {
            while (sum <= index) sum += strs[++strIndex].length
            const startIndex = strIndex
            const startOffset = index - (sum - strs[strIndex].length)
            const end = index + needleLength
            while (sum <= end) sum += strs[++strIndex].length
            const endIndex = strIndex
            const endOffset = end - (sum - strs[strIndex].length)
            const range = { startIndex, startOffset, endIndex, endOffset }
            yield { range, excerpt: makeExcerpt(strs, range) }
        }
    } while (index > -1)
}

const segmenterSearch = function* (strs, query, options = {}) {
    const { locales = 'en', granularity = 'word', sensitivity = 'base' } = options
    let segmenter, collator
    try {
        segmenter = new Intl.Segmenter(locales, { usage: 'search', granularity })
        collator = new Intl.Collator(locales, { sensitivity })
    } catch (e) {
        console.warn(e)
        segmenter = new Intl.Segmenter('en', { usage: 'search', granularity })
        collator = new Intl.Collator('en', { sensitivity })
    }
    const queryLength = Array.from(segmenter.segment(query)).length

    const substrArr = []
    let strIndex = 0
    let segments = segmenter.segment(strs[strIndex])[Symbol.iterator]()
    main: while (strIndex < strs.length) {
        while (substrArr.length < queryLength) {
            const { done, value } = segments.next()
            if (done) {
                // the current string is exhausted
                // move on to the next string
                strIndex++
                if (strIndex < strs.length) {
                    segments = segmenter.segment(strs[strIndex])[Symbol.iterator]()
                    continue
                } else break main
            }
            const { index, segment } = value
            // ignore formatting characters
            if (!/[^\p{Format}]/u.test(segment)) continue
            // normalize whitespace
            if (/\s/u.test(segment)) {
                if (!/\s/u.test(substrArr[substrArr.length - 1]?.segment))
                    substrArr.push({ strIndex, index, segment: ' ' })
                continue
            }
            value.strIndex = strIndex
            substrArr.push(value)
        }
        const substr = substrArr.map(x => x.segment).join('')
        if (collator.compare(query, substr) === 0) {
            const endIndex = strIndex
            const lastSeg = substrArr[substrArr.length - 1]
            const endOffset = lastSeg.index + lastSeg.segment.length
            const startIndex = substrArr[0].strIndex
            const startOffset = substrArr[0].index
            const range = { startIndex, startOffset, endIndex, endOffset }
            yield { range, excerpt: makeExcerpt(strs, range) }
        }
        substrArr.shift()
    }
}

export const search = (strs, query, options) => {
    const { granularity = 'grapheme', sensitivity = 'base' } = options
    if (!Intl?.Segmenter || granularity === 'grapheme'
    && (sensitivity === 'variant' || sensitivity === 'accent'))
        return simpleSearch(strs, query, options)
    return segmenterSearch(strs, query, options)
}

export const searchMatcher = (textWalker, opts) => {
    const { defalutLocale, matchCase, matchDiacritics, matchWholeWords } = opts
    return function* (doc, query) {
        const iter = textWalker(doc, function* (strs, makeRange) {
            for (const result of search(strs, query, {
                locales: doc.body.lang || doc.documentElement.lang || defalutLocale || 'en',
                granularity: matchWholeWords ? 'word' : 'grapheme',
                sensitivity: matchDiacritics && matchCase ? 'variant'
                : matchDiacritics && !matchCase ? 'accent'
                : !matchDiacritics && matchCase ? 'case'
                : 'base',
            })) {
                const { startIndex, startOffset, endIndex, endOffset } = result.range
                result.range = makeRange(startIndex, startOffset, endIndex, endOffset)
                yield result
            }
        })
        for (const result of iter) yield result
    }
}
