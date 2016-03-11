import { Router } from 'express';
import Tag from '../models/Tag';
import RestaurantTag from '../models/RestaurantTag';
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
        Tag.create({
          name: req.body.name
        }).then(tag =>
          RestaurantTag.create({
            restaurant_id: restaurantId,
            tag_id: tag.id
          }).then(() => {
            const json = tag.toJSON();
            req.wss.broadcast(postedNewTagToRestaurant(restaurantId, json));
            res.status(201).send({ error: false, data: json });
          }).catch(alreadyAddedError)
        ).catch(() => {
          const error = { message: 'Could not add new tag. Is it already added?' };
          errorCatcher(res, error);
        });
      } else if (req.body.id !== undefined) {
        const id = parseInt(req.body.id, 10);
        RestaurantTag.create({
          restaurant_id: restaurantId,
          tag_id: id
        }).then(obj => {
          const json = obj.toJSON();
          req.wss.broadcast(postedTagToRestaurant(restaurantId, id));
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
        req.wss.broadcast(deletedTagFromRestaurant(restaurantId, id));
        res.status(204).send({ error: false });
      }).catch(err => errorCatcher(res, err));
    }
  );

export default router;
