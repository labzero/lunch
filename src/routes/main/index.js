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

import invitation from './invitation';
import password from './password';
import users from './users';

// The top-level (parent) route
export default {

  path: '',

  // Keep in mind, routes are evaluated in order
  children: [
    {
      path: '',
      action: async (context) => (await import(/* webpackChunkName: 'landing' */ './landing')).default(context)
    },
    {
      path: '/teams',
      action: async (context) => (await import(/* webpackChunkName: 'teams' */ './teams')).default(context)
    },
    {
      path: '/new-team',
      action: async (context) => (await import(/* webpackChunkName: 'new-team' */ './new-team')).default(context)
    },
    {
      path: '/account',
      action: async (context) => (await import(/* webpackChunkName: 'account' */ './account')).default(context)
    },
    {
      path: '/welcome',
      action: async (context) => (await import(/* webpackChunkName: 'welcome' */ './welcome')).default(context)
    },
    {
      path: '/invitation',
      children: invitation,
    },
    {
      path: '/password',
      children: password,
    },
    {
      path: '/users',
      children: users,
    },
    {
      path: '/about',
      action: async (context) => (await import(/* webpackChunkName: 'about' */ './about')).default(context)
    },
    {
      path: '/login',
      action: async (context) => (await import(/* webpackChunkName: 'login' */ '../login')).default(context)
    },

    // Wildcard routes, e.g. { path: '(.*)', ... } (must go last)
    {
      path: '(.*)',
      action: async (context) => (await import(/* webpackChunkName: 'not-found' */ '../not-found')).default(context)
    }
  ],

  action: rootAction
};
