/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

// ESLint configuration
// http://eslint.org/docs/user-guide/configuring
module.exports = {
  parser: "@typescript-eslint/parser",

  extends: [
    "airbnb",
    "plugin:css-modules/recommended",
    "plugin:@typescript-eslint/recommended",
    "prettier",
  ],

  plugins: ["css-modules", "@typescript-eslint", "import"],

  globals: {
    Bun: true,
    __DEV__: true,
  },

  env: {
    browser: true,
  },

  root: true,

  rules: {
    // `js` and `jsx` are common extensions
    // `mjs` is for `universal-router` only, for now
    "import/extensions": [
      "error",
      {
        js: "never",
        jsx: "never",
        mjs: "never",
        ts: "never",
        json: "always",
      },
    ],

    // Not supporting nested package.json yet
    // https://github.com/benmosher/eslint-plugin-import/issues/458
    "import/no-extraneous-dependencies": "off",

    "jsx-a11y/anchor-is-valid": [
      "error",
      {
        specialLink: ["to"],
      },
    ],

    // Recommend not to leave any console.log in your code
    // Use console.error, console.warn and console.info instead
    "no-console": [
      "error",
      {
        allow: ["warn", "error", "info"],
      },
    ],

    "prefer-destructuring": 0,

    // Allow js files to use jsx syntax, too
    "react/jsx-filename-extension": [
      "error",
      { extensions: [".js", ".jsx", ".tsx"] },
    ],

    // Automatically convert pure class to function by
    // babel-plugin-transform-react-pure-class-to-function
    // https://github.com/kriasoft/react-starter-kit/pull/961
    "react/prefer-stateless-function": "off",
    "comma-dangle": 0,
    "key-spacing": 0,
    "no-confusing-arrow": 0,
    "react/jsx-quotes": 0,
    "react/jsx-props-no-spreading": 0,
    "max-len": 0,
    "jsx-quotes": [2, "prefer-double"],
    "arrow-parens": "off",
    "generator-star-spacing": "off",
    "import/prefer-default-export": 0,

    "react/forbid-prop-types": "off",
    "react/destructuring-assignment": "off",
    "react/function-component-definition": [
      "error",
      {
        namedComponents: "arrow-function",
        unnamedComponents: "arrow-function",
      },
    ],
    "react/static-property-placement": "off",
    "import/no-relative-packages": "off",
    "import/no-import-module-exports": "off",
    "no-use-before-define": "off",
    "no-param-reassign": [
      "error",
      { props: true, ignorePropertyModificationsFor: ["draftState"] },
    ],
    "@typescript-eslint/no-use-before-define": ["error"],
  },

  settings: {
    // Allow absolute paths in imports, e.g. import Button from 'components/Button'
    // https://github.com/benmosher/eslint-plugin-import/tree/master/resolvers
    "import/resolver": {
      node: {
        extensions: [".js", ".jsx", ".ts", ".tsx"],
        moduleDirectory: ["node_modules", "src"],
      },
      typescript: {
        alwaysTryTypes: true, // always try to resolve types under `<root>@types` directory even it doesn't contain any source code, like `@types/unist`
        extensions: [".ts", ".tsx"],
      },
    },
    "import/parsers": {
      "@typescript-eslint/parser": [".ts", ".tsx"],
    },
  },
};
