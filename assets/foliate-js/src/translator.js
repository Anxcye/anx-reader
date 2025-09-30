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

// Translation function that calls Flutter's translation service
const translate = async (text) => {
  try {
    // Call Flutter's translation handler
      const result = await window.flutter_inappwebview.callHandler('translateText', text)
      return result || `Translation failed: ${text}`
  } catch (error) {
    console.error('Translation failed:', error)
    return `Translation error: ${text}`
  }
}

export class Translator {
  #translationMode = TranslationMode.OFF
  observedElements = new Set()
  #translatedElements = new WeakMap()
  #observer = null
  
  constructor() {
    this.#initializeObserver()
  }

  #initializeObserver() {
    this.#observer = new IntersectionObserver(
      (entries) => {
        // console.log(`IntersectionObserver triggered with ${entries.length} entries`)
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            // console.log('Element intersecting, translating:', entry.target.tagName, entry.target.textContent?.substring(0, 30))
            this.#translateElement(entry.target).catch(error => 
              console.warn('Translation failed in observer:', error)
            )
          }
        })
      },
      {
        rootMargin: '1280px',
        threshold: 0
      }
    )
  }

  async setTranslationMode(mode) {
    if (!Object.values(TranslationMode).includes(mode)) {
      console.warn(`Invalid translation mode: ${mode}`)
      return
    }
    
    const oldMode = this.#translationMode
    this.#translationMode = mode
    
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

  getTranslationMode() {
    return this.#translationMode
  }

  observeDocument(doc) {
    // console.log('Observing document for translation, doc:', doc)
    if (!doc) {
      console.warn('No document provided to observeDocument')
      return
    }
        
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
  }

  clearTranslations() {
    // Remove all translation elements and restore original content
    this.observedElements.forEach(element => {
      const translationElements = element.querySelectorAll('.translated-text')
      translationElements.forEach(trans => trans.remove())
      
      // Restore original text if hidden
      this.#restoreOriginalText(element)
    })
    
    // Clear observer
    this.#observer.disconnect()
    this.observedElements.clear()
    this.#translatedElements = new WeakMap()
    
    // Reinitialize observer
    this.#initializeObserver()
  }

  #walkTextNodes(root, rejectTags = ['pre', 'code', 'math', 'style', 'script']) {
    const elements = []
    
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
        
        const hasDirectText = Array.from(child.childNodes).some(node => {
          if (node.nodeType === Node.TEXT_NODE && node.textContent?.trim()) {
            return true
          }
          if (node.nodeType === Node.ELEMENT_NODE && node.tagName === 'SPAN') {
            return true
          }
          return false
        })
        
        if (child.children.length === 0 && child.textContent?.trim()) {
          elements.push(child)
        } else if (hasDirectText) {
          elements.push(child)
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
    
    try {
      const translatedText = await translate(text)
      
      // Mark as translated to prevent re-processing
      this.#translatedElements.set(element, {
        originalText: text,
        translatedText: translatedText
      })
      
      this.#applyTranslation(element, translatedText)
    } catch (error) {
      console.warn('Translation failed:', error)
    }
  }

  #applyTranslation(element, translatedText) {
    // Remove existing translation if any
    const existingTranslation = element.querySelector('.translated-text')
    if (existingTranslation) {
      existingTranslation.remove()
    }
    
    // Create translation wrapper
    const wrapper = document.createElement('span')
    wrapper.className = 'translated-text'
    wrapper.setAttribute('data-translation-mark', '1')
    wrapper.style.display = 'block'
    // wrapper.style.fontSize = '0.9em'
    // wrapper.style.color = '#666'
    // wrapper.style.fontStyle = 'italic'
    wrapper.style.marginTop = '0.2em'
    wrapper.textContent = translatedText
    
    // Apply based on current mode
    this.#updateElementDisplay(element, wrapper)
    
    element.appendChild(wrapper)
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
    // console.log('Force translating visible elements')
    
    const translationPromises = []
    
    // Find elements in viewport and translate them immediately
    this.observedElements.forEach(element => {
      const rect = element.getBoundingClientRect()
      const isVisible = rect.top < window.innerHeight && rect.bottom > 0
      
      if (isVisible && !this.#translatedElements.has(element)) {
        // console.log('Force translating visible element:', element)
        const translationPromise = this.#translateElement(element).catch(error => {
          console.warn('Force translation failed:', error)
        })
        translationPromises.push(translationPromise)
      } else if (isVisible && this.#translatedElements.has(element)) {
        // Element already translated, just update display
        const translationWrapper = element.querySelector('.translated-text')
        if (translationWrapper) {
          this.#updateElementDisplay(element, translationWrapper)
        }
      }
    })
    
    // Wait for all visible translations to complete
    if (translationPromises.length > 0) {
      // console.log(`Waiting for ${translationPromises.length} translations to complete`)
      await Promise.allSettled(translationPromises)
      // console.log('All visible translations completed')
    }
  }

  #updateTranslationDisplay() {
    // console.log('Updating translation display for mode:', this.#translationMode, 'Elements:', this.observedElements.size)
    this.observedElements.forEach(element => {
      const translationWrapper = element.querySelector('.translated-text')
      if (translationWrapper) {
        // console.log('Updating display for element with translation:', element)
        this.#updateElementDisplay(element, translationWrapper)
      } else {
        // console.log('No translation wrapper found for element:', element)
      }
    })
  }

  destroy() {
    this.clearTranslations()
    this.#observer = null
  }
}