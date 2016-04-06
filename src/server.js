/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import Promise from 'bluebird';
import path from 'path';
import express from 'express';
import fs from 'fs';
import { Server as HttpServer } from 'http';
import { Server as HttpsServer } from 'https';
import compression from 'compression';
import forceSSL from 'express-force-ssl';
import cookieParser from 'cookie-parser';
import bodyParser from 'body-parser';
import expressJwt from 'express-jwt';
import jwt from 'jsonwebtoken';
import React from 'react';
import { Provider } from 'react-redux';
import ReactDOM from 'react-dom/server';
import PrettyError from 'pretty-error';
import { match, RouterContext } from 'react-router';
import configureStore from './configureStore';
import assets from './assets';
import { port, httpsPort, auth, selfSigned, privateKeyPath, certificatePath } from './config';
import makeRoutes from './routes';
import ContextHolder from './core/ContextHolder';
import passport from './core/passport';
import restaurantApi from './api/restaurants';
import tagApi from './api/tags';
import { Restaurant, Tag, User } from './models';
import { Server as WebSocketServer } from 'ws';
import serialize from 'serialize-javascript';

const server = global.server = express();

const httpServer = new HttpServer(server);
let httpsServer;
if (process.env.NODE_ENV === 'production') {
  if (selfSigned) {
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
  }
  const key = fs.readFileSync(privateKeyPath);
  const cert = fs.readFileSync(certificatePath);
  httpsServer = new HttpsServer({ key, cert }, server);
  server.use(forceSSL);
}
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
server.use(compression());
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
server.get('/logout', (req, res) => {
  req.logout();
  res.clearCookie('id_token');
  res.redirect('/');
});

//
// Register WebSockets
// -----------------------------------------------------------------------------
const wss = new WebSocketServer({ server: httpsServer === undefined ? httpServer : httpsServer });

wss.broadcast = data => {
  wss.clients.forEach(client => {
    client.send(JSON.stringify(data));
  });
};

server.use((req, res, next) => {
  req.wss = wss;
  return next();
});

//
// Register API middleware
// -----------------------------------------------------------------------------
server.use('/api/restaurants', restaurantApi);
server.use('/api/tags', tagApi);

//
// Register server-side rendering middleware
// -----------------------------------------------------------------------------
server.get('*', async (req, res, next) => {
  try {
    match({ routes, location: req.url }, (error, redirectLocation, renderProps) => {
      if (error) {
        throw error;
      }
      if (redirectLocation) {
        const redirectPath = `${redirectLocation.pathname}${redirectLocation.search}`;
        res.redirect(302, redirectPath);
        return;
      }
      const finds = [Restaurant.findAllWithTagIds(), Tag.scope('orderedByRestaurant').findAll()];
      if (req.user) {
        finds.push(User.findAll({ attributes: ['id', 'name'] }));
      }
      Promise.all(finds)
        .then(([restaurants, tags, users]) => {
          let statusCode = 200;
          const initialState = {
            restaurants: {
              isFetching: false,
              didInvalidate: false,
              items: restaurants.map(r => r.toJSON())
            },
            tags: {
              isFetching: false,
              didInvalidate: false,
              items: tags.map(t => t.toJSON())
            },
            flashes: [],
            modals: {},
            user: {},
            users: {
              items: []
            },
            latLng: {
              lat: parseFloat(process.env.SUGGEST_LAT),
              lng: parseFloat(process.env.SUGGEST_LNG)
            },
            listUi: {},
            mapUi: {
              markers: {},
              showUnvoted: true
            },
            tagFilters: [],
            tagUi: {},
            pageUi: {},
            wsPort: process.env.BS_RUNNING ? port : 0
          };
          if (req.user) {
            initialState.user = req.user;
            initialState.users.items = users.map(u => u.toJSON());
          }
          const store = configureStore(initialState);
          const template = require('./views/index.jade');
          const data = {
            apikey: process.env.GOOGLE_CLIENT_APIKEY || '',
            title: '',
            description: '',
            css: '',
            body: '',
            entry: assets.main.js,
            initialState: serialize(initialState)
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
          res.status(statusCode);
          res.send(template(data));
        }).catch(err => next(err));
    });
  } catch (err) {
    next(err);
  }
});

//
// Error handling
// -----------------------------------------------------------------------------
const pe = new PrettyError();
pe.skipNodeFiles();
pe.skipPackage('express');

server.use((err, req, res, next) => { // eslint-disable-line no-unused-vars
  console.log(pe.render(err)); // eslint-disable-line no-console
  const template = require('./views/error.jade');
  const statusCode = err.status || 500;
  res.status(statusCode);
  res.send(template({
    message: err.message,
    stack: /* process.env.NODE_ENV === 'production' ? '' : */ err.stack,
  }));
});

//
// Launch the server
// -----------------------------------------------------------------------------
httpServer.listen(port, () => {
  /* eslint-disable no-console */
  console.log(`The server is running at http://localhost:${port}/`);
});
if (httpsServer !== undefined) {
  httpsServer.listen(httpsPort, () => {
    console.log(`The HTTPS server is running at https://localhost:${httpsPort}`);
  });
}
