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
    if (req.query.state) {
      res.redirect(generateUrl(req, `${req.query.state}.${bsHost}`));
    } else {
      res.redirect('/');
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
        res.redirect(301, generateUrl(req, bsHost, `/login/google?team=${req.subdomain}`));
      } else {
        const options = { scope: ['email', 'profile'], session: false };
        if (req.query.team) {
          options.state = req.query.team;
        }
        passport.authenticate('google', options)(req, res, next);
      }
    },
  ).get('/google/callback',
    (req, res, next) => {
      const options = { failureRedirect: '/coming-soon', session: false };
      passport.authenticate('google', options)(req, res, next);
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
