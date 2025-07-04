// Jest setup file to configure test environment
process.env.NODE_ENV = 'test';

// Suppress console warnings during tests
const originalWarn = console.warn;
console.warn = (...args: any[]) => {
  // Only suppress CDK deprecation warnings during tests
  if (args[0] && typeof args[0] === 'string' && args[0].includes('[WARNING]')) {
    return;
  }
  originalWarn.apply(console, args);
};