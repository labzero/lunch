import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { auth, bsHost, domain } from '../config';
import generateUrl from '../helpers/generateUrl';
import passport from '../core/passport';

const setCookie = (req, res, next) => {
  if (req.user) {
    const expiresIn = 60 * 60 * 24 * 180; // 180 days
    const token = jwt.sign(req.user, auth.jwt.secret);
    res.cookie('id_token', token, {
      domain,
      maxAge: 1000 * expiresIn,
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production'
    });
    let state = {};
    if (req.query.state) {
      state = JSON.parse(req.query.state);
    }
    let path;
    if (state.next) {
      path = state.next;
    } else if (req.query.next) {
      path = req.query.next;
    }
    if (state.team) {
      res.redirect(generateUrl(req, `${state.team}.${bsHost}`, path));
    } else {
      res.redirect(path || '/');
    }
  } else {
    next();
  }
};

export default () => {
  const router = new Router();

  router.get(
    '/google',
    (req, res, next) => {
      if (req.subdomain) {
        let nextQuery = '';
        if (req.query.next) {
          nextQuery = `&next=${req.query.next}`;
        }
        res.redirect(301, generateUrl(req, bsHost, `/login/google?team=${req.subdomain}${nextQuery}`));
      } else {
        const options = { scope: ['email', 'profile'], session: false };
        options.state = JSON.stringify({
          team: req.query.team,
          next: req.query.next
        });
        passport.authenticate('google', options)(req, res, next);
      }
    },
  ).get('/google/callback',
    (req, res, next) => {
      passport.authenticate('google', { session: false }, (err, user, email) => {
        if (err) { return next(err); }
        if (!user) {
          let path = '/invitation/new';
          if (email) {
            path = `${path}?email=${email}`;
          }
          return res.redirect(path);
        }
        return req.logIn(user, (logInErr) => {
          if (logInErr) { return next(logInErr); }
          return next();
        });
      })(req, res, next);
    },
    setCookie
  ).post('/',
    (req, res, next) => {
      passport.authenticate('local', { session: false }, (err, user, info) => {
        if (err) { return next(err); }
        if (!user) {
          req.flash('error', info); // eslint-disable-line no-param-reassign
          return next();
        }
        return req.logIn(user, (logInErr) => {
          if (logInErr) { return next(logInErr); }
          return next();
        });
      })(req, res, next);
    },
    setCookie
  );

  return router;
};
