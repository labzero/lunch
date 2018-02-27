import { Router } from 'express';
import moment from 'moment';
import { DataTypes } from '../../models/db';
import { Decision } from '../../models';
import checkTeamRole from '../helpers/checkTeamRole';
import loggedIn from '../helpers/loggedIn';
import { decisionPosted, decisionDeleted } from '../../actions/decisions';

export default () => {
  const router = new Router({ mergeParams: true });

  return router
    .get(
      '/',
      loggedIn,
      checkTeamRole(),
      async (req, res, next) => {
        try {
          const opts = { where: { team_id: req.team.id } };
          const days = parseInt(req.query.days, 10);
          if (!Number.isNaN(days)) {
            opts.where.created_at = {
              [DataTypes.Op.gt]: moment().subtract(days, 'days').toDate()
            }
          }
      
          const decisions = await Decision.findAll(opts);

          res.status(200).json({ error: false, data: decisions });
        } catch (err) {
          next(err);
        }
      }
    )
    .get(
      '/fromToday',
      loggedIn,
      checkTeamRole(),
      async (req, res, next) => {
        try {
          const decision = await Decision.scope('fromToday').findOne({ where: { team_id: req.team.id } });

          res.status(200).json({ error: false, data: decision });
        } catch (err) {
          next(err);
        }
      }
    )
    .post(
      '/',
      loggedIn,
      checkTeamRole(),
      async (req, res, next) => {
        const restaurantId = parseInt(req.body.restaurant_id, 10);
        try {
          const deselected = await Decision.scope('fromToday').findAll({ where: { team_id: req.team.id } });
          await Decision.scope('fromToday').destroy({ where: { team_id: req.team.id } });

          try {
            const obj = await Decision.create({
              restaurant_id: restaurantId,
              team_id: req.team.id
            });

            const json = obj.toJSON();
            req.wss.broadcast(req.team.id, decisionPosted(json, deselected, req.user.id));
            res.status(201).send({ error: false, data: obj });
          } catch (err) {
            const error = { message: 'Could not save decision.' };
            next(error);
          }
        } catch (err) {
          next(err);
        }
      }
    )
    .delete(
      '/fromToday',
      loggedIn,
      checkTeamRole(),
      async (req, res, next) => {
        const restaurantId = parseInt(req.body.restaurant_id, 10);
        try {
          await Decision.scope('fromToday').destroy({ where: { team_id: req.team.id } });

          req.wss.broadcast(req.team.id, decisionDeleted(restaurantId, req.user.id));
          res.status(204).send();
        } catch (err) {
          next(err);
        }
      }
    );
};
