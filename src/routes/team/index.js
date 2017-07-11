/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable global-require */
import rootAction from '../helpers/rootAction';

// The top-level (parent) route
export default {

  path: '/',

  // Keep in mind, routes are evaluated in order
  children: [
    {
      path: '/',
      load: () => import(/* webpackChunkName: 'home' */ './home'),
    },
    {
      path: '/team',
      load: () => import(/* webpackChunkName: 'team' */ './team'),
    },
    {
      path: '/tags',
      load: () => import(/* webpackChunkName: 'tags' */ './tags'),
    },
    {
      path: '/teams',
      load: () => import(/* webpackChunkName: 'teams' */ './teams'),
    },
    {
      path: '/login',
      load: () => import(/* webpackChunkName: 'login' */ '../login'),
    },

    // Wildcard routes, e.g. { path: '*', ... } (must go last)
    {
      path: '*',
      load: () => import(/* webpackChunkName: 'not-found' */ '../not-found'),
    }
  ],

  action: rootAction

};
