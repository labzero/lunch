import { Router } from 'express';
import dayjs from 'dayjs';
import { DataTypes } from '../../models/db';
import { Decision } from '../../models';
import checkTeamRole from '../helpers/checkTeamRole';
import loggedIn from '../helpers/loggedIn';
import { decisionPosted, decisionsDeleted } from '../../actions/decisions';

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
              [DataTypes.Op.gt]: dayjs().subtract(days, 'days').toDate()
            };
          }

          const decisions = await Decision.findAll(opts);

          res.status(200).json({ error: false, data: decisions });
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
          const destroyOpts = { where: { team_id: req.team.id } };
          const daysAgo = parseInt(req.body.daysAgo, 10);
          let MaybeScopedDecision = Decision;
          if (daysAgo > 0) {
            destroyOpts.where.created_at = {
              [DataTypes.Op.gt]: dayjs().subtract(daysAgo, 'days').subtract(12, 'hours').toDate(),
              [DataTypes.Op.lt]: dayjs().subtract(daysAgo, 'days').add(12, 'hours').toDate(),
            };
          } else {
            MaybeScopedDecision = MaybeScopedDecision.scope('fromToday');
          }

          const deselected = await MaybeScopedDecision.findAll(destroyOpts);
          await MaybeScopedDecision.destroy(destroyOpts);

          try {
            const createOpts = {
              restaurant_id: restaurantId,
              team_id: req.team.id
            };
            if (daysAgo > 0) {
              createOpts.created_at = dayjs().subtract(daysAgo, 'days').toDate();
            }
            const obj = await Decision.create(createOpts);

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
        try {
          const decisions = await Decision.scope('fromToday').findAll({ where: { team_id: req.team.id } });
          await Decision.scope('fromToday').destroy({ where: { team_id: req.team.id } });

          req.wss.broadcast(req.team.id, decisionsDeleted(decisions, req.user.id));
          res.status(204).send();
        } catch (err) {
          next(err);
        }
      }
    );
};
