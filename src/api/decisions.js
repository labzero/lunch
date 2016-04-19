import { Router } from 'express';
import { Vote } from '../models';
import { loggedIn, errorCatcher } from './ApiHelper';
import { votePosted, voteDeleted } from '../actions/restaurants';

const router = new Router({ mergeParams: true });

router
  .post(
    '/',
    loggedIn,
    async (req, res) => {
      const restaurantId = parseInt(req.params.restaurant_id, 10);
      return Vote.recentForRestaurantAndUser(restaurantId, req.user.id).then(count => {
        if (count === 0) {
          return Vote.create({
            restaurant_id: restaurantId,
            user_id: req.user.id
          }).then(obj => {
            const json = obj.toJSON();
            req.wss.broadcast(votePosted(json));
            res.status(201).send({ error: false, data: obj });
          }).catch(() => {
            const error = { message: 'Could not vote. Did you already vote today?' };
            errorCatcher(res, error);
          });
        }
        const error = { message: 'Could not vote. Did you already vote today?' };
        return errorCatcher(res, error);
      }).catch(err => errorCatcher(res, err));
    }
  )
  .delete(
    '/:id',
    loggedIn,
    async (req, res) => {
      const id = parseInt(req.params.id, 10);
      Vote.destroy({ where: { id } }).then(() => {
        req.wss.broadcast(voteDeleted(parseInt(req.params.restaurant_id, 10), req.user.id, id));
        res.status(204).send({ error: false });
      }).catch(err => errorCatcher(res, err));
    }
  );

export default router;
