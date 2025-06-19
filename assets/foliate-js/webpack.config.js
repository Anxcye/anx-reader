const path = require('path');

module.exports = {
  entry: {
    bundle: './src/book.js',
    'pdf-legacy': './src/vendor/pdfjs/pdf.js',
    'pdf-legacy.worker': './src/vendor/pdfjs/pdf.worker.js'
  },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, 'dist'),
    // Use compatible module format for legacy browsers
    library: {
      name: 'FoliateJS',
      type: 'umd'
    },
    globalObject: 'window'
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
        exclude: [
          /node_modules/,
          /src\/vendor\/pdfjs\/pdf\.js$/, // Exclude large PDF.js file from Babel processing
          /src\/vendor\/pdfjs\/pdf\.worker\.js$/
        ],
        use: {
          loader: 'babel-loader',
          options: {
            presets: [
              ['@babel/preset-env', {
                targets: {
                  // Target older Android WebView versions
                  android: '4.4',
                  chrome: '30',
                  safari: '9'
                },
                useBuiltIns: 'entry',
                corejs: 3,
                modules: 'auto'
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
              '@babel/plugin-transform-optional-chaining'
            ]
          }
        }
      }
    ]
  }
};