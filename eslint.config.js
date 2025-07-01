// @ts-check

import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import securityPlugin from 'eslint-plugin-security';
import globals from 'globals';

export default tseslint.config(
  // Global ignores
  { ignores: ['dist/**', 'node_modules/**', '.turbo/**'] },

  // Base configuration for all JS/TS files
  {
    files: ['**/*.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
    linterOptions: {
      reportUnusedDisableDirectives: true,
    },
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.es2021,
        ...globals.jest,
      },
    },
  },

  // ESLint recommended rules
  eslint.configs.recommended,

  // Security plugin recommended rules
  securityPlugin.configs.recommended,

  // TypeScript specific configurations
  ...tseslint.configs.recommended,

  // Project-specific rules (can be customized)
  {
    rules: {
      // TypeScript strict rules for production
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unused-vars': 'error',
      '@typescript-eslint/no-non-null-assertion': 'warn',

      // Security and best practices
      'no-debugger': 'error',
      'prefer-const': 'error',
    },
  },

  // Stricter rules for production source code
  {
    files: [
      'src/**/*.{js,ts,tsx}',
      '!src/**/*.test.{js,ts,tsx}',
      '!src/**/*.spec.{js,ts,tsx}',
    ],
    rules: {
      '@typescript-eslint/explicit-function-return-type': 'warn',
      'no-console': 'warn',
    },
  },

  // Relaxed rules for test files and configuration
  {
    files: [
      '**/*.test.{js,ts,tsx}',
      '**/*.spec.{js,ts,tsx}',
      '**/test*.{js,ts}',
      '**/*config*.{js,ts}',
      '**/jest.setup.js',
      '**/conftest.py',
    ],
    rules: {
      '@typescript-eslint/explicit-function-return-type': 'off',
      'no-console': 'off',
      '@typescript-eslint/no-require-imports': 'off',
    },
  }
);
