import { Router } from 'express';
import Restaurant from '../models/Restaurant';

const router = new Router();

router
  .get('/', async (req, res, next) => {
    try {
      Restaurant.fetchAll().then(all => {
        res.status(200).send(all);
      });
    } catch (err) {
      next(err);
    }
  })
  .post('/', async (req, res, next) => {
    try {
      new Restaurant({ name: req.body.name }).save().then(obj => {
        res.status(201).send(obj);
      });
    } catch (err) {
      next(err);
    }
  })
  .delete('/:id', async (req, res, next) => {
    try {
      new Restaurant({ id: req.params.id }).destroy().then(() => {
        res.status(204).send();
      });
    } catch (err) {
      next(err);
    }
  });

export default router;
