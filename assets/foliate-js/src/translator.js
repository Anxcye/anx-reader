// Translation modes
export const TranslationMode = {
  OFF: 'off',
  TRANSLATION_ONLY: 'translation-only', 
  ORIGINAL_ONLY: 'original-only',
  BILINGUAL: 'bilingual'
}

// Make TranslationMode globally available for debugging
if (typeof window !== 'undefined') {
  window.TranslationMode = TranslationMode
}

const isTranslationFailure = (value) => {
  if (typeof value !== 'string' || value.trim().length === 0) return true
  const raw = value.trim()
  const normalized = raw.toLowerCase().replace(/\s+/g, ' ')
  return normalized === '...'
    || normalized.startsWith('translation failed:')
    || normalized.startsWith('translation error:')
    || normalized.startsWith('translate error')
    || normalized.startsWith('error:')
    || normalized.startsWith('failed:')
    || (normalized.includes('api key') && normalized.includes('please set'))
    || (normalized.includes('api key') && normalized.includes('invalid'))
    || normalized.includes('authentication failed')
    || normalized.includes('service not configured')
    || (normalized.includes('ai service') && (normalized.includes('configure')
      || normalized.includes('configured')
      || normalized.includes('setting')
      || normalized.includes('settins')))
    || raw.includes('AI配置')
    || raw.includes('AI 配置')
    || raw.includes('AI設定')
    || raw.includes('AI 設定')
    || raw.includes('AI服务')
    || raw.includes('AI 服務')
}

const getTranslationErrorFallbackText = () => window.i18n?.translateError || 'Translation failed'

const getRetryText = () => window.i18n?.retry || 'Retry'

const getRetryingText = () => window.i18n?.retrying || `${getRetryText()}...`

const getTranslationErrorMessage = (value) => {
  if (typeof value !== 'string') return getTranslationErrorFallbackText()
  const sanitized = sanitizeTranslationResult(value)
  return sanitized && sanitized.trim().length > 0
    ? sanitized.trim()
    : getTranslationErrorFallbackText()
}

const isNonRetryableTranslationFailure = (value) => {
  if (typeof value !== 'string' || value.trim().length === 0) return false
  const raw = value.trim()
  const normalized = raw.toLowerCase().replace(/\s+/g, ' ')
  return normalized.includes('authentication failed')
    || normalized.includes('service not configured')
    || (normalized.includes('ai service') && (normalized.includes('configure')
      || normalized.includes('configured')
      || normalized.includes('setting')
      || normalized.includes('settins')))
    || (normalized.includes('api key') && normalized.includes('invalid'))
    || raw.includes('AI配置')
    || raw.includes('AI 配置')
    || raw.includes('AI設定')
    || raw.includes('AI 設定')
    || raw.includes('AI服务')
    || raw.includes('AI 服務')
}

const sanitizeTranslationResult = (value) => {
  if (typeof value !== 'string') return value
  return value.replace(/<think>[\s\S]*?<\/think>/gi, '').trim()
}

// Translation function that calls Flutter's translation service
const translate = async (text) => {
  try {
    // Call Flutter's translation handler
    const result = await window.flutter_inappwebview.callHandler('translateText', text)
    const sanitizedResult = sanitizeTranslationResult(result)
    if (isTranslationFailure(sanitizedResult)) {
      throw new Error(getTranslationErrorMessage(sanitizedResult))
    }
    return sanitizedResult
  } catch (error) {
    console.error('Translation failed:', error)
    throw error
  }
}

export class Translator {
  #translationMode = TranslationMode.OFF
  observedElements = new Set()
  #translatedElements = new WeakMap()
  #observer = null
  #translationQueue = []
  #pendingTasks = new Map()
  #isTranslating = false
  #maxConcurrent = 3 // Maximum concurrent translations
  #requestDelay = 500 // Delay between requests in ms
  #cache = {} // Persistent translation cache, keyed by stable element identifiers
  #cacheLoadPromise = null
  #cacheNamespace = null
  #rootMargin = '1600px' // Medium pre-translation level (default)
  #maxCacheSize = 5000 // Maximum cache entries
  #separator = '\x1f' // Unit Separator for batch translation
  #maxBatchSize = 5 // Maximum paragraphs per batch
  #maxBatchChars = 3000 // Maximum total characters per batch
  #progressTotal = 0
  #progressCompleted = 0
  #progressFailed = 0
  #progressIdleTimer = null
  #persistCacheTimer = null

  constructor() {
    this.#initializeObserver()
  }

  #initializeObserver() {
    this.#observer = new IntersectionObserver(
      (entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            this.#queueTranslation(entry.target)
          }
        })
        this.#processQueue()
      },
      {
        rootMargin: this.#rootMargin,
        threshold: 0
      }
    )
  }

  // Set the observation margin (e.g., '1600px' for ~3 pages)
  setRootMargin(margin) {
    this.#rootMargin = margin
    if (this.#observer) {
      this.#observer.disconnect()
      this.#initializeObserver()
      // Re-observe all elements with new margin
      this.observedElements.forEach(element => {
        try { this.#observer.observe(element) } catch (e) {}
      })
    }
  }

  #isElementConnected(element) {
    return Boolean(element?.isConnected && element.parentNode)
  }

  #canApplyToElement(element, expectedText = null) {
    if (!this.#isElementConnected(element)) return false
    if (!this.observedElements.has(element)) return false
    if (expectedText == null) return true

    const translated = this.#translatedElements.get(element)
    if (translated?.originalText === expectedText) return true

    const text = element.innerText?.trim()
    return Boolean(text) && text === expectedText
  }

  #getTaskKey(cacheKey, text) {
    return `${cacheKey || this.#getChapterId()}::${text}`
  }

  #takePendingElements(item) {
    const pending = item?.taskKey ? this.#pendingTasks.get(item.taskKey) : null
    if (item?.taskKey) this.#pendingTasks.delete(item.taskKey)
    if (pending) return Array.from(pending.elements)
    return item?.element ? [item.element] : []
  }

  #pruneStaleWork() {
    const staleElements = new Set()

    this.observedElements.forEach(element => {
      if (this.#isElementConnected(element)) return
      staleElements.add(element)
      this.#translatedElements.delete(element)
      try { this.#observer?.unobserve(element) } catch (e) {}
      this.observedElements.delete(element)
    })

    if (staleElements.size === 0) return

    this.#translationQueue = this.#translationQueue.filter(item => !staleElements.has(item.element))

    for (const [taskKey, pending] of this.#pendingTasks.entries()) {
      pending.elements = new Set(
        Array.from(pending.elements).filter(element => !staleElements.has(element))
      )

      if (pending.elements.size === 0) {
        this.#pendingTasks.delete(taskKey)
      }
    }
  }

  #clearQueuedTranslations() {
    if (this.#translationQueue.length === 0) return

    const removedCount = this.#translationQueue.length
    const queuedTaskKeys = new Set(this.#translationQueue.map(item => item.taskKey))
    this.#translationQueue = []
    queuedTaskKeys.forEach(taskKey => this.#pendingTasks.delete(taskKey))

    this.#progressTotal = Math.max(this.#progressCompleted, this.#progressTotal - removedCount)
    this.#reportTranslationProgress(this.#isTranslating)
  }

  // Queue translation requests
  #queueTranslation(element) {
    this.#pruneStaleWork()

    if (this.#translationMode === TranslationMode.OFF) return
    if (this.#translatedElements.has(element)) return

    const text = element.innerText?.trim()
    if (!text) return

    if (this.#applyCachedTranslation(element, text)) return

    const cacheKey = this.#getCacheKey(element)
    const taskKey = this.#getTaskKey(cacheKey, text)
    const pendingTask = this.#pendingTasks.get(taskKey)
    if (pendingTask) {
      pendingTask.elements.add(element)
      return
    }

    // Add to queue if not already queued
    if (!this.#translationQueue.find(item => item.element === element)) {
      this.#startProgressItem()
      this.#translationQueue.push({ element, text, cacheKey, taskKey })
      this.#pendingTasks.set(taskKey, { elements: new Set([element]) })
      this.#reportTranslationProgress(true)
    }
  }

  // Process queue using batch translation
  async #processQueue() {
    this.#pruneStaleWork()

    if (this.#isTranslating) return
    if (this.#translationQueue.length === 0) return
    if (this.#translationMode === TranslationMode.OFF) return

    this.#isTranslating = true

    // In translation-only and bilingual mode, prefer batch translation for
    // efficiency, but bilingual mode must preserve strict 1:1 paragraph pairing.
    // Any batch result that cannot be split back to the exact paragraph count
    // is discarded and retried paragraph-by-paragraph.
    const useBatch =
      this.#translationMode === TranslationMode.TRANSLATION_ONLY ||
      this.#translationMode === TranslationMode.BILINGUAL

    if (useBatch) {
      await this.#processBatch()
    } else {
      await this.#processIndividual()
    }

    this.#isTranslating = false

    // Process remaining queue if any
    if (this.#translationQueue.length > 0 && this.#translationMode !== TranslationMode.OFF) {
      setTimeout(() => this.#processQueue(), this.#requestDelay)
    }
  }

  // Process a batch of paragraphs. Bilingual mode uses the same batching path,
  // but only accepts results that split back to an exact 1:1 paragraph mapping.
  async #processBatch() {
    const batch = this.#buildBatch()
    if (batch.length === 0) return

    // Sort by DOM position before translation
    batch.sort((a, b) => this.#compareDomPosition(a.element, b.element))

    try {
      if (batch.length > 1) {
        const combinedText = batch.map(item => item.text).join(this.#separator)
        const combinedResult = await translate(combinedText)
        const translations = this.#splitBatchResult(combinedResult, batch.length)

        for (let i = 0; i < batch.length; i++) {
          const item = batch[i]
          this.#applyTranslated(item, item.text, translations[i])
        }
      } else if (batch.length === 1) {
        const item = batch[0]
        const translatedText = await this.#translateWithRetry(item.text)
        this.#applyTranslated(item, item.text, translatedText)
      }
    } catch (error) {
      console.warn('Batch translation failed, falling back to individual:', error)
      for (const item of batch) {
        try {
          const translatedText = await this.#translateWithRetry(item.text)
          this.#applyTranslated(item, item.text, translatedText)
        } catch (e) {
          console.warn('Translation failed:', e)
          this.#applyTranslationError(item, item.text, e?.message || String(e))
          this.#finishProgressItem(true)
        }
      }
    }
  }

  #splitBatchResult(combinedResult, expectedCount) {
    const translations = combinedResult
      .split(this.#separator)
      .map(text => text.trim())

    if (translations.length !== expectedCount) {
      throw new Error(`Batch translation count mismatch: ${translations.length}/${expectedCount}`)
    }

    if (translations.some(text => !text || isTranslationFailure(text))) {
      throw new Error('Batch translation contains empty or failed segments')
    }

    return translations
  }

  // Process individual paragraphs for bilingual mode (1:1 pairing)
  async #processIndividual() {
    const item = this.#translationQueue.shift()
    if (!item) return

    try {
      const translatedText = await this.#translateWithRetry(item.text)
      this.#applyTranslated(item, item.text, translatedText)
    } catch (error) {
      console.warn('Translation failed:', error)
      this.#applyTranslationError(item, item.text, error?.message || String(error))
      this.#finishProgressItem(true)
    }
  }

  // Retry transient translation failures with exponential backoff.
  async #translateWithRetry(text, maxRetries = 3) {
    let lastError
    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          const delay = Math.min(1000 * Math.pow(2, attempt - 1), 5000)
          await new Promise(resolve => setTimeout(resolve, delay))
        }

        const result = await translate(text)
        if (!isTranslationFailure(result)) return result
        lastError = new Error(result)
        if (isNonRetryableTranslationFailure(result)) {
          throw lastError
        }
      } catch (e) {
        lastError = e
        const errorMessage = e?.message ?? e?.toString?.() ?? ''
        if (isNonRetryableTranslationFailure(errorMessage)) {
          throw e
        }
      }
    }

    throw lastError
  }

  // Apply translated text and update cache
  #applyTranslated(element, originalText, translatedText) {
    const item = element?.element && element?.text
      ? element
      : {
          element,
          text: originalText,
          cacheKey: this.#getCacheKey(element),
          taskKey: this.#getTaskKey(this.#getCacheKey(element), originalText),
        }

    if (isTranslationFailure(translatedText)) {
      this.#applyTranslationError(
        item,
        item.text,
        translatedText,
      )
      this.#finishProgressItem(true)
      return
    }

    const cacheData = { originalText: item.text, translatedText }
    if (item.cacheKey) this.#cache[item.cacheKey] = cacheData

    for (const target of this.#takePendingElements(item)) {
      if (!this.#canApplyToElement(target, item.text)) continue
      this.#translatedElements.set(target, cacheData)
      this.#applyTranslation(target, translatedText)
    }

    this.#schedulePersistCache()
    this.#finishProgressItem(false)
  }

  #applyCachedTranslation(element, text) {
    const cacheKey = this.#getCacheKey(element)
    if (!cacheKey || !this.#cache[cacheKey]) return false

    const cached = this.#cache[cacheKey]
    if (cached.originalText !== text) return false
    if (isTranslationFailure(cached.translatedText)) {
      delete this.#cache[cacheKey]
      this.#schedulePersistCache()
      return false
    }

    this.#translatedElements.set(element, cached)
    this.#applyTranslation(element, cached.translatedText)
    return true
  }

  #applyTranslationError(element, originalText, errorMessage = 'Translation failed') {
    const item = element?.element && element?.text
      ? element
      : {
          element,
          text: originalText,
          cacheKey: this.#getCacheKey(element),
          taskKey: this.#getTaskKey(this.#getCacheKey(element), originalText),
        }

    if (item.cacheKey && this.#cache[item.cacheKey]) {
      delete this.#cache[item.cacheKey]
      this.#schedulePersistCache()
    }

    for (const target of this.#takePendingElements(item)) {
      if (!this.#canApplyToElement(target, item.text)) continue

      this.#translatedElements.delete(target)

      const existingTranslation = this.#findTranslationWrapper(target)
      if (existingTranslation) {
        existingTranslation.remove()
      }

      const wrapper = document.createElement('div')
      wrapper.className = 'translated-text translated-error'
      wrapper.setAttribute('data-translation-mark', '1')

      const message = document.createElement('span')
      message.className = 'translated-error-message'
      message.textContent = getTranslationErrorMessage(errorMessage)
      wrapper.appendChild(message)

      const retryButton = document.createElement('button')
      retryButton.type = 'button'
      retryButton.className = 'translated-error-retry'
      retryButton.textContent = getRetryText()
      retryButton.style.marginLeft = '8px'
      retryButton.addEventListener('click', async () => {
        retryButton.disabled = true
        retryButton.textContent = getRetryingText()
        try {
          const translatedText = await this.#translateWithRetry(item.text)
          this.#applyTranslated(target, item.text, translatedText)
        } catch (error) {
          console.warn('Retry translation failed:', error)
          message.textContent = getTranslationErrorMessage(error?.message || String(error))
          retryButton.disabled = false
          retryButton.textContent = getRetryText()
        }
      })
      wrapper.appendChild(retryButton)

      this.#restoreOriginalText(target)
      if (target.parentNode) {
        target.parentNode.insertBefore(wrapper, target.nextSibling)
      }
    }
  }

  #startProgressItem() {
    if (this.#progressIdleTimer) {
      clearTimeout(this.#progressIdleTimer)
      this.#progressIdleTimer = null
    }

    if (
      this.#progressTotal > 0 &&
      this.#progressCompleted >= this.#progressTotal &&
      !this.#isTranslating &&
      this.#translationQueue.length === 0
    ) {
      this.#progressTotal = 0
      this.#progressCompleted = 0
      this.#progressFailed = 0
    }

    this.#progressTotal += 1
  }

  #finishProgressItem(failed) {
    if (this.#progressTotal <= 0) return

    this.#progressCompleted = Math.min(this.#progressCompleted + 1, this.#progressTotal)
    if (failed) this.#progressFailed += 1
    this.#reportTranslationProgress(true)

    if (
      this.#progressCompleted >= this.#progressTotal &&
      this.#translationQueue.length === 0
    ) {
      if (this.#progressIdleTimer) clearTimeout(this.#progressIdleTimer)
      this.#progressIdleTimer = setTimeout(() => {
        if (this.#translationQueue.length === 0 && !this.#isTranslating) {
          this.#reportTranslationProgress(false)
        }
      }, 600)
    }
  }

  #reportTranslationProgress(active) {
    try {
      if (!window.flutter_inappwebview) return
      window.flutter_inappwebview.callHandler('onTranslationProgress', {
        active,
        completed: this.#progressCompleted,
        total: this.#progressTotal,
        pending: this.#translationQueue.length,
        failed: this.#progressFailed,
        mode: this.#translationMode,
      })
    } catch (e) {}
  }

  #schedulePersistCache() {
    if (this.#persistCacheTimer) return

    this.#persistCacheTimer = setTimeout(() => {
      this.#persistCacheTimer = null
      this.#persistCache()
    }, 250)
  }

  // Compare DOM position of two elements
  #compareDomPosition(a, b) {
    if (a === b) return 0
    const position = a.compareDocumentPosition?.(b)
    if (position === undefined) return 0
    if (position & Node.DOCUMENT_POSITION_FOLLOWING) return -1
    if (position & Node.DOCUMENT_POSITION_PRECEDING) return 1
    return 0
  }

  // Build a batch of adjacent paragraphs for combined translation
  #buildBatch() {
    const batch = []
    let totalChars = 0

    while (
      this.#translationQueue.length > 0 &&
      batch.length < this.#maxBatchSize &&
      totalChars < this.#maxBatchChars
    ) {
      const item = this.#translationQueue.shift()
      batch.push(item)
      totalChars += item.text.length
    }

    return batch
  }

  async setTranslationMode(mode) {
    if (!Object.values(TranslationMode).includes(mode)) {
      console.warn(`Invalid translation mode: ${mode}`)
      return
    }

    const oldMode = this.#translationMode
    this.#translationMode = mode

    await this.loadCache({ forceReload: true, resetRendered: true })

    if (oldMode !== mode) {
      // console.log(`Translation mode changed from ${oldMode} to ${mode}`)

      if (mode === TranslationMode.OFF) {
        // Turn off translation
        this.#updateTranslationDisplay()
      } else if (oldMode === TranslationMode.OFF) {
        // Turn on translation - force translate visible elements and wait for completion
        await this.#forceTranslateVisibleElements()
      } else {
        // Just update display mode
        this.#updateTranslationDisplay()
      }
    }

    // Re-render annotations after translation mode change (and after translation completion)
    if (window.reader && window.reader.annotationsByValue) {
      const existingAnnotations = Array.from(window.reader.annotationsByValue.values())
      if (existingAnnotations.length > 0) {
        // console.log('Re-rendering annotations after translation mode change:', existingAnnotations.length)
        window.renderAnnotations(existingAnnotations)
      }
    }
  }

  async refreshCache() {
    return this.loadCache({ forceReload: true, resetRendered: true })
  }

  getTranslationMode() {
    return this.#translationMode
  }

  observeDocument(doc) {
    // console.log('Observing document for translation, doc:', doc)
    if (!doc) {
      console.warn('No document provided to observeDocument')
      return
    }

    this.#pruneStaleWork()

    const textElements = this.#walkTextNodes(doc.body || doc.documentElement)
    // console.log(`Found ${textElements.length} text elements to observe`)

    textElements.forEach(element => {
      if (!this.observedElements.has(element)) {
        this.#observer.observe(element)
        this.observedElements.add(element)
        // console.log('Added element to observer:', element.tagName, element.textContent?.substring(0, 50))
      }
    })

    // console.log(`Total observed elements: ${this.observedElements.size}`)

    // Check cache for already-translated elements
    this.#applyCachedTranslations()
  }

  // Apply cached translations to newly loaded document
  #applyCachedTranslations() {
    const cacheKeys = Object.keys(this.#cache)
    if (cacheKeys.length === 0) return

    this.#pruneStaleWork()

    this.observedElements.forEach(element => {
      if (this.#translatedElements.has(element)) return

      const cacheKey = this.#getCacheKey(element)
      if (cacheKey && this.#cache[cacheKey]) {
        const cached = this.#cache[cacheKey]
        const text = element.innerText?.trim()
        if (text && cached.originalText === text) {
          this.#translatedElements.set(element, cached)
          this.#applyTranslation(element, cached.translatedText)
        }
      }
    })
  }

  #resetRenderedTranslations() {
    this.observedElements.forEach(element => {
      const translationWrapper = this.#findTranslationWrapper(element)
      if (translationWrapper) {
        translationWrapper.remove()
      }
      this.#restoreOriginalText(element)
    })

    this.#translatedElements = new WeakMap()
  }

  #findTranslationWrapper(element) {
    let sibling = element?.nextElementSibling
    while (sibling) {
      if (sibling.classList?.contains('translated-text')) {
        return sibling
      }
      if (!sibling.hasAttribute?.('data-translation-mark')) {
        break
      }
      sibling = sibling.nextElementSibling
    }
    return null
  }

  clearTranslations() {
    this.#clearQueuedTranslations()

    // Remove all translation elements and restore original content
    this.observedElements.forEach(element => {
      const translationWrapper = this.#findTranslationWrapper(element)
      if (translationWrapper) {
        translationWrapper.remove()
      }
      
      // Restore original text if hidden
      this.#restoreOriginalText(element)
    })
    
    // Clear observer
    this.#observer.disconnect()
    this.observedElements.clear()
    this.#translatedElements = new WeakMap()
    this.#pendingTasks.clear()
    this.#isTranslating = false
    
    // Reinitialize observer
    this.#initializeObserver()
  }

  #walkTextNodes(root, rejectTags = ['pre', 'code', 'math', 'style', 'script']) {
    const elements = []

    // Define preferred paragraph-level elements
    const preferredTags = ['p', 'div', 'blockquote', 'li', 'dd', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'section', 'article', 'aside']
    // Define inline elements to skip (translate at parent level)
    const inlineTags = ['span', 'em', 'strong', 'b', 'i', 'u', 'a', 'font', 'mark', 'small', 'sub', 'sup']

    const walk = (node, depth = 0) => {
      if (depth > 15) return

      const children = Array.from(node.children || [])
      for (const child of children) {
        if (rejectTags.includes(child.tagName.toLowerCase())) {
          continue
        }

        // Skip translation elements
        if (child.classList.contains('translated-text')) {
          continue
        }

        // Skip inline elements - they should be translated as part of their parent
        if (inlineTags.includes(child.tagName.toLowerCase())) {
          // Don't add inline elements, but still traverse their children
          // in case they contain nested elements
          if (child.children.length > 0) {
            walk(child, depth + 1)
          }
          continue
        }

        // Prioritize paragraph-level elements
        if (preferredTags.includes(child.tagName.toLowerCase())) {
          // Check if it has meaningful text content
          const textContent = child.textContent?.trim()
          if (textContent && textContent.length > 0) {
            // Check if children are mostly inline elements or text
            const hasBlockChildren = Array.from(child.children).some(c =>
              !inlineTags.includes(c.tagName.toLowerCase()) &&
              !rejectTags.includes(c.tagName.toLowerCase())
            )

            // If no block-level children, this is a good translation unit
            if (!hasBlockChildren) {
              elements.push(child)
              continue // Don't traverse deeper into this element
            }
          }
          // If it has block children, traverse deeper
          walk(child, depth + 1)
          continue
        }

        // For non-preferred, non-inline elements
        const hasDirectText = Array.from(child.childNodes).some(node => {
          if (node.nodeType === Node.TEXT_NODE && node.textContent?.trim()) {
            return true
          }
          return false
        })

        if (child.children.length === 0 && child.textContent?.trim()) {
          elements.push(child)
        } else if (hasDirectText) {
          // Check if it's a leaf-like element with mostly text
          const textLength = child.textContent?.trim().length || 0
          if (textLength > 10) {
            elements.push(child)
          } else {
            walk(child, depth + 1)
          }
        } else if (child.children.length > 0) {
          walk(child, depth + 1)
        }
      }
    }

    walk(root)
    return elements
  }

  async #translateElement(element) {
    if (this.#translationMode === TranslationMode.OFF) return
    if (this.#translatedElements.has(element)) return

    const text = element.innerText?.trim()
    if (!text) return

    // Check persistent cache first
    const cacheKey = this.#getCacheKey(element)
    if (cacheKey && this.#cache[cacheKey]) {
      const cached = this.#cache[cacheKey]
      // Verify cached text matches current text
      if (cached.originalText === text) {
        this.#translatedElements.set(element, cached)
        this.#applyTranslation(element, cached.translatedText)
        return
      }
    }

    try {
      const translatedText = await this.#translateWithRetry(text)

      const cacheData = {
        originalText: text,
        translatedText: translatedText
      }
      this.#translatedElements.set(element, cacheData)

      // Store in persistent cache
      if (cacheKey) {
        this.#cache[cacheKey] = cacheData
        // Persist to Flutter
        this.#persistCache()
      }

      this.#applyTranslation(element, translatedText)
    } catch (error) {
      console.warn('Translation failed:', error)
      this.#applyTranslationError(element, text, error?.message || String(error))
    }
  }

  // Generate a stable cache key for an element
  #getCacheKey(element) {
    // Primary: CFI (most precise)
    try {
      if (window.reader && window.reader.view) {
        const cfi = window.reader.view.getCFIFromDomElement?.(element)
        if (cfi) return cfi
      }
    } catch (e) {}

    // Fallback: stable structure path signature
    const chapterId = this.#getChapterId()
    const pathSignature = this.#getElementPath(element)
    if (pathSignature) {
      return `${chapterId}:${pathSignature}`
    }

    // Last resort: text hash (least reliable)
    if (element.innerText) {
      let hash = 0
      const text = element.innerText.trim().substring(0, 100)
      for (let i = 0; i < text.length; i++) {
        hash = ((hash << 5) - hash) + text.charCodeAt(i)
        hash |= 0
      }
      return `${chapterId}:hash_${hash}`
    }
    return null
  }

  // Extract chapter identifier from current location
  #getChapterId() {
    try {
      if (window.reader?.view?.location?.cfi) {
        // Use first 60 chars of CFI as chapter identifier
        return window.reader.view.location.cfi.substring(0, 60)
      }
    } catch (e) {}
    return 'unknown'
  }

  // Generate a stable path signature based on DOM structure
  #getElementPath(element) {
    const segments = []
    let current = element
    let depth = 0
    while (current && current !== document.body && depth < 15) {
      const tag = current.tagName?.toLowerCase()
      if (tag && !['html', 'body'].includes(tag)) {
        const siblings = Array.from(current.parentElement?.children || [])
          .filter(c => c.tagName === current.tagName && !c.classList.contains('translated-text'))
        const index = siblings.indexOf(current)
        segments.unshift(`${tag}${index >= 0 ? index : ''}`)
      }
      current = current.parentElement
      depth++
    }
    return segments.join('/')
  }

  // Persist cache to Flutter for storage across sessions
  #persistCache() {
    for (const [key, value] of Object.entries(this.#cache)) {
      if (!value || isTranslationFailure(value.translatedText)) {
        delete this.#cache[key]
      }
    }

    // Enforce cache size limit
    const keys = Object.keys(this.#cache)
    if (keys.length > this.#maxCacheSize) {
      const excess = keys.length - this.#maxCacheSize
      for (let i = 0; i < excess; i++) {
        delete this.#cache[keys[i]]
      }
    }

    try {
      if (window.flutter_inappwebview) {
        const cacheJson = JSON.stringify(this.#cache)
        window.flutter_inappwebview.callHandler('saveTranslationCache', {
          namespace: this.#cacheNamespace,
          cacheJson,
        })
      }
    } catch (e) {
      // Silently fail - cache loss is not critical
    }
  }

  // Load cache from Flutter on document ready
  async loadCache({ forceReload = false, resetRendered = false } = {}) {
    if (forceReload) this.#cacheLoadPromise = null
    if (this.#cacheLoadPromise) return this.#cacheLoadPromise

    this.#cacheLoadPromise = (async () => {
      try {
        let namespace = null
        let nextCache = {}

        if (window.flutter_inappwebview) {
          const payload = await window.flutter_inappwebview.callHandler('loadTranslationCache')
          let cacheJson = ''

          if (typeof payload === 'string') {
            cacheJson = payload
          } else if (payload && typeof payload === 'object') {
            namespace = typeof payload.namespace === 'string' ? payload.namespace : null
            cacheJson = typeof payload.cacheJson === 'string' ? payload.cacheJson : ''
          }

          if (cacheJson) {
            const decoded = JSON.parse(cacheJson)
            nextCache = Object.fromEntries(
              Object.entries(decoded || {}).filter(([, value]) =>
                value &&
                typeof value === 'object' &&
                !isTranslationFailure(value.translatedText)
              )
            )
          }
        }

        const namespaceChanged = namespace !== this.#cacheNamespace
        this.#cacheNamespace = namespace
        this.#cache = nextCache

        if (namespaceChanged || resetRendered) {
          this.#resetRenderedTranslations()
        }

        console.log(`Translation cache loaded: ${Object.keys(this.#cache).length} entries`)
        this.#applyCachedTranslations()
      } catch (e) {
        console.warn('Failed to load translation cache:', e)
      }
      return this.#cache
    })()

    return this.#cacheLoadPromise
  }

  #applyTranslation(element, translatedText) {
    if (!this.#isElementConnected(element)) return

    // Remove existing translation if any
    const existingTranslation = this.#findTranslationWrapper(element)
    if (existingTranslation) {
      existingTranslation.remove()
    }

    // Create translation wrapper
    const wrapper = document.createElement('div')
    wrapper.className = 'translated-text'
    wrapper.setAttribute('data-translation-mark', '1')

    // Handle paragraph structure - convert newlines to proper HTML structure
    // Split by double newlines for paragraphs, single newlines for line breaks
    const paragraphs = translatedText.split(/\n\n+/).filter(p => p.trim())

    if (paragraphs.length > 1) {
      // Multiple paragraphs: create separate paragraph elements
      paragraphs.forEach((paraText, index) => {
        if (index > 0) {
          wrapper.appendChild(document.createElement('br'))
        }
        const para = document.createElement('div')
        para.className = 'translated-paragraph'
        // Handle single newlines within paragraphs
        const lines = paraText.split(/\n/).filter(l => l.trim())
        lines.forEach((lineText, lineIndex) => {
          if (lineIndex > 0) {
            para.appendChild(document.createElement('br'))
          }
          const span = document.createElement('span')
          span.textContent = lineText.trim()
          para.appendChild(span)
        })
        wrapper.appendChild(para)
      })
    } else {
      // Single paragraph: handle single newlines as line breaks
      const lines = translatedText.split(/\n/).filter(l => l.trim())
      lines.forEach((lineText, index) => {
        if (index > 0) {
          wrapper.appendChild(document.createElement('br'))
        }
        const span = document.createElement('span')
        span.textContent = lineText.trim()
        wrapper.appendChild(span)
      })
    }

    // Apply based on current mode
    this.#updateElementDisplay(element, wrapper)

    // Insert as sibling after the element, not as child
    element.parentNode.insertBefore(wrapper, element.nextSibling)
  }

  #updateElementDisplay(element, translationWrapper) {
    const data = this.#translatedElements.get(element)
    if (!data) return
    
    switch (this.#translationMode) {
      case TranslationMode.TRANSLATION_ONLY:
        this.#hideOriginalText(element)
        translationWrapper.style.display = 'block'
        break
        
      case TranslationMode.ORIGINAL_ONLY:
        this.#restoreOriginalText(element)
        translationWrapper.style.display = 'none'
        break
        
      case TranslationMode.BILINGUAL:
        this.#restoreOriginalText(element)
        translationWrapper.style.display = 'block'
        break
        
      case TranslationMode.OFF:
      default:
        this.#restoreOriginalText(element)
        translationWrapper.style.display = 'none'
        break
    }
  }

  #hideOriginalText(element) {
    // Use CSS to hide original content instead of removing DOM nodes
    if (!element.hasAttribute('data-original-visibility')) {
      element.setAttribute('data-original-visibility', 'hidden')
      
      // Hide all child nodes except translation elements using CSS
      Array.from(element.childNodes).forEach(node => {
        if (node.nodeType === Node.ELEMENT_NODE) {
          const el = node
          if (!el.classList || !el.classList.contains('translated-text')) {
            // Store and hide using CSS
            if (!el.hasAttribute('data-original-display')) {
              el.setAttribute('data-original-display', el.style.display || 'initial')
              el.style.display = 'none'
            }
          }
        } else if (node.nodeType === Node.TEXT_NODE) {
          // For text nodes, store content and make invisible
          if (!node.__originalContent) {
            node.__originalContent = node.textContent
            node.textContent = ''
          }
        }
      })
    }
    
    // Mark element as having hidden text
    element.classList.add('translation-source-hidden')
  }

  #restoreOriginalText(element) {
    // Restore visibility by reversing the hide operations
    if (element.hasAttribute('data-original-visibility')) {
      // Restore all child nodes
      Array.from(element.childNodes).forEach(node => {
        if (node.nodeType === Node.ELEMENT_NODE) {
          const el = node
          if (!el.classList || !el.classList.contains('translated-text')) {
            // Restore original display
            if (el.hasAttribute('data-original-display')) {
              const originalDisplay = el.getAttribute('data-original-display')
              el.style.display = originalDisplay === 'initial' ? '' : originalDisplay
              el.removeAttribute('data-original-display')
            }
          }
        } else if (node.nodeType === Node.TEXT_NODE) {
          // Restore text content
          if (node.__originalContent !== undefined) {
            node.textContent = node.__originalContent
            delete node.__originalContent
          }
        }
      })
      
      element.removeAttribute('data-original-visibility')
    }
    
    element.classList.remove('translation-source-hidden')
  }

  async #forceTranslateVisibleElements() {
    this.#pruneStaleWork()

    // console.log('Force translating visible elements')

    // Find elements in viewport and queue them for translation
    this.observedElements.forEach(element => {
      const rect = element.getBoundingClientRect()
      const isVisible = rect.top < window.innerHeight && rect.bottom > 0

      if (isVisible && !this.#translatedElements.has(element)) {
        // Queue visible elements for sequential translation
        this.#queueTranslation(element)
      } else if (isVisible && this.#translatedElements.has(element)) {
        // Element already translated, just update display
        const translationWrapper = this.#findTranslationWrapper(element)
        if (translationWrapper) {
          this.#updateElementDisplay(element, translationWrapper)
        }
      }
    })

    // Process the queue and wait for completion
    if (this.#translationQueue.length > 0) {
      // Process all queued items sequentially
      await this.#processQueueAndWait()
    }
  }

  // Process queue completely and wait for all translations
  async #processQueueAndWait() {
    this.#pruneStaleWork()

    this.#isTranslating = true
    const useBatch =
      this.#translationMode === TranslationMode.TRANSLATION_ONLY ||
      this.#translationMode === TranslationMode.BILINGUAL

    try {
      while (this.#translationQueue.length > 0 && this.#translationMode !== TranslationMode.OFF) {
        if (useBatch) {
          // Batch mode: build, sort, translate, apply
          const batch = this.#buildBatch()
          if (batch.length === 0) break
          batch.sort((a, b) => this.#compareDomPosition(a.element, b.element))

          try {
            if (batch.length > 1) {
              const combinedText = batch.map(item => item.text).join(this.#separator)
              const combinedResult = await translate(combinedText)
              const translations = this.#splitBatchResult(combinedResult, batch.length)
              for (let i = 0; i < batch.length; i++) {
                const item = batch[i]
                this.#applyTranslated(item, item.text, translations[i])
              }
            } else {
              const item = batch[0]
              const translatedText = await this.#translateWithRetry(item.text)
              this.#applyTranslated(item, item.text, translatedText)
            }
          } catch (error) {
            // Fallback to individual
            for (const item of batch) {
              try {
                const translatedText = await this.#translateWithRetry(item.text)
                this.#applyTranslated(item, item.text, translatedText)
              } catch (e) {
                console.warn('Translation failed:', e)
                this.#applyTranslationError(item, item.text, e?.message || String(e))
                this.#finishProgressItem(true)
              }
            }
          }
        } else {
          // Individual mode: translate one at a time
          const item = this.#translationQueue.shift()
          if (!item) break
          try {
            const translatedText = await this.#translateWithRetry(item.text)
            this.#applyTranslated(item, item.text, translatedText)
          } catch (e) {
            console.warn('Translation failed:', e)
            this.#applyTranslationError(item, item.text, e?.message || String(e))
            this.#finishProgressItem(true)
          }
        }

        // Delay between batches/individual
        if (this.#translationQueue.length > 0) {
          await new Promise(resolve => setTimeout(resolve, this.#requestDelay))
        }
      }
    } finally {
      this.#isTranslating = false

      if (this.#translationQueue.length > 0 && this.#translationMode !== TranslationMode.OFF) {
        setTimeout(() => this.#processQueue(), this.#requestDelay)
      }
    }
  }

  #updateTranslationDisplay() {
    this.#pruneStaleWork()

    // console.log('Updating translation display for mode:', this.#translationMode, 'Elements:', this.observedElements.size)
    this.observedElements.forEach(element => {
      const translationWrapper = this.#findTranslationWrapper(element)
      if (translationWrapper) {
        // console.log('Updating display for element with translation:', element)
        this.#updateElementDisplay(element, translationWrapper)
      } else {
        // console.log('No translation wrapper found for element:', element)
      }
    })
  }

  // Public method to translate visible elements (called on page/chapter change)
  async translateVisibleElements() {
    if (this.#translationMode === TranslationMode.OFF) return
    await this.#forceTranslateVisibleElements()
  }

  // Translate ONLY the currently visible page elements immediately
  async translateCurrentPage() {
    if (this.#translationMode === TranslationMode.OFF) return

    this.#pruneStaleWork()
    this.#clearQueuedTranslations()

    // Find elements currently in the viewport (no margin buffer)
    const visibleElements = []
    this.observedElements.forEach(element => {
      const rect = element.getBoundingClientRect()
      const isFullyVisible = rect.top >= 0 && rect.bottom <= window.innerHeight
      const isPartiallyVisible = rect.top < window.innerHeight && rect.bottom > 0

      if (isFullyVisible || isPartiallyVisible) {
        visibleElements.push(element)
      }
    })

    // Queue visible elements. #queueTranslation applies cache before scheduling
    // network work, so revisiting a page does not translate it again.
    for (const element of visibleElements) {
      this.#queueTranslation(element)
    }

    // Process the queue immediately
    if (this.#translationQueue.length > 0) {
      await this.#processQueueAndWait()
    }
  }

  // Translate a selected paragraph and insert inline below original
  async translateSelectedParagraph(cfi) {
    console.log('translateSelectedParagraph called, cfi:', cfi)

    await this.loadCache()

    // Find the paragraph element from CFI
    const element = this.#findElementByCfi(cfi)
    console.log('Found element:', element)
    if (!element) {
      console.warn('Could not find element for CFI:', cfi)
      return false
    }

    // Find the paragraph-level parent element
    const paragraphElement = this.#findParagraphParent(element)
    console.log('Found paragraph element:', paragraphElement)
    if (!paragraphElement) {
      console.warn('Could not find paragraph parent')
      return false
    }

    // If already translated, just show the translation
    if (this.#translatedElements.has(paragraphElement)) {
      console.log('Element already translated')
      const wrapper = this.#findTranslationWrapper(paragraphElement)
      if (wrapper) {
        if (wrapper.classList.contains('translated-error')) {
          wrapper.remove()
        } else {
          wrapper.style.display = 'block'
          return true
        }
      }
    }

    // Get text and translate
    const text = paragraphElement.innerText?.trim()
    if (!text) return false

    if (this.#applyCachedTranslation(paragraphElement, text)) {
      const wrapper = this.#findTranslationWrapper(paragraphElement)
      if (wrapper) wrapper.style.display = 'block'
      return true
    }

    try {
      const translatedText = await this.#translateWithRetry(text)
      const cacheData = {
        originalText: text,
        translatedText: translatedText
      }
      this.#translatedElements.set(paragraphElement, cacheData)
      const cacheKey = this.#getCacheKey(paragraphElement)
      if (cacheKey) this.#cache[cacheKey] = cacheData
      this.#applyTranslation(paragraphElement, translatedText)
      this.#schedulePersistCache()
      return true
    } catch (error) {
      console.warn('Translation failed:', error)
      this.#applyTranslationError(
        paragraphElement,
        text,
        error?.message || String(error),
      )
      return false
    }
  }

  // Find element from CFI - prioritize CFI resolution, selection as fallback
  #findElementByCfi(cfi) {
    try {
      // Primary: resolve CFI directly (authoritative identifier)
      if (window.reader && window.reader.view) {
        const view = window.reader.view
        const resolved = view.resolveCFI?.(cfi)
        if (resolved && resolved.anchor) {
          const contents = view.renderer?.getContents?.()
          if (contents && contents.length > 0) {
            const doc = contents[0].doc
            if (doc) {
              const range = resolved.anchor(doc)
              if (range && range.startContainer) {
                return range.startContainer.parentElement
              }
            }
          }
        }
      }

      // Fallback: use current selection (works when selection is still active)
      const selection = window.getSelection()
      if (selection && selection.rangeCount > 0) {
        const range = selection.getRangeAt(0)
        if (range && range.startContainer) {
          return range.startContainer.parentElement
        }
      }
    } catch (e) {
      console.warn('CFI parse error:', e)
    }
    return null
  }

  // Find paragraph-level parent element
  #findParagraphParent(element) {
    const paragraphTags = ['P', 'DIV', 'BLOCKQUOTE', 'LI', 'DD', 'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'SECTION', 'ARTICLE']
    const inlineTags = ['SPAN', 'EM', 'STRONG', 'B', 'I', 'U', 'A', 'FONT', 'MARK', 'SMALL', 'SUB', 'SUP', 'BR']

    let current = element
    while (current && current !== document.body) {
      if (paragraphTags.includes(current.tagName)) {
        // Check if it's a true paragraph (no block-level children)
        const hasBlockChildren = Array.from(current.children).some(c =>
          !inlineTags.includes(c.tagName) && !paragraphTags.includes(c.tagName)
        )
        if (!hasBlockChildren) {
          return current
        }
      }
      current = current.parentElement
    }
    // Fallback: return the original element if no paragraph parent found
    return element
  }

  destroy() {
    this.clearTranslations()
    this.#observer = null
  }
}
