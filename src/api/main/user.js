import { Router } from 'express';
import getPasswordError from '../../helpers/getPasswordError';
import getUserPasswordUpdates from '../../helpers/getUserPasswordUpdates';
import { User } from '../../models';
import loggedIn from '../helpers/loggedIn';

export default () => {
  const router = new Router();

  return router
    .patch(
      '/',
      loggedIn,
      async (req, res, next) => {
        let fieldCount = 0;

        const allowedFields = [
          {
            name: 'name',
            type: 'string'
          }, {
            name: 'email',
            type: 'string'
          }, {
            name: 'password',
            type: 'string',
          }
        ];

        const filteredPayload = {};

        allowedFields.forEach(f => {
          const value = req.body[f.name];
          if (value && typeof value === f.type) { // eslint-disable-line valid-typeof
            filteredPayload[f.name] = value;
            fieldCount += 1;
          }
        });

        if (fieldCount) {
          try {
            if (filteredPayload.password) {
              const passwordError = getPasswordError(filteredPayload.password);
              if (passwordError) {
                return res.status(422).json({ error: true, data: { message: passwordError } });
              }
              const passwordUpdates = await getUserPasswordUpdates(
                req.user,
                filteredPayload.password
              );
              Object.assign(
                filteredPayload,
                passwordUpdates
              );
              delete filteredPayload.password;
            }
            if (filteredPayload.name) {
              if (req.user.get('name') !== filteredPayload.name) {
                filteredPayload.namedChanged = true;
              }
            }
            await req.user.update(filteredPayload);

            // get user again because now req.user contains password fields
            const user = await User.getSessionUser(req.user.get('id'));

            return res.status(200).json({ error: false, data: user });
          } catch (err) {
            if (err.name === 'SequelizeUniqueConstraintError') {
              return res.status(422).json({ error: true, data: { message: 'Email is already taken.' } });
            }
            return next(err);
          }
        }
        return res.status(422).json({ error: true, data: { message: 'Can\'t update any of the provided fields.' } });
      }
    );
};
