import { Router } from 'express';
import { Vote } from '../../models';
import { sequelize } from '../../models/db';
import checkTeamRole from '../helpers/checkTeamRole';
import loggedIn from '../helpers/loggedIn';
import { votePosted, voteDeleted } from '../../actions/restaurants';

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
      async (req, res, next) => {
        const restaurantId = parseInt(req.params.restaurant_id, 10);
        try {
          const result = await sequelize.transaction(async (t) => {
            const count = await Vote.recentForRestaurantAndUser(restaurantId, req.user.id, t);

            if (count === 0) {
              return Vote.create({
                restaurant_id: restaurantId,
                user_id: req.user.id
              }, { transaction: t });
            }
            return '409';
          });
          if (result === '409') {
            res.status(409).json({ error: true, data: { message: 'Could not vote. Did you already vote today?' } });
          } else {
            try {
              const json = result.toJSON();
              req.wss.broadcast(req.team.id, votePosted(json));
              res.status(201).send({ error: false, data: result });
            } catch (err) {
              next(err);
            }
          }
        } catch (err) {
          next(err);
        }
      }
    )
    .delete(
      '/:id',
      loggedIn,
      checkTeamRole(),
      async (req, res, next) => {
        const id = parseInt(req.params.id, 10);

        try {
          const count = await Vote.destroy({ where: { id, user_id: req.user.id } });

          if (count === 0) {
            notFound(res);
          } else {
            req.wss.broadcast(
              req.team.id,
              voteDeleted(parseInt(req.params.restaurant_id, 10), req.user.id, id)
            );
            res.status(204).send();
          }
        } catch (err) {
          next(err);
        }
      }
    );
};
