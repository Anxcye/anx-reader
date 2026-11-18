const clamp = (value, min, max) => Math.min(max, Math.max(min, value))
const mix = (from, to, t) => from + (to - from) * t

// Clip a sheet against a line in fold coordinates (s is normal to the crease).
const clip = (points, distance, keepAbove) => {
  const inside = p => keepAbove ? p.s >= distance : p.s <= distance
  return points.flatMap((point, index) => {
    const prev = points[(index + points.length - 1) % points.length]
    const result = []
    if (inside(prev) !== inside(point)) {
      const t = (distance - prev.s) / (point.s - prev.s)
      result.push({ s: distance, u: mix(prev.u, point.u, t) })
    }
    if (inside(point)) result.push(point)
    return result
  })
}

export function curlGeometry(width, height, direction, bottom, distance, lift) {
  const corner = { x: direction > 0 ? width : 0, y: bottom ? height : 0 }
  const dx = direction * clamp(distance, 0.01, 2 * width + 2)
  const dy = (bottom ? 1 : -1) * clamp(lift, -height / 4, height)
  const length = Math.hypot(dx, dy)
  const nx = dx / length
  const ny = dy / length
  const progress = Math.min(1, Math.abs(dx) / (2 * width))
  const radius = Math.min(length / 8, width * 0.075, width * (1 - progress) * 0.35)
  const arc = Math.PI * radius
  const creaseDistance = (length + arc) / 2
  const cx = corner.x - nx * creaseDistance
  const cy = corner.y - ny * creaseDistance
  const sheet = [[0, 0], [width, 0], [width, height], [0, height]]
    .map(([x, y]) => ({
      s: (x - cx) * nx + (y - cy) * ny,
      u: (y - cy) * nx - (x - cx) * ny,
    }))

  // Wrap the sheet around a half cylinder, then extend the back tangentially.
  // Perspective scales along the fold, keeping the pulled corner under the finger.
  const perspective = Math.max(width, height) * 2
  const project = ({ s, u }) => {
    const curved = s > 0 && s < arc
    const angle = curved ? s / radius : 0
    const offset = curved ? radius * Math.sin(angle) : s <= 0 ? s : arc - s
    const depth = curved ? radius * (1 - Math.cos(angle)) : s > 0 ? 2 * radius : 0
    const tangent = u * perspective / (perspective - depth)
    return { x: cx + offset * nx - tangent * ny, y: cy + offset * ny + tangent * nx }
  }
  const bend = (points, cuts) => points.flatMap((point, index) => {
    const next = points[(index + 1) % points.length]
    const stops = cuts.filter(s => s > Math.min(point.s, next.s) && s < Math.max(point.s, next.s))
    if (next.s < point.s) stops.reverse()
    return [project(point), ...stops.map(s => project({
      s, u: mix(point.u, next.u, (s - point.s) / (next.s - point.s)),
    }))]
  })
  const crown = arc / 2
  return {
    tip: project({ s: creaseDistance, u: 0 }),
    front: clip(sheet, 0, false).map(project),
    bend: bend(clip(clip(sheet, 0, true), crown, false), [crown / 3, 2 * crown / 3]),
    back: bend(clip(sheet, crown, true), [4 * arc / 6, 5 * arc / 6, arc]),
    exposed: clip(sheet, 0, true).map(({ s, u }) => ({
      x: cx + nx * s - ny * u, y: cy + ny * s + nx * u,
    })),
    angle: Math.atan2(ny, nx),
    crease: { x: cx, y: cy },
    radius,
    progress,
  }
}

export function shouldCommitCurl(distance, width, velocity) {
  return velocity > -0.35 && (distance >= width * 0.33
    || (distance >= Math.min(24, width * 0.08) && velocity > 0.45))
}

const layer = () => {
  const element = document.createElement('div')
  Object.assign(element.style, { position: 'absolute', inset: '0' })
  return element
}

const setPolygon = (element, points) => {
  const polygon = points.length < 3 ? 'polygon(0 0, 0 0, 0 0)' : 'polygon('
    + points.map(({ x, y }) => x.toFixed(2) + 'px ' + y.toFixed(2) + 'px').join(',') + ')'
  element.style.clipPath = polygon
  element.style.webkitClipPath = polygon
}

const gradient = (element, angle, position, width, height, stops) => {
  const nx = Math.cos(angle)
  const ny = Math.sin(angle)
  const origin = (position.x - width / 2) * nx + (position.y - height / 2) * ny
    + (width * Math.abs(nx) + height * Math.abs(ny)) / 2
  element.style.backgroundImage = 'linear-gradient(' + (angle + Math.PI / 2) + 'rad, '
    + stops.map(([color, offset]) => color + ' ' + (origin + offset).toFixed(2) + 'px').join(',') + ')'
}

// Keep the expensive document clone attached to a single iframe for the whole
// chapter. Only viewport offsets, polygons and lighting change during a turn.
export class PageCurlController {
  #layer
  #front = layer()
  #fold = layer()
  #back = layer()
  #shadow = layer()
  #snapshot
  #ready = false
  #loadTimer
  #overlayObserver
  #active
  #frame = 0
  #resolve
  #onFail
  #context
  #retryTimer
  #attempts = 0
  constructor(element, onFail = null) {
    this.#layer = element
    this.#onFail = onFail
    this.#front.style.overflow = 'hidden'
    this.#front.append(layer())
    this.#layer.append(this.#shadow, this.#front, this.#fold, this.#back)
  }
  prepare({ doc, iframe, overlay }) {
    // A new chapter (or a relayout into a different document) gets a fresh
    // retry budget; retries only accumulate within the same document.
    if (this.#context && this.#context.doc !== doc) this.#attempts = 0
    this.invalidate()
    this.#context = { doc, iframe, overlay }
    if (!doc?.head || !doc.body || !('srcdoc' in iframe)
        || !globalThis.CSS?.supports('inset', '0')
        || !globalThis.CSS.supports('clip-path', 'polygon(0 0, 100% 0, 0 100%)')) return

    const { width, height } = iframe.getBoundingClientRect()
    if (!(width > 0 && height > 0)) return
    const html = doc.documentElement.cloneNode(true)
    html.querySelectorAll('script, iframe, frame, object, embed, meta[http-equiv="refresh" i], base')
      .forEach(node => node.remove())
    const base = doc.createElement('base')
    base.href = doc.baseURI
    html.querySelector('head').prepend(base)
    html.querySelectorAll('img[loading="lazy"]').forEach(img => img.loading = 'eager')

    const frame = document.createElement('iframe')
    frame.setAttribute('sandbox', 'allow-same-origin')
    frame.setAttribute('aria-hidden', 'true')
    frame.setAttribute('part', 'filter')
    frame.setAttribute('scrolling', 'no')
    frame.tabIndex = -1
    Object.assign(frame.style, {
      position: 'absolute', top: '0', left: '0', border: '0',
      width: width + 'px', height: height + 'px',
    })
    const snapshot = { frame, width, height, overlay: null }
    this.#snapshot = snapshot
    const syncOverlay = () => {
      snapshot.overlay?.remove()
      snapshot.overlay = overlay?.cloneNode(true)
      if (snapshot.overlay) {
        Object.assign(snapshot.overlay.style, {
          left: '0', top: '0', width: width + 'px', height: height + 'px',
        })
        this.#front.append(snapshot.overlay)
        this.#positionSnapshot(this.#active?.offset ?? 0)
      }
    }
    syncOverlay()
    if (overlay) {
      this.#overlayObserver = new MutationObserver(syncOverlay)
      this.#overlayObserver.observe(overlay, {
        attributes: true, childList: true, subtree: true,
      })
    }

    const timeout = this.#loadTimer = setTimeout(() => {
      if (this.#snapshot === snapshot) this.#fail()
    }, 5000)
    frame.addEventListener('load', async () => {
      if (this.#snapshot !== snapshot) return
      try {
        const copy = frame.contentDocument
        if (!copy?.body || !copy.querySelector('base')) throw new Error('Snapshot did not load')
        // Force the copy's first layout before awaiting font loads.
        if (!copy.documentElement.scrollWidth) throw new Error('Snapshot has no layout')
        await Promise.all([
          copy.fonts?.ready,
          doc.fonts?.ready,
          ...Array.from(copy.images, (img, i) => img.decode?.().catch(error => {
            // Preserve the original fallback for already broken images.
            if (doc.images[i]?.naturalWidth) throw error
          })),
        ])
        if (this.#snapshot !== snapshot) return
        if (Math.abs(copy.documentElement.scrollWidth - doc.documentElement.scrollWidth) > 2)
          throw new Error('Snapshot pagination differs')
        this.#ready = true
        this.#attempts = 0
      } catch {
        if (this.#snapshot === snapshot) this.#fail()
      } finally {
        clearTimeout(timeout)
      }
    }, { once: true })
    frame.srcdoc = '<!doctype html>' + html.outerHTML
    this.#front.insertBefore(frame, snapshot.overlay ?? null)
  }
  #positionSnapshot(offset) {
    const { frame, overlay } = this.#snapshot
    const transform = 'translate3d(' + offset + 'px, 0, 0)'
    frame.style.transform = transform
    if (overlay) overlay.style.transform = transform
  }
  begin({ width, height, offset, direction, bottom, background, paper, dark }) {
    if (!this.#ready || !this.#snapshot || this.#active || ![width, height, offset].every(Number.isFinite)
        || width < 32 || height < 32 || Math.abs(this.#snapshot.height - height) > 2
        || offset > 1 || width - offset > this.#snapshot.width + 2) return false
    this.#active = { width, height, offset, direction, bottom, dark, distance: 0, lift: 0 }
    const surface = this.#front.firstElementChild
    const backplate = background.cloneNode(false)
    backplate.removeAttribute('id')
    backplate.style.width ||= '100%'
    backplate.style.height ||= '100%'
    surface.append(backplate)
    surface.style.backgroundColor = paper
    this.#fold.style.backgroundColor = paper
    this.#back.style.backgroundColor = paper
    this.#positionSnapshot(offset)
    return true
  }
  update(distance, lift) {
    if (!this.#active) return
    Object.assign(this.#active, { distance, lift })
    if (!this.#frame) {
      this.#frame = requestAnimationFrame(() => {
        this.#frame = 0
        this.#paint()
      })
    }
  }
  #paint() {
    const { width, height, direction, bottom, distance, lift, dark } = this.#active
    const shape = curlGeometry(width, height, direction, bottom, distance, lift)
    this.#layer.style.visibility = 'visible'
    setPolygon(this.#front, shape.front)
    setPolygon(this.#fold, shape.bend)
    setPolygon(this.#back, shape.back)
    setPolygon(this.#shadow, shape.exposed)
    const { angle, crease, radius, progress } = shape
    const shade = Math.min(1, (radius + 10 * progress) / 12)
    gradient(this.#shadow, angle, crease, width, height, [
      ['rgba(0,0,0,' + (0.34 * shade) + ')', 0],
      ['transparent', Math.max(1, radius * 2.6)],
    ])
    gradient(this.#fold, angle, crease, width, height, [
      ['transparent', 0],
      ['rgba(0,0,0,0.32)', radius],
    ])
    gradient(this.#back, angle, crease, width, height, [
      [dark ? 'rgba(255,255,255,0.12)' : 'rgba(110,76,34,0.12)', -radius * 4],
      ['rgba(0,0,0,0.22)', -radius * 0.4],
      [dark ? 'rgba(255,255,255,0.18)' : 'rgba(255,255,255,0.65)', radius * 0.55],
      ['rgba(0,0,0,0.24)', radius],
    ])
  }
  paintNow(distance, lift) {
    if (!this.#active) return
    cancelAnimationFrame(this.#frame)
    this.#frame = 0
    Object.assign(this.#active, { distance, lift })
    this.#paint()
  }
  settle(commit) {
    if (!this.#active) return Promise.resolve(false)
    const { distance, lift, width } = this.#active
    const target = commit ? 2 * width + 2 : 0
    const duration = commit ? 330 : 220
    cancelAnimationFrame(this.#frame)
    return new Promise(resolve => {
      this.#resolve = resolve
      let start
      let done = false
      const finish = value => {
        if (done) return
        done = true
        clearTimeout(watchdog)
        this.#frame = 0
        this.#resolve = null
        resolve(value)
      }
      // requestAnimationFrame is throttled or fully paused in hidden WebViews;
      // a stalled settle must still complete, or the whole turn wedges shut.
      const watchdog = setTimeout(() => {
        if (!this.#active) return finish(false)
        Object.assign(this.#active, { distance: target, lift: 0 })
        this.#paint()
        finish(true)
      }, duration + 600)
      const step = now => {
        if (done) return
        start ??= now
        const t = Math.min(1, (now - start) / duration)
        const eased = 1 - (1 - t) ** 2
        const nextDistance = mix(distance, target, eased)
        const nextLift = mix(lift, 0, eased)
          + (commit && distance === 0 ? Math.sin(Math.PI * t) * Math.min(width * 0.26, 130) : 0)
        Object.assign(this.#active, { distance: nextDistance, lift: nextLift })
        this.#paint()
        if (t < 1) this.#frame = requestAnimationFrame(step)
        else finish(true)
      }
      this.#frame = requestAnimationFrame(step)
    })
  }
  end() {
    cancelAnimationFrame(this.#frame)
    this.#frame = 0
    this.#layer.style.visibility = 'hidden'
    this.#front.firstElementChild.textContent = ''
    this.#active = null
    this.#resolve?.(false)
    this.#resolve = null
  }
  // Snapshot failed to load or validate: drop it and ask the paginator for a
  // fresh prepare attempt, so a slow device (fonts/images over 5s) can recover
  // instead of silently losing curl for the whole chapter.
  #fail() {
    clearTimeout(this.#loadTimer)
    const canRetry = this.#attempts < 3 && this.#onFail
    this.invalidate()
    if (!canRetry) return
    this.#attempts++
    clearTimeout(this.#retryTimer)
    this.#retryTimer = setTimeout(() => this.#onFail?.(), 1200)
  }
  invalidate() {
    this.end()
    clearTimeout(this.#loadTimer)
    clearTimeout(this.#retryTimer)
    this.#overlayObserver?.disconnect()
    this.#overlayObserver = null
    this.#snapshot?.frame.remove()
    this.#snapshot?.overlay?.remove()
    this.#snapshot = null
    this.#ready = false
  }
}
