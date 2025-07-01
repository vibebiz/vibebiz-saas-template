module.exports = {
  root: true,
  env: {
    node: true,
    jest: true,
    es2022: true,
  },
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    // Allow console.log in tests for debugging
    'no-console': 'off',
    // Allow unused vars with underscore prefix
    'no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
        varsIgnorePattern: '^_',
        ignoreRestSiblings: true,
      },
    ],
    // Fix useless escape characters
    'no-useless-escape': 'error',
  },
  globals: {
    // Cross-cutting test utilities global
    crossCuttingTestUtils: 'readonly',
    // Jest globals
    describe: 'readonly',
    it: 'readonly',
    test: 'readonly',
    expect: 'readonly',
    beforeAll: 'readonly',
    afterAll: 'readonly',
    beforeEach: 'readonly',
    afterEach: 'readonly',
    jest: 'readonly',
    // Node.js globals
    global: 'readonly',
    process: 'readonly',
    Buffer: 'readonly',
    // Browser globals for E2E tests
    fetch: 'readonly',
    performance: 'readonly',
  },
  overrides: [
    {
      // TypeScript files
      files: ['**/*.ts'],
      parser: '@typescript-eslint/parser',
      plugins: ['@typescript-eslint'],
      extends: ['eslint:recommended', '@typescript-eslint/recommended'],
      rules: {
        '@typescript-eslint/no-unused-vars': [
          'error',
          {
            argsIgnorePattern: '^_',
            varsIgnorePattern: '^_',
            ignoreRestSiblings: true,
          },
        ],
        '@typescript-eslint/no-explicit-any': 'off',
      },
    },
    {
      // Playwright specific globals for E2E tests
      files: ['**/e2e/**/*.{ts,js}', '**/accessibility/**/*.{ts,js}'],
      globals: {
        page: 'readonly',
        browser: 'readonly',
        context: 'readonly',
      },
    },
  ],
};
