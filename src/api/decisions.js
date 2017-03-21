import { Router } from 'express';
import { Decision } from '../models';
import errorCatcher from './helpers/errorCatcher';
import checkTeamRole from './helpers/checkTeamRole';
import loggedIn from './helpers/loggedIn';
import { decisionPosted, decisionDeleted } from '../actions/decisions';

const router = new Router({ mergeParams: true });

router
  .get(
    '/fromToday',
    loggedIn,
    checkTeamRole(),
    async (req, res) => {
      try {
        const decision = await Decision.scope('fromToday').findOne({ where: { team_id: req.team.id } });

        res.status(200).json({ error: false, data: decision });
      } catch (err) {
        errorCatcher(res, err);
      }
    }
  )
  .post(
    '/',
    loggedIn,
    checkTeamRole(),
    async (req, res) => {
      const restaurantId = parseInt(req.body.restaurant_id, 10);
      try {
        await Decision.scope('fromToday').destroy({ where: { team_id: req.team.id } });

        try {
          const obj = await Decision.create({
            restaurant_id: restaurantId,
            team_id: req.team.id
          });

          const json = obj.toJSON();
          req.wss.broadcast(decisionPosted(json, req.user.id));
          res.status(201).send({ error: false, data: obj });
        } catch (err) {
          const error = { message: 'Could not save decision.' };
          errorCatcher(res, error);
        }
      } catch (err) {
        errorCatcher(res, err);
      }
    }
  )
  .delete(
    '/fromToday',
    loggedIn,
    checkTeamRole(),
    async (req, res) => {
      const restaurantId = parseInt(req.body.restaurant_id, 10);
      try {
        await Decision.scope('fromToday').destroy({ where: { team_id: req.team.id } });

        req.wss.broadcast(decisionDeleted(restaurantId, req.user.id));
        res.status(204).send({ error: false });
      } catch (err) {
        errorCatcher(res, err);
      }
    }
  );

export default router;
