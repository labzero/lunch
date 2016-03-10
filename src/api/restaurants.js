import { Router } from 'express';
import Restaurant from '../models/Restaurant';
import Vote from '../models/Vote';
import { loggedIn, errorCatcher } from './ApiHelper';
import { restaurantPosted, restaurantDeleted } from '../actions/restaurants';
import voteApi from './votes';

const router = new Router();

router
  .get('/', async (req, res) => {
    Restaurant.findAll({ include: [Vote] }).then(all => {
      res.status(200).send({ error: false, data: all });
    }).catch(err => errorCatcher(res, err));
  })
  .post(
    '/',
    loggedIn,
    async (req, res) => {
      const { name, place_id, lat, lng } = req.body;
      let { address } = req.body;
      address = address.replace(`${name}, `, '');
      Restaurant.create({
        name,
        place_id,
        address,
        lat,
        lng,
        votes: []
      }, { include: [Vote] }).then(obj => {
        const json = obj.toJSON();
        req.wss.broadcast(restaurantPosted(json));
        res.status(201).send({ error: false, data: json });
      }).catch(() => {
        const error = { message: 'Could not save new restaurant. Has it already been added?' };
        errorCatcher(res, error);
      });
    }
  )
  .delete(
    '/:id',
    loggedIn,
    async (req, res) => {
      const id = parseInt(req.params.id, 10);
      Restaurant.destroy({ where: { id } }).then(() => {
        req.wss.broadcast(restaurantDeleted(id));
        res.status(204).send({ error: false });
      }).catch(err => errorCatcher(res, err));
    }
  )
  .use('/:restaurant_id/votes', voteApi);

export default router;
