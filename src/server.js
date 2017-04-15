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
import fs from 'fs';
import rfs from 'rotating-file-stream';
import morgan from 'morgan';
import express from 'express';
import { Server as HttpServer } from 'http';
import enforce from 'express-sslify';
import compression from 'compression';
import cookieParser from 'cookie-parser';
import bodyParser from 'body-parser';
import methodOverride from 'method-override';
import session from 'express-session';
import connectSessionSequelize from 'connect-session-sequelize';
import flash from 'connect-flash';
import expressJwt from 'express-jwt';
import React from 'react';
import ReactDOM from 'react-dom/server';
import UniversalRouter from 'universal-router';
import expressWs from 'express-ws';
import Honeybadger from 'honeybadger';
import PrettyError from 'pretty-error';
import App from './components/App';
import Html from './components/Html';
import { ErrorPageWithoutStyle } from './components/ErrorPage/ErrorPage';
import errorPageStyle from './components/ErrorPage/ErrorPage.scss';
import generateUrl from './helpers/generateUrl';
import hasRole from './helpers/hasRole';
import teamRoutes from './routes/team';
import mainRoutes from './routes/main';
import assets from './assets.json'; // eslint-disable-line import/no-unresolved
import configureStore from './store/configureStore';
import { domain, bsHost, port, auth } from './config';
import makeInitialState from './initialState';
import passport from './core/passport';
import invitationMiddleware from './middlewares/invitation';
import loginMiddleware from './middlewares/login';
import passwordMiddleware from './middlewares/password';
import api from './api';
import { sequelize } from './models/db';
import { Team, User } from './models';

fetch.promise = Promise;

const app = express();

const logDirectory = path.join(__dirname, 'log');

// ensure log directory exists
// eslint-disable-next-line no-unused-expressions
fs.existsSync(logDirectory) || fs.mkdirSync(logDirectory);

// create a rotating write stream
const accessLogStream = rfs('access.log', {
  interval: '1d', // rotate daily
  path: logDirectory
});

const httpServer = new HttpServer(app);

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
app.use(morgan('combined', { stream: accessLogStream }));

app.get('/health', (req, res) => {
  res.status(200).send('welcome to the health endpoint');
});

if (process.env.NODE_ENV === 'production') {
  app.use(enforce.HTTPS({
    trustProtoHeader: true,
    trustXForwardedHostHeader: true
  }));
  app.set('trust proxy', true);
}

app.use(compression());
app.use(express.static(path.join(__dirname, 'public')));
app.use(cookieParser());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(methodOverride((req) => {
  if (req.body && typeof req.body === 'object' && '_method' in req.body) {
    const method = req.body._method; // eslint-disable-line no-underscore-dangle
    delete req.body._method; // eslint-disable-line no-underscore-dangle, no-param-reassign
    return method;
  }
  return undefined;
}));

//
// Redirect old labzero.com host
// -----------------------------------------------------------------------------
app.use((req, res, next) => {
  if (req.hostname === 'lunch.labzero.com') {
    res.redirect(301, generateUrl(req, bsHost, path));
  } else {
    next();
  }
});

//
// Session / Flash
// -----------------------------------------------------------------------------
if (__DEV__) {
  app.enable('trust proxy');
}

const SequelizeStore = connectSessionSequelize(session.Store);
app.use(session({
  cookie: {
    domain,
    secure: process.env.NODE_ENV === 'production'
  },
  saveUninitialized: false,
  secret: auth.session.secret,
  store: new SequelizeStore({
    db: sequelize
  }),
  resave: false,
  proxy: true
}));

app.use(flash());

//
// Authentication
// -----------------------------------------------------------------------------
app.use(expressJwt({
  secret: auth.jwt.secret,
  credentialsRequired: false,
  getToken: req => req.cookies.id_token,
}));
app.use(passport.initialize());
app.use((err, req, res, next) => {
  // In the case of an invalid token, attempt to remove it but also
  // attempt to render the requested page as a logged-out user.
  // If the cookie's domain is .lunch.pink but the current host is
  // local.lunch.pink, the cookie might not be removed, so don't blow up.
  if (err.name === 'UnauthorizedError') {
    req.logout();
    res.clearCookie('id_token', { domain });
    next();
  }
});

app.use((req, res, next) => {
  const subdomainMatch = req.hostname.match(`^(.*)${domain.replace(/\./g, '\\.')}`);
  if (subdomainMatch && subdomainMatch[1]) {
    // eslint-disable-next-line no-param-reassign
    req.subdomain = subdomainMatch[1];
  }

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

app.use('/invitation', invitationMiddleware());
app.use('/login', loginMiddleware());
app.use('/password', passwordMiddleware());

app.get('/logout', (req, res) => {
  req.logout();
  res.clearCookie('id_token', { domain });
  res.redirect('/');
});

//
// Register WebSockets
// -----------------------------------------------------------------------------
const wsInstance = expressWs(app, httpServer);
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
  if (req.subdomain) {
    const team = await Team.findOne({ where: { slug: req.subdomain } });
    if (team && hasRole(req.user, team)) {
      req.team = team; // eslint-disable-line no-param-reassign
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
const render = async (req, res, next) => {
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

    const flashes = req.flash();
    const flashKeys = Object.keys(flashes);
    if (flashKeys.length) {
      stateData.flashes = [];
      flashKeys.forEach(k => {
        flashes[k].forEach(f => {
          stateData.flashes.push({
            message: f,
            type: k
          });
        });
      });
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
    if (req.subdomain) {
      router = new UniversalRouter(teamRoutes);
    } else {
      router = new UniversalRouter(mainRoutes);
    }

    const route = await router.resolve({
      ...context,
      path: req.path,
      query: req.query,
      subdomain: req.subdomain
    });

    if (route.redirect) {
      res.redirect(route.status || 302, route.redirect);
      return;
    }

    const data = { ...route,
      apikey: process.env.GOOGLE_CLIENT_APIKEY || '',
      children: '',
      title: route.title || 'Lunch',
      description: 'An app for groups to decide on nearby lunch options.',
      body: '',
      root: generateUrl(req, req.get('host')),
      state: initialState
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
    if (route.map) {
      data.scripts.push(assets.map.js);
    }

    const html = ReactDOM.renderToStaticMarkup(<Html {...data} />);
    res.status(route.status || 200);
    res.send(`<!doctype html>${html}`);
  } catch (err) {
    next(err);
  }
};

app.post('/invitation', render);
app.post('/login', render);
app.post('/password', render);
app.put('/password', render);
app.get('*', render);

//
// Error handling
// -----------------------------------------------------------------------------
const pe = new PrettyError();
pe.skipNodeFiles();
pe.skipPackage('express');

app.use((err, req, res, next) => { // eslint-disable-line no-unused-vars
  console.log(pe.render(err)); // eslint-disable-line no-console
  res.status(err.status || 500);
  if (req.accepts('html') === 'html') {
    const html = ReactDOM.renderToStaticMarkup(
      <Html
        title="Internal Server Error"
        description={err.message}
        styles={[{ id: 'css', cssText: errorPageStyle._getCss() }]} // eslint-disable-line no-underscore-dangle
      >
        {ReactDOM.renderToString(<ErrorPageWithoutStyle error={err} />)}
      </Html>,
    );
    res.send(`<!doctype html>${html}`);
  } else {
    res.json({
      error: true,
      data: {
        message: err.message,
        stack: process.env.NODE_ENV !== 'production' ? err.stack : undefined
      }
    });
  }
  next(err);
});

app.use(Honeybadger.errorHandler);  // Use *after* all other app middleware.

//
// Launch the server
// -----------------------------------------------------------------------------
httpServer.listen(port, () => {
  /* eslint-disable no-console */
  console.log(`The server is running at http://local.lunch.pink:${port}/`);
});
