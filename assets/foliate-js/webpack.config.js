const path = require('path');

module.exports = {
  entry: {
    bundle: ['core-js/stable', './src/book.js'],
    'pdf-legacy': './src/vendor/pdfjs/pdf.js',
    'pdf-legacy.worker': './src/vendor/pdfjs/pdf.worker.js'
  },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, 'dist'),
    // Use compatible module format for legacy browsers
    library: {
      name: 'FoliateJS',
      type: 'umd',
      export: 'default'
    },
    globalObject: '(typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : typeof global !== "undefined" ? global : this)'
  },
  mode: 'production',
  target: ['web', 'es5'], // Target ES5 for legacy browser compatibility
  optimization: {
    splitChunks: false,
    runtimeChunk: false,
    minimize: true
  },
  performance: {
    hints: false
  },
  experiments: {
    outputModule: false
  },
  resolve: {
    alias: {
      // Use legacy PDF.js build
      'pdfjs-dist': path.resolve(__dirname, 'src/vendor/pdfjs/pdf-legacy.js')
    },
    fallback: {
      // Disable Node.js polyfills for browser build
      "fs": false,
      "zlib": false,
      "http": false,
      "https": false,
      "url": false,
      "canvas": false,
      "util": false,
      "stream": false,
      "buffer": false,
      "crypto": false,
      "os": false,
      "path": false
    }
  },
  module: {
    parser: {
      javascript: {
        dynamicImportMode: 'eager'
      }
    },
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: [
              ['@babel/preset-env', {
                targets: {
                  // Android 11 e-ink devices can ship a fixed Chrome 83 WebView.
                  chrome: '83',
                  android: '11',
                },
                useBuiltIns: 'entry',
                corejs: 3,
                modules: 'auto',
                bugfixes: true
              }]
            ],
            plugins: [
              ['@babel/plugin-transform-runtime', {
                regenerator: true,
                corejs: false,
                helpers: true,
                useESModules: false
              }],
              '@babel/plugin-transform-class-properties',
              '@babel/plugin-transform-private-methods',
              '@babel/plugin-transform-nullish-coalescing-operator',
              '@babel/plugin-transform-logical-assignment-operators',
              '@babel/plugin-transform-optional-chaining'
            ]
          }
        }
      }
    ]
  }
};
