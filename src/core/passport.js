/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-2016 Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/**
 * Passport.js reference implementation.
 * The database schema used in this sample is available at
 * https://github.com/membership/membership.db/tree/master/postgres
 */

import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import { User, WhitelistEmail } from '../models';

/**
 * Sign in with Google.
 */
passport.use(new GoogleStrategy(
  {
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: '/login/callback',
    passReqToCallback: true
  },
  (req, accessToken, refreshToken, profile, done) => {
    if (
      typeof profile.emails === 'object' &&
      profile.emails.length !== undefined
    ) {
      const accountEmail = profile.emails.find(email => email.type === 'account');
      return WhitelistEmail.findAll().then(whitelistEmails => {
        if (
          whitelistEmails
            .map(we => we.get('email').toLowerCase())
            .indexOf(accountEmail.value.toLowerCase()) > -1 ||
          // eslint-disable-next-line no-underscore-dangle
          profile._json.domain === process.env.OAUTH_DOMAIN ||
          process.env.OAUTH_DOMAIN === undefined
        ) {
          return User.findOrCreate({ where: { google_id: profile.id } }).spread(user => {
            const userUpdates = {};
            let doUpdates = false;

            if (
              typeof profile.displayName === 'string' &&
              profile.displayName !== user.get('name')
            ) {
              userUpdates.name = profile.displayName;
              doUpdates = true;
            }

            if (accountEmail !== undefined && accountEmail.value !== user.get('email')) {
              userUpdates.email = accountEmail.value;
              doUpdates = true;
            }

            if (doUpdates) {
              return user.update(userUpdates).then(updatedUser => done(null, updatedUser));
            }

            return done(null, user);
          }).catch(err => done(err));
        }
        return done(null, false, { message: 'Please log in using your Lab Zero account.' });
      }).catch(err => done(err));
    }
    return done(null, false, { message: 'No email provided.' });
  }
));

passport.serializeUser((user, cb) => {
  cb(null, user.id);
});

passport.deserializeUser((id, cb) => {
  User.findById(id).then(user => {
    cb(null, user);
  }).catch(err => {
    cb(err);
  });
});

export default passport;
