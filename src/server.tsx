/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

import path from "path";
import fs from "fs";
import { createStream } from "rotating-file-stream";
import morgan from "morgan";
import express, {
  Application,
  ErrorRequestHandler,
  RequestHandler,
} from "express";
import cors from "cors";
import http from "http";
import https from "https";
import enforce from "express-sslify";
import compression from "compression";
import cookieParser from "cookie-parser";
import bodyParser from "body-parser";
import bodyParserErrorHandler from "express-body-parser-error-handler";
import methodOverride from "method-override";
import session from "express-session";
import connectSessionSequelize from "connect-session-sequelize";
import flash from "connect-flash";
import { expressjwt, UnauthorizedError as Jwt401Error } from "express-jwt";
import React from "react";
import ReactDOM from "react-dom/server";
import expressWs from "express-ws";
import Honeybadger from "@honeybadger-io/js";
import PrettyError from "pretty-error";
import { v1 } from "uuid";
import AppComponent from "./components/App";
import Html, { HtmlProps } from "./components/Html";
import { ErrorPageWithoutStyle } from "./components/ErrorPage/ErrorPage";
import errorPageStyle from "./components/ErrorPage/ErrorPage.scss";
import generateUrl from "./helpers/generateUrl";
import hasRole from "./helpers/hasRole";
import teamRoutes from "./routes/team";
import mainRoutes from "./routes/main";
import passport from "./passport";
import routerCreator from "./router";
// @ts-ignore
import chunks from "./chunk-manifest.json"; // eslint-disable-line import/no-unresolved
import configureStore from "./store/configureStore";
import config from "./config";
import makeInitialState from "./initialState";
import invitationMiddleware from "./middlewares/invitation";
import loginMiddleware from "./middlewares/login";
import passwordMiddleware from "./middlewares/password";
import usersMiddleware from "./middlewares/users";
import api from "./api";
import { sequelize, Team, User } from "./db";
import { App, AppContext, ExtWebSocket, Flash, StateData } from "./interfaces";
import { InsertCSS } from "isomorphic-style-loader/StyleContext";

process.on("unhandledRejection", (reason, p) => {
  console.error("Unhandled Rejection at:", p, "reason:", reason);
  // send entire app down. Process manager will restart it
  process.exit(1);
});

Honeybadger.configure({
  apiKey: process.env.HONEYBADGER_API_KEY,
  environment: __DEV__ ? "development" : "production",
});

const logDirectory = path.join(__dirname, "log");

// ensure log directory exists
// eslint-disable-next-line no-unused-expressions
fs.existsSync(logDirectory) || fs.mkdirSync(logDirectory);

// create a rotating write stream
const accessLogStream = createStream("access.log", {
  interval: "1d", // rotate daily
  path: logDirectory,
});

const app: Application = express();

let internalWsServer;
if (process.env.USE_HTTPS === "true") {
  // use self-signed cert locally
  const options = {
    key: fs.readFileSync(path.join(__dirname, "../cert/server.key")),
    cert: fs.readFileSync(path.join(__dirname, "../cert/server.crt")),
  };

  internalWsServer = https.createServer(options, app);
} else {
  // prod proxy will take care of https
  internalWsServer = http.createServer(app);
}
export const wsServer = internalWsServer;

//
// Tell any CSS tooling (such as Material UI) to use all vendor prefixes if the
// user agent is not known.
// -----------------------------------------------------------------------------
globalThis.navigator = globalThis.navigator || {};
// @ts-ignore
globalThis.navigator.userAgent = globalThis.navigator.userAgent || "all";

//
// If you are using proxy from external machine, you can set TRUST_PROXY env
// Default is to trust proxy headers only from loopback interface.
// -----------------------------------------------------------------------------
app.set("trust proxy", config.trustProxy);

//
// Register Node.js middleware
// -----------------------------------------------------------------------------
app.use(Honeybadger.requestHandler); // Use *before* all other app middleware.
app.use(morgan("combined", { stream: accessLogStream }));

app.get("/health", (req, res) => {
  res.status(200).send("welcome to the health endpoint");
});

if (process.env.NODE_ENV === "production") {
  app.use(
    enforce.HTTPS({
      trustProtoHeader: true,
      trustXForwardedHostHeader: true,
    })
  );
  app.set("trust proxy", true);
}

app.use(compression());
app.use(express.static(path.resolve(__dirname, "public")));
app.use(cookieParser());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

app.use(bodyParserErrorHandler());

app.use(
  methodOverride((req) => {
    if (req.body && typeof req.body === "object" && "_method" in req.body) {
      const method = req.body._method; // eslint-disable-line no-underscore-dangle
      delete req.body._method; // eslint-disable-line no-underscore-dangle, no-param-reassign
      return method;
    }
    return undefined;
  })
);

//
// Redirect old labzero.com host
// -----------------------------------------------------------------------------
app.use((req, res, next) => {
  if (req.hostname === "lunch.labzero.com") {
    res.redirect(301, generateUrl(req, config.bsHost, req.path));
  } else {
    next();
  }
});

//
// Redirect www to root
// -----------------------------------------------------------------------------
app.use((req, res, next) => {
  if (req.headers.host?.slice(0, 4) === "www.") {
    const newHost = req.headers.host.slice(4);
    res.redirect(301, `${req.protocol}://${newHost}${req.originalUrl}`);
  } else {
    next();
  }
});

//
// Session / Flash
// -----------------------------------------------------------------------------
if (__DEV__) {
  app.enable("trust proxy");
}

const SequelizeStore = connectSessionSequelize(session.Store);
app.use(
  session({
    cookie: {
      domain: config.domain,
      secure: process.env.NODE_ENV === "production",
    },
    saveUninitialized: false,
    secret: config.auth.session.secret,
    store: new SequelizeStore({
      db: sequelize,
    }),
    resave: false,
    proxy: true,
  })
);

app.use(flash());

//
// Authentication
// -----------------------------------------------------------------------------
app.use(passport.initialize());

app.use(
  expressjwt({
    algorithms: ["HS256"],
    secret: config.auth.jwt.secret,
    credentialsRequired: false,
    getToken: (req) => req.cookies.id_token,
    requestProperty: "user",
  })
);

// Error handler for express-jwt
const jwtErrorHandler: ErrorRequestHandler = (err, req, res, next) => {
  // eslint-disable-line no-unused-vars
  if (err instanceof Jwt401Error) {
    req.logout(next);
    res.clearCookie("id_token", { domain: config.domain });
  } else {
    console.error("[express-jwt-error]", req.cookies.id_token);
    // `clearCookie`, otherwise user can't use web-app until cookie expires
    res.clearCookie("id_token");
    next(err);
  }
};
app.use(jwtErrorHandler);

app.use((req, res, next) => {
  const subdomainMatch = req.hostname.match(
    `^(.*)${config.domain.replace(/\./g, "\\.")}`
  );
  if (subdomainMatch && subdomainMatch[1]) {
    // eslint-disable-next-line no-param-reassign
    req.subdomain = subdomainMatch[1];
  }

  if (
    "user" in req &&
    (typeof req.user === "number" || typeof req.user === "string")
  ) {
    User.getSessionUser(req.user)
      .then((user) => {
        if (user) {
          // eslint-disable-next-line no-param-reassign
          req.user = user;
        } else {
          // eslint-disable-next-line no-param-reassign
          delete req.user;
        }
        next();
      })
      .catch((err) => next(err));
  } else {
    next();
  }
});

app.use("/invitation", invitationMiddleware());
app.use("/login", loginMiddleware());
app.use("/password", passwordMiddleware());
app.use("/users", usersMiddleware());

app.get("/logout", (req, res, next) => {
  req.logout((err) => {
    if (err) {
      return next(err);
    }
    return res.redirect("/");
  });
  res.clearCookie("id_token", { domain: config.domain });
});

//
// Register WebSockets
// -----------------------------------------------------------------------------
const wsInstance = expressWs(app, wsServer);
export const wss = wsInstance.getWss();

app.use((req, res, next) => {
  req.broadcast = (teamId, data) => {
    wss.clients?.forEach((client: ExtWebSocket) => {
      if (client.teamId === teamId) {
        client.send(JSON.stringify(data));
      }
    });
  };
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
if (__DEV__) {
  app.use(
    cors({
      credentials: true,
      optionsSuccessStatus: 200, // some legacy browsers (IE11, various SmartTVs) choke on 204
      origin: true,
    })
  );
}
app.use("/api", api());

//
// Register server-side rendering middleware
// -----------------------------------------------------------------------------
const render: RequestHandler = async (req, res, next) => {
  try {
    const stateData: Partial<StateData> = {
      host: config.bsHost,
    };
    if (req.user) {
      stateData.user = req.user;
      stateData.teams = await Team.findAllForUser(req.user);
      stateData.team = req.team;
    }

    const flashes = req.flash();
    const flashKeys = Object.keys(flashes);
    if (flashKeys.length) {
      stateData.flashes = [];
      flashKeys.forEach((k) => {
        flashes[k].forEach((f) => {
          stateData.flashes!.push({
            id: v1(),
            message: f,
            type: k as Flash["type"],
          });
        });
      });
    }
    const css = new Set();

    // Enables critical path CSS rendering
    // https://github.com/kriasoft/isomorphic-style-loader
    const insertCss: InsertCSS = (...styles) => {
      // eslint-disable-next-line no-underscore-dangle
      styles.forEach((style) => css.add(style._getCss()));
    };

    const initialState = makeInitialState(stateData as Required<StateData>);
    const store = configureStore(initialState);

    // Global (context) variables that can be easily accessed from any React component
    // https://facebook.github.io/react/docs/context.html
    const context: AppContext = {
      insertCss,
      googleApiKey: config.googleApiKey!,
      // The twins below are wild, be careful!
      pathname: req.path,
      query: req.query,
      // You can access redux through react-redux connect
      store,
    };

    let router;
    if (req.subdomain) {
      router = routerCreator(teamRoutes);
    } else {
      router = routerCreator(mainRoutes);
    }

    const route = await router.resolve({
      ...context,
      subdomain: req.subdomain,
    });

    if (route.redirect) {
      res.redirect(route.status || 302, route.redirect);
      return;
    }

    const pageTitle = route.title || "Lunch";

    const data: HtmlProps = {
      ...route,
      title: pageTitle,
      ogTitle: route.ogTitle || pageTitle,
      description:
        "A simple lunch voting app for you and your team. Search nearby restaurants, add them to your list, vote for as many as you like, and decide on today’s pick!",
      children: "",
      root: generateUrl(req, req.get("host")!),
    };

    data.children = ReactDOM.renderToString(
      <AppComponent context={context}>{route.component}</AppComponent>
    );
    data.styles = [{ id: "css", cssText: [...css].join("") }];

    const scripts = new Set<string>();
    const addChunk = (chunk: string) => {
      if (chunks[chunk]) {
        chunks[chunk].forEach((asset: string) => scripts.add(asset));
      } else if (__DEV__) {
        throw new Error(`Chunk with name '${chunk}' cannot be found`);
      }
    };
    addChunk("client");
    if (route.chunk) addChunk(route.chunk);
    if (route.chunks) route.chunks.forEach(addChunk);

    data.scripts = Array.from(scripts);
    data.app = {
      apiUrl: config.api.clientUrl,
      googleApiKey: config.googleApiKey!,
      state: initialState,
    };

    const html = ReactDOM.renderToStaticMarkup(<Html {...data} />);
    res.status(route.status || 200);
    res.send(`<!doctype html>${html}`);
  } catch (err) {
    next(err);
  }
};

app.post("/invitation", render);
app.post("/login", render);
app.post("/password", render);
app.post("/users", render);
app.put("/password", render);
app.get("*", render);

//
// Error handling
// -----------------------------------------------------------------------------
const pe = new PrettyError();
pe.skipNodeFiles();
pe.skipPackage("express");

app.use(Honeybadger.errorHandler); // Use *after* all other app middleware.

// eslint-disable-next-line no-unused-vars
const errorHandler: ErrorRequestHandler = (err, req, res, next) => {
  console.error(pe.render(err));
  res.status(err.status || 500);
  if (req.accepts("html") === "html") {
    const html = ReactDOM.renderToStaticMarkup(
      <Html
        title="Internal Server Error"
        description={err.message}
        styles={[{ id: "css", cssText: errorPageStyle._getCss() }]} // eslint-disable-line no-underscore-dangle
      >
        {ReactDOM.renderToString(<ErrorPageWithoutStyle error={err} />)}
      </Html>
    );
    res.send(`<!doctype html>${html}`);
  } else {
    res.json({
      error: true,
      data: {
        message: err.message,
        stack: process.env.NODE_ENV !== "production" ? err.stack : undefined,
      },
    });
  }
};

app.use(errorHandler);

//
// Launch the server
// -----------------------------------------------------------------------------
if (process.env.USE_HTTPS === "true") {
  wsServer.listen(config.wsPort, () => {
    /* eslint-disable no-console */
    console.log(
      `The websockets server is running at https://local.lunch.pink:${config.wsPort}/`
    );
  });
} else {
  wsServer.listen(config.port, () => {
    /* eslint-disable no-console */
    console.log(
      `The server is running at http://local.lunch.pink:${config.port}/`
    );
  });
}

//
// Hot Module Replacement
// -----------------------------------------------------------------------------
/* if ("hot" in module && module.hot) {
  app.hot = module.hot;
  module.hot.accept('./router');
} */

export default app;
