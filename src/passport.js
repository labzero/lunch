/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/**
 * Passport.js reference implementation.
 * The database schema used in this sample is available at
 * https://github.com/membership/membership.db/tree/master/postgres
 */

import bcrypt from 'bcrypt';
import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import { Strategy as LocalStrategy } from 'passport-local';
import { User } from './models';

/**
 * Sign in with Google.
 */
passport.use(new GoogleStrategy(
  {
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: '/login/google/callback',
    userProfileURL: 'https://www.googleapis.com/oauth2/v3/userinfo',
  },
  async (accessToken, refreshToken, profile, done) => {
    if (
      /* eslint-disable no-underscore-dangle */
      profile._json
      && profile._json.email
    ) {
      const accountEmail = profile._json.email;
      /* eslint-enable no-underscore-dangle */

      try {
        // WARNING: this retrieves all attributes (incl. password).
        // But we only provide the ID to passport.
        let user = await User.findOne({
          where: { googleId: profile.id }
        });

        const userUpdates = {};
        let doUpdates = false;

        // might not have been linked with Google yet
        if (!user) {
          user = await User.findOne({
            where: { email: accountEmail }
          });
          userUpdates.googleId = profile.id;
          doUpdates = true;
        }

        if (!user) {
          return done(null, false, accountEmail);
        }

        if (
          typeof profile.displayName === 'string'
          && profile.displayName !== user.get('name')
          && !user.get('namedChanged')
        ) {
          userUpdates.name = profile.displayName;
          doUpdates = true;
        }

        if (doUpdates) {
          const updatedUser = await user.update(userUpdates);
          return done(null, updatedUser.get('id'));
        }

        return done(null, user.get('id'));
      } catch (err) {
        return done(err);
      }
    }
    return done(null, false);
  }
));

/**
 * Sign in locally.
 */
passport.use(new LocalStrategy({
  usernameField: 'email',
  passReqToCallback: true
}, async (req, email, password, done) => {
  const failureData = 'Invalid email or password.';
  try {
    // WARNING: this retrieves all attributes (incl. password).
    // But we only provide the ID to passport.
    const user = await User.findOne({ where: { email } });
    if (!user || !user.get('encryptedPassword')) {
      return done(null, false, failureData);
    }
    const passwordValid = await bcrypt.compare(password, user.get('encryptedPassword'));
    if (passwordValid) {
      return done(null, user.get('id'));
    }
    return done(null, false, failureData);
  } catch (err) {
    return done(err);
  }
}));

passport.serializeUser((userId, cb) => cb(null, userId));

export default passport;
