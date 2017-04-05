import { Router } from 'express';
import cors from 'cors';
import { Team, Role } from '../../models';
import reservedTeamSlugs from '../../constants/reservedTeamSlugs';
import { TEAM_LIMIT, TEAM_SLUG_REGEX } from '../../constants';
import checkTeamRole from '../helpers/checkTeamRole';
import corsOptionsDelegate from '../helpers/corsOptionsDelegate';
import loggedIn from '../helpers/loggedIn';

const error409 = (res) =>
  res.status(409).json({ error: true, data: { message: 'Could not create new team. It might already exist.' } });

export default () => {
  const router = new Router();

  return router
    .post(
      '/',
      loggedIn,
      async (req, res, next) => {
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
          return next(err);
        }
      }
    )
    .options('/:id', cors(corsOptionsDelegate)) // enable pre-flight request for DELETE request
    .delete(
      '/:id',
      cors(corsOptionsDelegate),
      loggedIn,
      async (req, res, next) => {
        const id = parseInt(req.params.id, 10);
        const team = await Team.findOne({ where: { id } });
        req.team = team; // eslint-disable-line no-param-reassign
        next();
      },
      checkTeamRole('owner'),
      async (req, res, next) => {
        try {
          await req.team.destroy();
          return res.status(204).send();
        } catch (err) {
          return next(err);
        }
      }
    );
};
