/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable global-require */

// The top-level (parent) route
export default {
  path: '/invitation',

  // Keep in mind, routes are evaluated in order
  children: [
    require('./create').default,
    require('./new').default,

    // Wildcard routes, e.g. { path: '*', ... } (must go last)
    require('../../notFound').default,
  ]
};
