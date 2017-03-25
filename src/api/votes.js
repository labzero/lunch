import { Router } from 'express';
import { Vote } from '../models';
import errorCatcher from './helpers/errorCatcher';
import checkTeamRole from './helpers/checkTeamRole';
import loggedIn from './helpers/loggedIn';
import { votePosted, voteDeleted } from '../actions/restaurants';

export default () => {
  const router = new Router({ mergeParams: true });

  const notFound = (res) => {
    res.status(404).json({ error: true, data: { message: 'Vote not found.' } });
  };

  return router
    .post(
      '/',
      loggedIn,
      checkTeamRole(),
      async (req, res) => {
        const restaurantId = parseInt(req.params.restaurant_id, 10);
        try {
          const count = await Vote.recentForRestaurantAndUser(restaurantId, req.user.id);

          if (count === 0) {
            try {
              const obj = await Vote.create({
                restaurant_id: restaurantId,
                user_id: req.user.id
              });

              const json = obj.toJSON();
              req.wss.broadcast(votePosted(json));
              res.status(201).send({ error: false, data: obj });
            } catch (err) {
              const error = { message: 'Could not vote. Did you already vote today?' };
              errorCatcher(res, error);
            }
          } else {
            const error = { message: 'Could not vote. Did you already vote today?' };
            errorCatcher(res, error);
          }
        } catch (err) {
          errorCatcher(res, err);
        }
      }
    )
    .delete(
      '/:id',
      loggedIn,
      checkTeamRole(),
      async (req, res) => {
        const id = parseInt(req.params.id, 10);

        try {
          const count = await Vote.destroy({ where: { id, user_id: req.user.id } });

          if (count === 0) {
            notFound(res);
          } else {
            req.wss.broadcast(voteDeleted(parseInt(req.params.restaurant_id, 10), req.user.id, id));
            res.status(204).send();
          }
        } catch (err) {
          errorCatcher(res, err);
        }
      }
    );
};
