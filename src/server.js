/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import 'babel-polyfill';
import path from 'path';
import express from 'express';
import React from 'react';
import { Provider } from 'react-redux';
import ReactDOM from 'react-dom/server';
import { match, RouterContext } from 'react-router';
import configureStore from './configureStore';
import assets from './assets';
import { port } from './config';
import makeRoutes from './routes';
import ContextHolder from './core/ContextHolder';
import Html from './components/Html';
import Restaurant from './models/Restaurant';

const server = global.server = express();

const routes = makeRoutes();

//
// Tell any CSS tooling (such as Material UI) to use all vendor prefixes if the
// user agent is not known.
// -----------------------------------------------------------------------------
global.navigator = global.navigator || {};
global.navigator.userAgent = global.navigator.userAgent || 'all';

//
// Register Node.js middleware
// -----------------------------------------------------------------------------
server.use(express.static(path.join(__dirname, 'public')));

//
// Register API middleware
// -----------------------------------------------------------------------------
server.use('/api/content', require('./api/content').default);
server.use('/api/restaurants', require('./api/restaurants').default);

//
// Register server-side rendering middleware
// -----------------------------------------------------------------------------
server.get('*', async (req, res, next) => {
  try {
    match({ routes, location: req.url }, (error, redirectLocation, renderProps) => {
      Restaurant.fetchAll().then(all => {
        if (error) {
          throw error;
        }
        if (redirectLocation) {
          const redirectPath = `${redirectLocation.pathname}${redirectLocation.search}`;
          res.redirect(302, redirectPath);
          return;
        }
        let statusCode = 200;
        const initialState = { restaurants: { items: all.serialize() } };
        const store = configureStore(initialState);
        const data = {
          title: '',
          description: '',
          css: '',
          body: '',
          entry: assets.main.js,
          initialState
        };
        const css = [];
        const context = {
          insertCss: styles => css.push(styles._getCss()),
          onSetTitle: value => (data.title = value),
          onSetMeta: (key, value) => (data[key] = value),
          onPageNotFound: () => (statusCode = 404),
        };
        data.body = ReactDOM.renderToString(
          <ContextHolder context={context}>
            <Provider store={store}>
              <RouterContext {...renderProps} />
            </Provider>
          </ContextHolder>
        );
        data.css = css.join('');
        const html = ReactDOM.renderToStaticMarkup(<Html {...data} />);
        res.status(statusCode).send(`<!doctype html>\n${html}`);
      });
    });
  } catch (err) {
    next(err);
  }
});

//
// Launch the server
// -----------------------------------------------------------------------------
server.listen(port, () => {
  /* eslint-disable no-console */
  console.log(`The server is running at http://localhost:${port}/`);
});
