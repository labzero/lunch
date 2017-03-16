import { Router } from 'express';
import { Decision } from '../models';
import errorCatcher from './helpers/errorCatcher';
import loggedIn from './helpers/loggedIn';
import { decisionPosted, decisionDeleted } from '../actions/decisions';

const router = new Router();

router
  .post(
    '/',
    loggedIn,
    async (req, res) => {
      const restaurantId = parseInt(req.body.restaurant_id, 10);
      try {
        try {
          await Decision.scope('fromToday').destroy({ where: {} });

          try {
            const obj = await Decision.create({
              restaurant_id: restaurantId
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
      } catch (err) {
        errorCatcher(res, err);
      }
    }
  )
  .delete(
    '/',
    loggedIn,
    async (req, res) => {
      const restaurantId = parseInt(req.body.restaurant_id, 10);
      try {
        await Decision.scope('fromToday').destroy({ where: {} });

        req.wss.broadcast(decisionDeleted(restaurantId, req.user.id));
        res.status(204).send({ error: false });
      } catch (err) {
        errorCatcher(res, err);
      }
    }
  );

export default router;
