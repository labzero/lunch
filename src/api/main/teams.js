import { Router } from 'express';
import cors from 'cors';
import { Team, Role } from '../../models';
import reservedTeamSlugs from '../../constants/reservedTeamSlugs';
import { TEAM_LIMIT, TEAM_SLUG_REGEX } from '../../constants';
import hasRole from '../../helpers/hasRole';
import checkTeamRole from '../helpers/checkTeamRole';
import corsOptionsDelegate from '../helpers/corsOptionsDelegate';
import errorCatcher from '../helpers/errorCatcher';
import loggedIn from '../helpers/loggedIn';

const getTeam = async (req, res, next) => {
  const id = parseInt(req.params.id, 10);
  const team = await Team.findOne({ where: { id } });
  req.team = team; // eslint-disable-line no-param-reassign
  next();
};

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
    )
    .options('/:id', cors(corsOptionsDelegate)) // enable pre-flight request for DELETE/PATCH
    .delete(
      '/:id',
      cors(corsOptionsDelegate),
      loggedIn,
      getTeam,
      checkTeamRole('owner'),
      async (req, res) => {
        try {
          await req.team.destroy();
          return res.status(204).send();
        } catch (err) {
          return errorCatcher(res, err);
        }
      }
    )
    .patch(
      '/:id',
      cors(corsOptionsDelegate),
      loggedIn,
      getTeam,
      checkTeamRole(),
      async (req, res, next) => {
        let fieldCount = 0;

        const allowedFields = [{ name: 'default_zoom', type: 'number' }];
        if (hasRole(req.user, req.team, 'owner')) {
          allowedFields.push({
            name: 'address',
            type: 'string'
          }, {
            name: 'lat',
            type: 'number'
          }, {
            name: 'lng',
            type: 'number',
          }, {
            name: 'name',
            type: 'string'
          });
        }

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
            await req.team.update(filteredPayload);
            res.status(200).json({ error: false, data: req.team });
          } catch (err) {
            next(err);
          }
        } else {
          res.status(422).json({ error: true, data: { message: 'Can\'t update any of the provided fields.' } });
        }
      }
    );
};
