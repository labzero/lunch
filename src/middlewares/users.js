import { Router } from 'express';
import { bsHost } from '../config';
import generateToken from '../helpers/generateToken';
import generateUrl from '../helpers/generateUrl';
import { Invitation, User } from '../models';
import transporter from '../mailers/transporter';

export default () => {
  const router = new Router();

  return router
    .post(
      '/',
      async (req, res, next) => {
        if (req.user && req.user.get('superuser')) {
          const { email, name } = req.body;

          try {
            const resetPasswordToken = await generateToken();

            await User.create({
              email,
              name,
              reset_password_token: resetPasswordToken,
              reset_password_sent_at: new Date()
            });

            // returns a promise but we're not going to wait to see if it succeeds.
            Invitation.destroy({ where: { email } }).then(() => {}).catch(() => {});

            await transporter.sendMail({
              name,
              email,
              subject: 'Welcome to Lunch!',
              text: `Hi there!

You've been invited to create a team on Lunch!

To get started, simply visit ${generateUrl(req, bsHost)} and log in with Google using the email address with which you signed up.

If you'd like to log in using a password instead, just follow this URL to generate one:
${generateUrl(req, bsHost, `/password/edit?token=${resetPasswordToken}`)}

Happy Lunching!`
            });

            next();
          } catch (err) {
            req.flash('error', err.message);
            req.session.save(() => {
              res.redirect('/users/new');
            });
          }
        } else {
          next();
        }
      }
    );
};
