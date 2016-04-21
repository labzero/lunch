import { Router } from 'express';
import { Decision } from '../models';
import { loggedIn, errorCatcher } from './ApiHelper';
import { decisionPosted, decisionDeleted } from '../actions/decisions';

const router = new Router();

router
  .post(
    '/',
    loggedIn,
    async (req, res) => {
      const restaurantId = parseInt(req.body.restaurant_id, 10);
      try {
        return Decision.scope('fromToday').destroy({ where: {} }).then(() =>
          Decision.create({
            restaurant_id: restaurantId
          }).then(obj => {
            const json = obj.toJSON();
            req.wss.broadcast(decisionPosted(json));
            res.status(201).send({ error: false, data: obj });
          }).catch(() => {
            const error = { message: 'Could not save decision.' };
            errorCatcher(res, error);
          })
        ).catch(err => errorCatcher(res, err));
      } catch (err) {
        return errorCatcher(res, err);
      }
    }
  )
  .delete(
    '/',
    loggedIn,
    async (req, res) => {
      Decision.scope('fromToday').destroy({ where: {} }).then(() => {
        req.wss.broadcast(decisionDeleted(req.user.id));
        res.status(204).send({ error: false });
      }).catch(err => errorCatcher(res, err));
    }
  );

export default router;
