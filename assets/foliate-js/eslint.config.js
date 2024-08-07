import js from '@eslint/js'
import globals from 'globals'

export default [js.configs.recommended, { ignores: ['vendor'] }, {
    languageOptions: {
        globals: globals.browser,
    },
    linterOptions: {
        reportUnusedDisableDirectives: true,
    },
    rules: {
        semi: ['error', 'never'],
        indent: ['warn', 4, { flatTernaryExpressions: true, SwitchCase: 1 }],
        quotes: ['warn', 'single', { avoidEscape: true }],
        'comma-dangle': ['warn', 'always-multiline'],
        'no-trailing-spaces': 'warn',
        'no-unused-vars': 'warn',
        'no-console': ['warn', { allow: ['debug', 'warn', 'error', 'assert'] }],
        'no-constant-condition': ['error', { checkLoops: false }],
        'no-empty': ['error', { allowEmptyCatch: true }],
    },
}]
