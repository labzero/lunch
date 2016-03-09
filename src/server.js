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
import cookieParser from 'cookie-parser';
import bodyParser from 'body-parser';
import expressJwt from 'express-jwt';
import expressGraphQL from 'express-graphql';
import jwt from 'jsonwebtoken';
import React from 'react';
import { Provider } from 'react-redux';
import ReactDOM from 'react-dom/server';
import { match, RouterContext } from 'react-router';
import configureStore from './configureStore';
import assets from './assets';
import { port, auth } from './config';
import makeRoutes from './routes';
import ContextHolder from './core/ContextHolder';
import Html from './components/Html';
import passport from './core/passport';
import schema from './data/schema';
import fetch from './core/fetch';
import ApiClient from './core/ApiClient';
import contentApi from './api/content';
import restaurantApi from './api/restaurants';

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
server.use(cookieParser());
server.use(bodyParser.urlencoded({ extended: true }));
server.use(bodyParser.json());

//
// Authentication
// -----------------------------------------------------------------------------
server.use(expressJwt({
  secret: auth.jwt.secret,
  credentialsRequired: false,
  /* jscs:disable requireCamelCaseOrUpperCaseIdentifiers */
  getToken: req => req.cookies.id_token,
  /* jscs:enable requireCamelCaseOrUpperCaseIdentifiers */
}));
server.use(passport.initialize());

server.get('/login',
  passport.authenticate('google', { scope: ['email', 'profile'] })
);
server.get('/login/callback',
  passport.authenticate('google', { failureRedirect: '/' }),
  (req, res) => {
    const expiresIn = 60 * 60 * 24 * 180; // 180 days
    const token = jwt.sign(req.user.toJSON(), auth.jwt.secret, { expiresIn });
    res.cookie('id_token', token, { maxAge: 1000 * expiresIn, httpOnly: true });
    res.redirect('/');
  }
);

//
// Register API middleware
// -----------------------------------------------------------------------------
server.use('/api/content', contentApi);
server.use('/api/restaurants', restaurantApi);
server.use('/graphql', expressGraphQL(req => ({
  schema,
  graphiql: true,
  rootValue: { request: req },
  pretty: process.env.NODE_ENV !== 'production',
})));

//
// Register server-side rendering middleware
// -----------------------------------------------------------------------------
server.get('*', async (req, res, next) => {
  try {
    match({ routes, location: req.url }, (error, redirectLocation, renderProps) => {
      fetch('/api/restaurants').then(all => new ApiClient(all).processResponse()).then(all => {
        if (error) {
          throw error;
        }
        if (redirectLocation) {
          const redirectPath = `${redirectLocation.pathname}${redirectLocation.search}`;
          res.redirect(302, redirectPath);
          return;
        }
        let statusCode = 200;
        const initialState = {
          restaurants: { items: all },
          user: {},
          flashes: [],
          latLng: {
            lat: process.env.SUGGEST_LAT,
            lng: process.env.SUGGEST_LNG
          }
        };
        if (req.user) {
          initialState.user = req.user;
        }
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
