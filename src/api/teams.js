import { Router } from 'express';
import reservedUsernames from 'reserved-usernames';
import { Team, Role } from '../models';
import errorCatcher from './helpers/errorCatcher';
import getTeamIfHasRole from './helpers/getTeamIfHasRole';
import loggedIn from './helpers/loggedIn';
import decisionApi from './decisions';
import restaurantApi from './restaurants';
import tagApi from './tags';
import userApi from './users';

export default () => {
  const router = new Router();

  return router
    .post(
      '/',
      loggedIn,
      async (req, res) => {
        const { name, slug } = req.body;
        const error = { message: 'Could not create new team. It might already exist.' };

        if (reservedUsernames.indexOf(slug) > -1) {
          return errorCatcher(res, error);
        }

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
          return res.status(201).send({ error: false, data: json });
        } catch (e) {
          return errorCatcher(res, error);
        }
      }
    )
    .use('/:slug/decisions', decisionApi())
    .use('/:slug/restaurants', restaurantApi())
    .use('/:slug/tags', tagApi())
    .use('/:slug/users', userApi())
    .ws('/:slug', async (ws, req) => {
      const team = await getTeamIfHasRole(req.user, req.params.slug);

      if (!team) {
        ws.close(1008, 'Not authorized for this team.');
      } else {
        ws.teamId = team.id; // eslint-disable-line no-param-reassign
      }
    });
};
