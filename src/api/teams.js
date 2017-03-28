import { Router } from 'express';
import { Team, Role } from '../models';
import reservedTeamSlugs from '../constants/reservedTeamSlugs';
import { TEAM_SLUG_REGEX } from '../constants';
import errorCatcher from './helpers/errorCatcher';
import loggedIn from './helpers/loggedIn';

export default () => {
  const router = new Router();

  return router
    .post(
      '/',
      loggedIn,
      async (req, res) => {
        const { name, slug } = req.body;
        const error = { message: 'Could not create new team. It might already exist.' };

        if (reservedTeamSlugs.indexOf(slug) > -1) {
          return errorCatcher(res, error);
        }

        if (!slug.match(TEAM_SLUG_REGEX)) {
          return errorCatcher(res, {
            message: 'Team URL doesn\'t meet the criteria.'
          });
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
    );
};
