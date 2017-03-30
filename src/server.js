/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import 'isomorphic-fetch';
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
import ReactDOM from 'react-dom/server';
import UniversalRouter from 'universal-router';
import expressWs from 'express-ws';
import serialize from 'serialize-javascript';
import Honeybadger from 'honeybadger';
import PrettyError from 'pretty-error';
import App from './components/App';
import Html from './components/Html';
import { ErrorPageWithoutStyle } from './components/ErrorPage/ErrorPage';
import errorPageStyle from './components/ErrorPage/ErrorPage.scss';
import teamRoutes from './routes/team';
import mainRoutes from './routes/main';
import assets from './assets.json'; // eslint-disable-line import/no-unresolved
import configureStore from './store/configureStore';
import { host, port, httpsPort, auth, selfSigned, privateKeyPath, certificatePath } from './config';
import makeInitialState from './initialState';
import passport from './core/passport';
import api from './api';
import { Team, User } from './models';

fetch.promise = Promise;

const app = express();

const hostname = host.match(/^([^:]*):?[0-9]{0,}/)[1];
const bsHost = process.env.BS_RUNNING ? `${hostname}:3001` : host;
const domain = `.${hostname}`;

const httpServer = new HttpServer(app);
let httpsServer;
if (process.env.NODE_ENV === 'production') {
  if (selfSigned) {
    process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';
  }
  const key = fs.readFileSync(privateKeyPath);
  const cert = fs.readFileSync(certificatePath);
  httpsServer = new HttpsServer({ key, cert }, app);
  app.use(forceSSL);
}

//
// Tell any CSS tooling (such as Material UI) to use all vendor prefixes if the
// user agent is not known.
// -----------------------------------------------------------------------------
global.navigator = global.navigator || {};
global.navigator.userAgent = global.navigator.userAgent || 'all';

//
// Register Node.js middleware
// -----------------------------------------------------------------------------
app.use(Honeybadger.requestHandler); // Use *before* all other app middleware.
app.use(compression());
app.use(express.static(path.join(__dirname, 'public')));
app.use(cookieParser());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

//
// Authentication
// -----------------------------------------------------------------------------
app.use(expressJwt({
  secret: auth.jwt.secret,
  credentialsRequired: false,
  getToken: req => req.cookies.id_token,
}));
app.use(passport.initialize());

app.use((req, res, next) => {
  if (typeof req.user === 'number' || typeof req.user === 'string') {
    User.getSessionUser(req.user).then(user => {
      if (user) {
        // eslint-disable-next-line no-param-reassign
        req.user = user;
      } else {
        // eslint-disable-next-line no-param-reassign
        delete req.user;
      }
      next();
    }).catch(err => next(err));
  } else {
    next();
  }
});

const getSubdomainMatch = req => req.hostname.match(`^(.*)${domain.replace(/\./g, '\\.')}`);

if (__DEV__) {
  app.enable('trust proxy');
}
app.get(
  '/login',
  (req, res, next) => {
    const subdomainMatch = getSubdomainMatch(req);
    if (subdomainMatch) {
      res.redirect(301, `${req.protocol}://${bsHost}/login?team=${subdomainMatch[1]}`);
    } else {
      const options = { scope: ['email', 'profile'], session: false };
      if (req.query.team) {
        options.state = req.query.team;
      }
      passport.authenticate('google', options)(req, res, next);
    }
  },
);
app.get('/login/callback',
  (req, res, next) => {
    const options = { failureRedirect: '/coming-soon', session: false };
    if (req.query.team) {
      options.state = req.query.team;
    }
    passport.authenticate('google', options)(req, res, next);
  },
  (req, res) => {
    const expiresIn = 60 * 60 * 24 * 180; // 180 days
    const token = jwt.sign(req.user, auth.jwt.secret);
    res.cookie('id_token', token, {
      domain,
      maxAge: 1000 * expiresIn,
      httpOnly: true
    });
    if (req.query.state) {
      res.redirect(`${req.protocol}://${req.query.state}.${bsHost}/`);
    } else {
      res.redirect('/');
    }
  },
);
app.get('/logout', (req, res) => {
  req.logout();
  res.clearCookie('id_token', { domain });
  res.redirect('/');
});

//
// Register WebSockets
// -----------------------------------------------------------------------------
const wsInstance = expressWs(app, httpsServer === undefined ? httpServer : httpsServer);
const wss = wsInstance.getWss();

wss.broadcast = (teamId, data) => {
  wss.clients.forEach(client => {
    if (client.teamId === teamId) {
      client.send(JSON.stringify(data));
    }
  });
};

app.use((req, res, next) => {
  req.wss = wss; // eslint-disable-line no-param-reassign
  return next();
});

//
// Get current team
// -----------------------------------------------------------------------------
app.use(async (req, res, next) => {
  const subdomainMatch = getSubdomainMatch(req);
  if (subdomainMatch) {
    // eslint-disable-next-line no-param-reassign
    req.team = await Team.findOne({ where: { slug: subdomainMatch[1] } });
    if (!req.team) {
      res.redirect(302, `${req.protocol}://${bsHost}`);
      return;
    }
  }
  next();
});

//
// Register API middleware
// -----------------------------------------------------------------------------
app.use('/api', api());

//
// Register server-side rendering middleware
// -----------------------------------------------------------------------------
app.get('*', async (req, res, next) => {
  try {
    const stateData = {
      host: bsHost
    };
    if (req.user) {
      stateData.user = req.user;
      stateData.teams = await Team.findAll({
        order: 'created_at ASC',
        where: { id: req.user.roles.map(r => r.team_id) }
      });
      stateData.team = req.team;
    }

    const initialState = makeInitialState(stateData);
    const store = configureStore(initialState, {
      cookie: req.headers.cookie,
    });

    const css = new Set();

    // Global (context) variables that can be easily accessed from any React component
    // https://facebook.github.io/react/docs/context.html
    const context = {
      // Enables critical path CSS rendering
      // https://github.com/kriasoft/isomorphic-style-loader
      insertCss: (...styles) => {
        // eslint-disable-next-line no-underscore-dangle
        styles.forEach(style => css.add(style._getCss()));
      },
      // Initialize a new Redux store
      // http://redux.js.org/docs/basics/UsageWithReact.html
      store
    };

    let router;
    if (stateData.team) {
      router = new UniversalRouter(teamRoutes);
    } else {
      router = new UniversalRouter(mainRoutes);
    }

    const route = await router.resolve({
      ...context,
      path: req.path,
      query: req.query
    });

    if (route.redirect) {
      res.redirect(route.status || 302, route.redirect);
      return;
    }

    const data = { ...route,
      apikey: process.env.GOOGLE_CLIENT_APIKEY || '',
      children: '',
      title: 'Lunch',
      description: 'An app for groups to decide on nearby lunch options.',
      body: '',
      root: `${req.protocol}://${req.get('host')}`,
      initialState: serialize(initialState)
    };

    data.children = ReactDOM.renderToString(<App context={context}>{route.component}</App>);

    data.styles = [
      { id: 'css', cssText: [...css].join('') },
    ];
    data.scripts = [
      assets.vendor.js,
      assets.client.js,
    ];
    if (assets[route.chunk]) {
      data.scripts.push(assets[route.chunk].js);
    }

    const html = ReactDOM.renderToStaticMarkup(<Html {...data} />);
    res.status(route.status || 200);
    res.send(`<!doctype html>${html}`);
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

app.use((err, req, res, next) => { // eslint-disable-line no-unused-vars
  console.log(pe.render(err)); // eslint-disable-line no-console
  const html = ReactDOM.renderToStaticMarkup(
    <Html
      title="Internal Server Error"
      description={err.message}
      styles={[{ id: 'css', cssText: errorPageStyle._getCss() }]} // eslint-disable-line no-underscore-dangle
    >
      {ReactDOM.renderToString(<ErrorPageWithoutStyle error={err} />)}
    </Html>,
  );
  res.status(err.status || 500);
  res.send(`<!doctype html>${html}`);
});

app.use(Honeybadger.errorHandler);  // Use *after* all other app middleware.

//
// Launch the server
// -----------------------------------------------------------------------------
httpServer.listen(port, () => {
  /* eslint-disable no-console */
  console.log(`The server is running at http://local.lunch.pink:${port}/`);
});
if (httpsServer !== undefined) {
  httpsServer.listen(httpsPort, () => {
    console.log(`The HTTPS server is running at https://local.lunch.pink:${httpsPort}`);
  });
}
