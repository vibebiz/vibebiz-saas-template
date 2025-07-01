/** @type {import('jest').Config} */
module.exports = {
  // Root configuration for the VibeBiz monorepo
  preset: 'ts-jest',
  testEnvironment: 'node',

  // Projects configuration for monorepo
  projects: [
    '<rootDir>/apps/*/jest.config.js',
    '<rootDir>/packages/*/jest.config.js',
    '<rootDir>/tests/jest.config.mjs', // Cross-cutting tests
  ],

  // Coverage configuration
  collectCoverageFrom: [
    'src/**/*.{ts,tsx,js,jsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.{ts,tsx}',
    '!src/**/*.config.{ts,js}',
    '!src/**/index.{ts,tsx}',
  ],

  // Coverage thresholds (80% minimum per testing rules)
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },

  // Coverage reporting
  coverageReporters: ['text', 'text-summary', 'lcov', 'html', 'json', 'clover'],

  // Coverage directory
  coverageDirectory: '<rootDir>/coverage',

  // Test patterns
  testMatch: ['**/__tests__/**/*.(ts|tsx|js|jsx)', '**/*.(test|spec).(ts|tsx|js|jsx)'],

  // Module file extensions
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json'],

  // Transform configuration
  transform: {
    '^.+\\.(ts|tsx)$': [
      'ts-jest',
      {
        tsconfig: 'tsconfig.json',
      },
    ],
  },

  // Module name mapping for absolute imports
  moduleNameMapping: {
    '^@/(.*)$': '<rootDir>/src/$1',
    '^@vibebiz/(.*)$': '<rootDir>/packages/$1/src',
  },

  // Setup files
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],

  // Clear mocks between tests
  clearMocks: true,

  // Restore mocks after each test
  restoreMocks: true,

  // Verbose output
  verbose: true,

  // Performance settings
  maxWorkers: '50%',

  // Watch ignore patterns
  watchPathIgnorePatterns: ['/node_modules/', '/dist/', '/build/', '/coverage/'],
};
