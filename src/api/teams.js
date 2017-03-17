import { Router } from 'express';
import { Team, Role } from '../models';
import errorCatcher from './helpers/errorCatcher';
import loggedIn from './helpers/loggedIn';
import restaurantApi from './restaurants';

const router = new Router();

router
  .post(
    '/',
    loggedIn,
    async (req, res) => {
      const { name, slug } = req.body;

      try {
        const obj = await Team.create({
          name,
          slug,
          roles: [{
            user_id: req.user.id,
            type: 'owner'
          }]
        }, { include: [Role] });

        const json = obj.toJSON();
        res.status(201).send({ error: false, data: json });
      } catch (e) {
        // eslint-disable-next-line no-console
        console.error(e);
        const error = { message: 'Could not create new team. It might already exist.' };
        errorCatcher(res, error);
      }
    }
  )
  .use('/:slug/restaurants', restaurantApi);

export default router;