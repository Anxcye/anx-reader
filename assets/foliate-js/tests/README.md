# Selection interaction regression

Run from the repository root:

```sh
node assets/foliate-js/tests/run-selection-browser.cjs
```

The runner uses Node's built-in HTTP server and an installed Chrome/Chromium
binary. Set `BROWSER_BINARY` when it is outside the usual macOS/Linux paths.
No additional npm dependencies are required. Open `selection-range.html` through
a local HTTP server to inspect the same real DOM Range/Selection fixture manually.

These checks cover range algorithms, explicit extension and rollback, stale
operation rejection, layout guards and synthetic touch event arbitration.
They do not replace Android WebView native-handle or physical E-INK testing.
