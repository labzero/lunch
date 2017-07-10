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
    parser: 'babel-eslint',

    extends: [
      'airbnb',
      'plugin:css-modules/recommended',
    ],

    plugins: [
      'css-modules',
    ],

    globals: {
      __DEV__: true,
    },

    env: {
      browser: true,
    },

    rules: {
      // `js` and `jsx` are common extensions
      // `mjs` is for `universal-router` only, for now
      'import/extensions': [
        'error',
        'always',
        {
          js: 'never',
          jsx: 'never',
          mjs: 'never',
        },
      ],

      // Not supporting nested package.json yet
      // https://github.com/benmosher/eslint-plugin-import/issues/458
      'import/no-extraneous-dependencies': 'off',

      // Recommend not to leave any console.log in your code
      // Use console.error, console.warn and console.info instead
      'no-console': [
        'error',
        {
          allow: ['warn', 'error', 'info'],
        },
      ],

      // Allow js files to use jsx syntax, too
      'react/jsx-filename-extension': 'off',

      // https://github.com/kriasoft/react-starter-kit/pull/961
      // You can reopen this if you still want this rule
      'react/prefer-stateless-function': 'off',

      "comma-dangle": 0,
      "key-spacing": 0,
      "no-confusing-arrow": 0,
      "react/jsx-quotes": 0,
      "jsx-quotes": [
        2,
        "prefer-double"
      ],
      "arrow-parens": "off",
      "generator-star-spacing": "off",
      "import/no-extraneous-dependencies": "off",
      "import/prefer-default-export": 0,
      "react/forbid-prop-types": "off",
    },
  };
