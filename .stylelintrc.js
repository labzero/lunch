/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

const lowerKebabCase = /^[a-z][a-zA-Z0-9]+$/;

// stylelint configuration
// https://stylelint.io/user-guide/configuration/
module.exports = {
  // The standard config based on a handful of CSS style guides
  // https://github.com/stylelint/stylelint-config-standard
  extends: "stylelint-config-standard-scss",

  plugins: [
    // stylelint plugin to sort CSS rules content with specified order
    // https://github.com/hudochenkov/stylelint-order
    "stylelint-order",
  ],

  rules: {
    "at-rule-no-unknown": null,
    "scss/at-rule-no-unknown": true,
    "declaration-empty-line-before": null,
    "keyframes-name-pattern": lowerKebabCase,
    "number-leading-zero": "never",
    "property-no-unknown": [
      true,
      {
        ignoreProperties: [
          // CSS Modules composition
          // https://github.com/css-modules/css-modules#composition
          "composes",
          "overflow-anchor",
        ],
      },
    ],
    "selector-class-pattern": lowerKebabCase,

    "selector-pseudo-class-no-unknown": [
      true,
      {
        ignorePseudoClasses: [
          // CSS Modules :global scope
          // https://github.com/css-modules/css-modules#exceptions
          "global",
          "local",
        ],
      },
    ],

    // https://github.com/hudochenkov/stylelint-order/blob/master/rules/order/README.md
    "order/order": [
      "custom-properties",
      "dollar-variables",
      {
        type: "at-rule",
        name: "include",
      },
      "declarations",
      "at-rules",
      "rules",
    ],

    // https://github.com/hudochenkov/stylelint-order/blob/master/rules/properties-order/README.md
    "order/properties-order": [],
  },
};
