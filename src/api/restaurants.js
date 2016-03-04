import { Router } from 'express';
import Restaurant from '../models/Restaurant';

const router = new Router();

const loggedIn = (req, res, next) => {
  if (req.user) {
    next();
  } else {
    res.redirect('/login');
  }
};

const errorCatcher = (res, err) => {
  res.status(500).json({ error: true, data: { message: err.message } });
};

router
  .get('/', async (req, res) => {
    Restaurant.fetchAll().then(all => {
      res.status(200).send({ error: false, data: all });
    }).catch(err => errorCatcher(res, err));
  })
  .post(
    '/',
    loggedIn,
    async (req, res) => {
      const { name, place_id, address, lat, lng } = req.body;
      new Restaurant({
        name,
        place_id,
        address,
        lat,
        lng
      }).save().then(obj => {
        res.status(201).send({ error: false, data: obj });
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
      new Restaurant({ id: req.params.id }).destroy().then(() => {
        res.status(204).send({ error: false });
      }).catch(err => errorCatcher(res, err));
    }
  );

export default router;
