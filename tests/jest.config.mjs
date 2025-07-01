/** @type {import('jest').Config} */
export default {
  displayName: 'Cross-Cutting Tests',
  preset: 'ts-jest',
  testEnvironment: 'node',

  // Root directory for this test suite
  rootDir: '.',

  // Test file patterns
  testMatch: [
    '<rootDir>/integration/**/*.test.{ts,js}',
    '<rootDir>/e2e/**/*.test.{ts,js}',
    '<rootDir>/security/**/*.test.{ts,js}',
    '<rootDir>/performance/**/*.test.{ts,js}',
    '<rootDir>/utils/**/*.test.{ts,js}',
  ],

  // Module file extensions
  moduleFileExtensions: ['ts', 'js', 'json'],

  // Transform configuration
  transform: {
    '^.+\\.(ts|js)$': [
      'ts-jest',
      {
        tsconfig: './tsconfig.json',
      },
    ],
  },

  // Module name mapping for absolute imports
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/../src/$1',
    '^@vibebiz/(.*)$': '<rootDir>/../packages/$1/src',
    '^@tests/(.*)$': '<rootDir>/$1',
  },

  // Setup files
  setupFilesAfterEnv: [
    '<rootDir>/config/jest.setup.js',
    '<rootDir>/../jest.setup.js', // Inherit global setup
  ],

  // Global test timeout for integration tests (longer than unit tests)
  testTimeout: 60000,

  // Coverage configuration
  collectCoverageFrom: [
    '<rootDir>/utils/**/*.{ts,js}',
    '<rootDir>/integration/**/*.{ts,js}',
    '!<rootDir>/**/*.d.ts',
    '!<rootDir>/**/*.config.{ts,js}',
    '!<rootDir>/**/fixtures/**',
  ],

  // Coverage thresholds for cross-cutting tests
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },

  // Coverage reporting
  coverageReporters: ['text', 'lcov', 'html', 'json'],
  coverageDirectory: '<rootDir>/coverage',

  // Clear mocks between tests
  clearMocks: true,
  restoreMocks: true,

  // Verbose output for debugging
  verbose: true,

  // Performance settings
  maxWorkers: '25%',

  // Watch ignore patterns
  watchPathIgnorePatterns: ['/node_modules/', '/coverage/', '/fixtures/', '/.git/'],

  // Extensible configuration for ts-jest
  extensionsToTreatAsEsm: ['.ts'],

  // Test runner
  testRunner: 'jest-circus/runner',

  // Fail fast for integration tests
  bail: 1,
};
