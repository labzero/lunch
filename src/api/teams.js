import { Router } from 'express';
import { Team, Role } from '../models';
import { loggedIn, errorCatcher } from './ApiHelper';

const router = new Router();

router
  .post(
    '/',
    loggedIn,
    async (req, res) => {
      const { name, slug } = req.body;

      Team.create({
        name,
        slug,
        roles: [{
          user_id: req.user.id,
          type: 'owner'
        }]
      }, { include: [Role] }).then(obj => {
        const json = obj.toJSON();
        res.status(201).send({ error: false, data: json });
      }).catch((e) => {
        // eslint-disable-next-line no-console
        console.error(e);
        const error = { message: 'Could not create new team. It might already exist.' };
        errorCatcher(res, error);
      });
    }
  );

export default router;
