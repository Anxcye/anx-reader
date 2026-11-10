// Real DOM Range / Selection verification; requires a local Chrome/Chromium binary.
const http = require('node:http')
const fs = require('node:fs')
const path = require('node:path')
const os = require('node:os')
const { execFile } = require('node:child_process')
const { promisify } = require('node:util')

;(async () => {
  const root = path.resolve(__dirname, '..')
  const candidates = [process.env.BROWSER_BINARY, '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', '/usr/bin/chromium', '/usr/bin/chromium-browser', '/usr/bin/google-chrome'].filter(Boolean)
  const browser = candidates.find(file => fs.existsSync(file))
  if (!browser) throw Error('Set BROWSER_BINARY to a local Chrome/Chromium executable')
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'anx-selection-'))
  const server = http.createServer((request, response) => {
    const pathname = new URL(request.url, 'http://localhost').pathname
    const file = path.resolve(root, '.' + decodeURIComponent(pathname))
    if (!file.startsWith(root + path.sep)) { response.writeHead(403).end(); return }
    fs.readFile(file, (error, data) => {
      if (error) { response.writeHead(404).end(); return }
      response.setHeader('Content-Type', file.endsWith('.js') ? 'text/javascript' : 'text/html')
      response.end(data)
    })
  })
  try {
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve))
    const port = server.address().port
    const { stdout } = await promisify(execFile)(browser, ['--headless', '--disable-gpu', '--no-first-run', '--no-default-browser-check', `--user-data-dir=${profile}`, '--virtual-time-budget=6000', '--dump-dom', `http://127.0.0.1:${port}/tests/selection-range.html`], { timeout: 30000, maxBuffer: 2 * 1024 * 1024 })
    const match = stdout.match(/<pre id="results">([\s\S]*?)<\/pre>/)
    if (!match) throw Error('Browser did not return fixture results')
    const json = match[1].replace(/&quot;/g, '"').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&')
    const result = JSON.parse(json)
    for (const item of result.results) if (!item.passed) console.error(`${item.name}: ${item.error}`)
    console.log(`Selection browser tests: ${result.passed} passed, ${result.failed} failed`)
    if (result.failed) process.exitCode = 1
  } finally {
    await new Promise(resolve => server.close(resolve))
    fs.rmSync(profile, { recursive: true, force: true })
  }
})().catch(error => { console.error(error); process.exitCode = 1 })
