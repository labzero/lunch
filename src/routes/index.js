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
const routes = {
    path: '/',
  
    // Keep in mind, routes are evaluated in order
    children: [
        {
            path: '/',
            load: () => import(/* webpackChunkName: 'landing' */ './main/landing'),
          },
          {
            path: '/teams',
            load: () => import(/* webpackChunkName: 'teams' */ './main/teams'),
          },
          {
            path: '/new-team',
            load: () => import(/* webpackChunkName: 'new-team' */ './main/new-team'),
          },
          {
            path: '/account',
            load: () => import(/* webpackChunkName: 'account' */ './main/account'),
          },
          {
            path: '/welcome',
            load: () => import(/* webpackChunkName: 'welcome' */ './main/welcome'),
          },
          {
            path: '/invitation',
            children: require('./main/invitation').default,
          },
          {
            path: '/password',
            children: require('./main/password').default,
          },
          {
            path: '/users',
            children: require('./main/users').default,
          },
          {
            path: '/about',
            load: () => import(/* webpackChunkName: 'about' */ './main/about'),
          },
          {
            path: '/login',
            load: () => import(/* webpackChunkName: 'login' */ './login'),
          },
          {
            path: '/team/',
            load: () => import(/* webpackChunkName: 'home' */ './team/home'),
          },
          {
            path: '/team/team',
            load: () => import(/* webpackChunkName: 'team' */ './team/team'),
          },
          {
            path: '/team/tags',
            load: () => import(/* webpackChunkName: 'tags' */ './team/tags'),
          },
          {
            path: '/team/teams',
            load: () => import(/* webpackChunkName: 'teams' */ './team/teams'),
          },
          {
            path: '/team/login',
            load: () => import(/* webpackChunkName: 'login' */ './login'),
          },
  
      // Wildcard routes, e.g. { path: '(.*)', ... } (must go last)
      {
        path: '(.*)',
        load: () => import(/* webpackChunkName: 'not-found' */ './not-found'),
      },
    ],
  
    async action({ next }) {
      // Execute each child route until one of them return the result
      const route = await next();
  
      // Provide default values for title, description etc.
      route.title = `${route.title || 'Untitled Page'} - www.reactstarterkit.com`;
      route.description = route.description || '';
  
      return route;
    },
  };
  
  // The error page is available by permanent url for development mode
//   if (__DEV__) {
//     routes.children.unshift({
//       path: '/error',
//       action: require('./error').default,
//     });
//   }
  
  export default routes;