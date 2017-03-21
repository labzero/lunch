import { Router } from 'express';
import { Team, Role } from '../models';
import errorCatcher from './helpers/errorCatcher';
import loggedIn from './helpers/loggedIn';
import decisionApi from './decisions';
import restaurantApi from './restaurants';
import tagApi from './tags';
import userApi from './users';

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
  .use('/:slug/decisions', decisionApi)
  .use('/:slug/restaurants', restaurantApi)
  .use('/:slug/tags', tagApi)
  .use('/:slug/users', userApi);

export default router;
