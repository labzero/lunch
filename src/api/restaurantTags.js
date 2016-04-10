import { Router } from 'express';
import { Tag, RestaurantTag } from '../models';
import { loggedIn, errorCatcher } from './ApiHelper';
import {
  postedNewTagToRestaurant,
  postedTagToRestaurant,
  deletedTagFromRestaurant
} from '../actions/restaurants';

const router = new Router({ mergeParams: true });

router
  .post(
    '/',
    loggedIn,
    async (req, res) => {
      const restaurantId = parseInt(req.params.restaurant_id, 10);
      const alreadyAddedError = () => {
        const error = { message: 'Could not add tag to restaurant. Is it already added?' };
        errorCatcher(res, error);
      };
      if (req.body.name !== undefined) {
        Tag.findOrCreate({
          where: {
            name: req.body.name.toLowerCase().trim()
          }
        }).spread(tag =>
          RestaurantTag.create({
            restaurant_id: restaurantId,
            tag_id: tag.id
          }).then(() => {
            const json = tag.toJSON();
            req.wss.broadcast(postedNewTagToRestaurant(restaurantId, json, req.user.id));
            res.status(201).send({ error: false, data: json });
          }).catch(alreadyAddedError)
        ).catch(err => {
          errorCatcher(res, err);
        });
      } else if (req.body.id !== undefined) {
        const id = parseInt(req.body.id, 10);
        RestaurantTag.create({
          restaurant_id: restaurantId,
          tag_id: id
        }).then(obj => {
          const json = obj.toJSON();
          req.wss.broadcast(postedTagToRestaurant(restaurantId, id, req.user.id));
          res.status(201).send({ error: false, data: json });
        }).catch(alreadyAddedError);
      } else {
        errorCatcher(res);
      }
    }
  )
  .delete(
    '/:id',
    loggedIn,
    async (req, res) => {
      const id = parseInt(req.params.id, 10);
      const restaurantId = parseInt(req.params.restaurant_id, 10);
      RestaurantTag.destroy({ where: { restaurant_id: restaurantId, tag_id: id } }).then(() => {
        req.wss.broadcast(deletedTagFromRestaurant(restaurantId, id, req.user.id));
        res.status(204).send({ error: false });
      }).catch(err => errorCatcher(res, err));
    }
  );

export default router;
