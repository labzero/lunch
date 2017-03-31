import { Router } from 'express';
import { Team, Role } from '../../models';
import reservedTeamSlugs from '../../constants/reservedTeamSlugs';
import { TEAM_LIMIT, TEAM_SLUG_REGEX } from '../../constants';
import errorCatcher from '../helpers/errorCatcher';
import loggedIn from '../helpers/loggedIn';

const error409 = (res) =>
  res.status(409).json({ error: true, data: { message: 'Could not create new team. It might already exist.' } });

export default () => {
  const router = new Router();

  return router
    .post(
      '/',
      loggedIn,
      async (req, res) => {
        const { address, lat, lng, name, slug } = req.body;

        if (req.user.roles.length >= TEAM_LIMIT) {
          return res.status(403).json({ error: true, data: { message: `You currently can't join more than ${TEAM_LIMIT} teams.` } });
        }

        if (reservedTeamSlugs.indexOf(slug) > -1) {
          return error409(res);
        }

        if (!slug.match(TEAM_SLUG_REGEX)) {
          return res.status(422).json({ error: true, data: { message: 'Team URL doesn\'t match the criteria.' } });
        }

        try {
          const obj = await Team.create({
            address,
            lat,
            lng,
            name,
            slug,
            roles: [{
              user_id: req.user.id,
              type: 'owner'
            }]
          }, { include: [Role] });

          const json = obj.toJSON();
          return res.status(201).send({ error: false, data: json });
        } catch (err) {
          if (err.name === 'SequelizeUniqueConstraintError') {
            return error409(res);
          }
          return errorCatcher(res, err);
        }
      }
    );
};
