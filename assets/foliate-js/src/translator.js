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

// Mock translation function - returns fixed Chinese text
const mockTranslate = async (text) => {
  // Simulate API delay
  await new Promise(resolve => setTimeout(resolve, 100))
  return `【翻译】${text.substring(0, 20)}...的中文翻译内容`
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
        console.log(`IntersectionObserver triggered with ${entries.length} entries`)
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            console.log('Element intersecting, translating:', entry.target.tagName, entry.target.textContent?.substring(0, 30))
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

  setTranslationMode(mode) {
    if (!Object.values(TranslationMode).includes(mode)) {
      console.warn(`Invalid translation mode: ${mode}`)
      return
    }
    
    const oldMode = this.#translationMode
    this.#translationMode = mode
    
    if (oldMode !== mode) {
      console.log(`Translation mode changed from ${oldMode} to ${mode}`)
      
      if (mode === TranslationMode.OFF) {
        // Turn off translation
        this.#updateTranslationDisplay()
      } else if (oldMode === TranslationMode.OFF) {
        // Turn on translation - force translate visible elements
        this.#forceTranslateVisibleElements()
      } else {
        // Just update display mode
        this.#updateTranslationDisplay()
      }
    }

    // Re-render annotations after translation mode change
    if (window.reader && window.reader.annotationsByValue) {
      const existingAnnotations = Array.from(window.reader.annotationsByValue.values())
      if (existingAnnotations.length > 0) {
        console.log('Re-rendering annotations after translation mode change:', existingAnnotations.length)
        window.renderAnnotations(existingAnnotations)
      }
    }
  }

  getTranslationMode() {
    return this.#translationMode
  }

  observeDocument(doc) {
    console.log('Observing document for translation, doc:', doc)
    if (!doc) {
      console.warn('No document provided to observeDocument')
      return
    }
        
    const textElements = this.#walkTextNodes(doc.body || doc.documentElement)
    console.log(`Found ${textElements.length} text elements to observe`)
    
    textElements.forEach(element => {
      if (!this.observedElements.has(element)) {
        this.#observer.observe(element)
        this.observedElements.add(element)
        console.log('Added element to observer:', element.tagName, element.textContent?.substring(0, 50))
      }
    })
    
    console.log(`Total observed elements: ${this.observedElements.size}`)
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
    
    const text = element.textContent?.trim()
    if (!text) return
    
    try {
      const translatedText = await mockTranslate(text)
      
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
    wrapper.style.fontSize = '0.9em'
    wrapper.style.color = '#666'
    wrapper.style.fontStyle = 'italic'
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
    // Store the complete innerHTML and hide all original content
    if (!element.hasAttribute('data-original-html')) {
      // Store the original HTML content (excluding any existing translations)
      const originalChildren = Array.from(element.childNodes).filter(node => {
        return !(node.nodeType === Node.ELEMENT_NODE && 
                node.classList && node.classList.contains('translated-text'))
      })
      
      const originalHTML = originalChildren.map(node => {
        if (node.nodeType === Node.ELEMENT_NODE) {
          return node.outerHTML
        } else if (node.nodeType === Node.TEXT_NODE) {
          return node.textContent
        }
        return ''
      }).join('')
      
      element.setAttribute('data-original-html', originalHTML)
      
      // Remove all original content (but keep translations)
      originalChildren.forEach(node => {
        if (node.parentNode === element) {
          element.removeChild(node)
        }
      })
    }
    
    // Mark element as having hidden text
    element.classList.add('translation-source-hidden')
  }

  #restoreOriginalText(element) {
    // Restore the original HTML content
    if (element.hasAttribute('data-original-html')) {
      const originalHTML = element.getAttribute('data-original-html')
      
      // First, collect all translation elements to preserve them
      const translationElements = Array.from(element.querySelectorAll('.translated-text'))
      const translationHTMLs = translationElements.map(el => el.outerHTML)
      
      // Clear the element and restore original content
      element.innerHTML = originalHTML
      
      // Re-add the translation elements
      translationHTMLs.forEach(html => {
        const tempDiv = document.createElement('div')
        tempDiv.innerHTML = html
        const translationEl = tempDiv.firstChild
        if (translationEl) {
          element.appendChild(translationEl)
        }
      })
      
      element.removeAttribute('data-original-html')
    }
    
    element.classList.remove('translation-source-hidden')
  }

  #forceTranslateVisibleElements() {
    console.log('Force translating visible elements')
    
    // Find elements in viewport and translate them immediately
    this.observedElements.forEach(element => {
      const rect = element.getBoundingClientRect()
      const isVisible = rect.top < window.innerHeight && rect.bottom > 0
      
      if (isVisible && !this.#translatedElements.has(element)) {
        console.log('Force translating visible element:', element)
        this.#translateElement(element).catch(error => 
          console.warn('Force translation failed:', error)
        )
      } else if (isVisible && this.#translatedElements.has(element)) {
        // Element already translated, just update display
        const translationWrapper = element.querySelector('.translated-text')
        if (translationWrapper) {
          this.#updateElementDisplay(element, translationWrapper)
        }
      }
    })
  }

  #updateTranslationDisplay() {
    console.log('Updating translation display for mode:', this.#translationMode, 'Elements:', this.observedElements.size)
    this.observedElements.forEach(element => {
      const translationWrapper = element.querySelector('.translated-text')
      if (translationWrapper) {
        console.log('Updating display for element with translation:', element)
        this.#updateElementDisplay(element, translationWrapper)
      } else {
        console.log('No translation wrapper found for element:', element)
      }
    })
  }

  destroy() {
    this.clearTranslations()
    this.#observer = null
  }
}