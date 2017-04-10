import { Router } from 'express';
import bcrypt from 'bcrypt';
import commonPassword from 'common-password';
import { bsHost } from '../config';
import { PASSWORD_MIN_LENGTH } from '../constants';
import generateUrl from '../helpers/generateUrl';
import transporter from '../mailers/transporter';
import { User } from '../models';

export default () => {
  const router = new Router();

  router.post('/', async (req, res, next) => {
    try {
      const user = await User.findOne({ where: { email: req.body.email } });
      if (user) {
        const resetPasswordToken = await User.generateToken();
        await user.update({
          reset_password_token: resetPasswordToken,
          reset_password_sent_at: new Date()
        });
        await transporter.sendMail({
          name: user.name,
          email: user.email,
          subject: 'Password reset instructions',
          text: `Hi there!

A password reset link was requested for your account. If you'd like to enter a new password, do so here: 
${generateUrl(req, bsHost, `/password/edit?token=${resetPasswordToken}`)}
This link will expire in one day.

Happy Lunching!`
        });
      }
      next();
    } catch (err) {
      next(err);
    }
  }).put('/', async (req, res, next) => {
    try {
      const user = await User.findOne({ where: { reset_password_token: req.body.token } });
      if (!user || !user.resetPasswordValid()) {
        res.redirect('/password/new');
      } else if (!req.body.password || req.body.password.length < PASSWORD_MIN_LENGTH) {
        req.flash('error', `Password must be at least ${PASSWORD_MIN_LENGTH} characters long.`);
        req.session.save(() => {
          res.redirect(`/password/edit?token=${req.body.token}`);
        });
      } else if (commonPassword(req.body.password)) {
        req.flash('error', 'The password you provided is too common. Please try another one.');
        req.session.save(() => {
          res.redirect(`/password/edit?token=${req.body.token}`);
        });
      } else {
        const encryptedPassword = await bcrypt.hash(req.body.password, 10);
        const updates = {
          encrypted_password: encryptedPassword,
          reset_password_token: null,
          reset_password_sent_at: null
        };
        if (!user.get('confirmed_at')) {
          updates.confirmed_at = new Date();
        }
        await user.update(updates);
        next();
      }
    } catch (err) {
      next(err);
    }
  }).get('/edit', async (req, res, next) => {
    try {
      const user = await User.findOne({ where: { reset_password_token: req.query.token } });
      if (!user || !user.resetPasswordValid()) {
        res.redirect('/password/new');
      } else {
        next();
      }
    } catch (err) {
      next(err);
    }
  });

  return router;
};
