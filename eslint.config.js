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
      // Add any project-specific rule overrides here
      // e.g., '@typescript-eslint/no-explicit-any': 'warn',
    },
  }
);
