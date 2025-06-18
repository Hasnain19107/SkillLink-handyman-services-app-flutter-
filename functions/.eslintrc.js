module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    "ecmaVersion": 2018,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "single"],
    "max-len": ["error", {"code": 100}], // Increased from 80 to 100
    "object-curly-spacing": ["error", "never"],
    "require-jsdoc": "off", // Disable JSDoc requirement
    "valid-jsdoc": "off",   // Disable JSDoc validation
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
