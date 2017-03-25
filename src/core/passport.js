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

import passport from 'passport';
import { Strategy as GoogleStrategy } from 'passport-google-oauth20';
import { User } from '../models';

/**
 * Sign in with Google.
 */
passport.use(new GoogleStrategy(
  {
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: '/login/callback'
  },
  async (accessToken, refreshToken, profile, done) => {
    if (
      typeof profile.emails === 'object' &&
      profile.emails.length !== undefined
    ) {
      const accountEmail = profile.emails.find(email => email.type === 'account');
      try {
        let user = await User.findOne({
          where: { google_id: profile.id }
        });

        const userUpdates = {};
        let doUpdates = false;

        // might not have been linked with Google yet
        if (!user) {
          user = await User.findOne({
            where: { email: accountEmail.value }
          });
          userUpdates.google_id = profile.id;
          doUpdates = true;
        }

        if (!user) {
          return done(null, false, { message: 'User not found.' });
        }

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
          return user.update(userUpdates).then(updatedUser => done(null, updatedUser.id));
        }

        return done(null, user.id);
      } catch (err) {
        done(err);
      }
    }
    return done(null, false, { message: 'No email provided.' });
  }
));

passport.serializeUser((userId, cb) => cb(null, userId));

export default passport;
