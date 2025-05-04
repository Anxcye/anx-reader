const path = require('path');

module.exports = {
  entry: './src/book.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist')
  },
  mode: 'production',
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
  module: {
    parser: {
      javascript: {
        dynamicImportMode: 'eager'
      }
    }
  }
};