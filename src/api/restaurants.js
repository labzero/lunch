import { Router } from 'express';
import Restaurant from '../models/Restaurant';

const router = new Router();

router.get('/', async (req, res, next) => {
  try {
    Restaurant.fetchAll().then(all => {
      res.status(200).send(all);
    });
  } catch (err) {
    next(err);
  }
});

export default router;
