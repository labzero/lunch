/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable global-require */

export default [
  {
    path: '/',
    action: require('./create').default,
  },
  {
    path: '/edit',
    action: require('./edit').default,
  },
  {
    path: '/new',
    action: require('./new').default,
  },

  // Wildcard routes, e.g. { path: '*', ... } (must go last)
  {
    path: '*',
    load: () => import(/* webpackChunkName: 'not-found' */ '../../not-found'),
  }
];
