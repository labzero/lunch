/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import 'whatwg-fetch';
import es6Promise from 'es6-promise';
import React from 'react';
import ReactDOM from 'react-dom';
import deepForceUpdate from 'react-deep-force-update';
import queryString from 'query-string';
import RobustWebSocket from 'robust-websocket';
import { createPath } from 'history/PathUtils';
import App from './components/App';
import createFetch from './createFetch';
import configureStore from './store/configureStore';
import history from './history';
import { updateMeta } from './DOMUtils';
import routerCreator from './router';

/* eslint-disable global-require */

es6Promise.polyfill();

window.RobustWebSocket = RobustWebSocket;

let subdomain;

// Undo Browsersync mangling of host
let host = window.App.state.host;
if (host.indexOf('//') === 0) {
  host = host.slice(2);
}
const teamSlug = window.App.state.team.slug;
if (teamSlug && host.indexOf(teamSlug) === 0) {
  subdomain = teamSlug;
  host = host.slice(teamSlug.length + 1); // + 1 for dot
}
window.App.state.host = host;

if (!subdomain) {
  // escape domain periods to not appear as regex wildcards
  const subdomainMatch = window.location.host.match(`^(.*)\\.${host.replace(/\./g, '\\.')}`);
  if (subdomainMatch) {
    subdomain = subdomainMatch[1];
  }
}

const store = configureStore(window.App.state, { history });
/* eslint-enable no-underscore-dangle */

// Global (context) variables that can be easily accessed from any React component
// https://facebook.github.io/react/docs/context.html
const context = {
  // Enables critical path CSS rendering
  // https://github.com/kriasoft/isomorphic-style-loader
  insertCss: (...styles) => {
    // eslint-disable-next-line no-underscore-dangle
    const removeCss = styles.map(x => x._insertCss());
    return () => {
      removeCss.forEach(f => f());
    };
  },
  // Universal HTTP client
  fetch: createFetch(fetch, {
    baseUrl: window.App.apiUrl,
  }),
  // Initialize a new Redux store
  // http://redux.js.org/docs/basics/UsageWithReact.html
  store
};

const container = document.getElementById('app');
let currentLocation = history.location;
let appInstance;

// Switch off the native scroll restoration behavior and handle it manually
// https://developers.google.com/web/updates/2015/09/history-api-scroll-restoration
const scrollPositionsHistory = {};
if (window.history && 'scrollRestoration' in window.history) {
  window.history.scrollRestoration = 'manual';
}

let routes;
if (subdomain) {
  routes = require('./routes/team').default; // eslint-disable-line global-require
} else {
  routes = require('./routes/main').default; // eslint-disable-line global-require
}

const router = routerCreator(routes);

// Re-render the app when window.location changes
async function onLocationChange(location, action) {
  // Remember the latest scroll position for the previous location
  scrollPositionsHistory[currentLocation.key] = {
    scrollX: window.pageXOffset,
    scrollY: window.pageYOffset,
  };
  // Delete stored scroll position for next page if any
  if (action === 'PUSH') {
    delete scrollPositionsHistory[location.key];
  }
  currentLocation = location;

  const isInitialRender = !action;
  try {
    // Traverses the list of routes in the order they are defined until
    // it finds the first route that matches provided URL path string
    // and whose action method returns anything other than `undefined`.
    const route = await router.resolve({
      ...context,
      pathname: location.pathname,
      query: queryString.parse(location.search),
      subdomain
    });

    // Prevent multiple page renders during the routing process
    if (currentLocation.key !== location.key) {
      return;
    }

    if (route.redirect) {
      history.replace(route.redirect);
      return;
    }

    const renderReactApp = isInitialRender ? ReactDOM.hydrate : ReactDOM.render;
    appInstance = renderReactApp(
      <App context={context}>{route.component}</App>,
      container,
      () => {
        if (isInitialRender) {
          const elem = document.getElementById('css');
          if (elem) elem.parentNode.removeChild(elem);
          return;
        }

        document.title = route.title;

        updateMeta('description', route.description);
        // Update necessary tags in <head> at runtime here, ie:
        // updateMeta('keywords', route.keywords);
        // updateCustomMeta('og:url', route.canonicalUrl);
        // updateCustomMeta('og:image', route.imageUrl);
        // updateLink('canonical', route.canonicalUrl);
        // etc.

        let scrollX = 0;
        let scrollY = 0;
        const pos = scrollPositionsHistory[location.key];
        if (pos) {
          scrollX = pos.scrollX;
          scrollY = pos.scrollY;
        } else {
          const targetHash = location.hash.substr(1);
          if (targetHash) {
            const target = document.getElementById(targetHash);
            if (target) {
              scrollY = window.pageYOffset + target.getBoundingClientRect().top;
            }
          }
        }

        // Restore the scroll position if it was saved into the state
        // or scroll to the given #hash anchor
        // or scroll to top of the page
        window.scrollTo(scrollX, scrollY);

        // Google Analytics tracking. Don't send 'pageview' event after
        // the initial rendering, as it was already sent
        if (window.ga) {
          window.ga('send', 'pageview', createPath(location));
        }
      },
    );
  } catch (error) {
    if (__DEV__) {
      throw error;
    }

    console.error(error);

    // Do a full page reload if error occurs during client-side navigation
    if (!isInitialRender && currentLocation.key === location.key) {
      window.location.reload();
    }
  }
}

// Handle client-side navigation by using HTML5 History API
// For more information visit https://github.com/mjackson/history#readme
history.listen(onLocationChange);
onLocationChange(currentLocation);

// Enable Hot Module Replacement (HMR)
if (module.hot) {
  const hotUpdate = () => {
    if (appInstance && appInstance.updater.isMounted(appInstance)) {
      // Force-update the whole tree, including components that refuse to update
      deepForceUpdate(appInstance);
    }

    onLocationChange(currentLocation);
  }

  module.hot.accept('./routes/team', () => {
    routes = require('./routes/team').default; // eslint-disable-line global-require
    hotUpdate();
  });

  module.hot.accept('./routes/main', () => {
    routes = require('./routes/main').default; // eslint-disable-line global-require
    hotUpdate();
  });
}
