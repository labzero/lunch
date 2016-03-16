import { Router } from 'express';
import { Tag } from '../models';
import { errorCatcher } from './ApiHelper';

const router = new Router();

router
  .get('/', async (req, res) => {
    Tag.scope('orderedByRestaurant').findAll().then(all => {
      res.status(200).send({ error: false, data: all });
    }).catch(err => errorCatcher(res, err));
  });

export default router;
