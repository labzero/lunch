import { Router } from 'express';
import { Tag } from '../models';
import { loggedIn, errorCatcher } from './ApiHelper';
import { tagDeleted } from '../actions/tags';

const router = new Router();

router
  .get('/', async (req, res) => {
    Tag.scope('orderedByRestaurant').findAll().then(all => {
      res.status(200).send({ error: false, data: all });
    }).catch(err => errorCatcher(res, err));
  })
  .delete(
    '/:id',
    loggedIn,
    async (req, res) => {
      const id = parseInt(req.params.id, 10);
      Tag.destroy({ where: { id } }).then(() => {
        req.wss.broadcast(tagDeleted(id));
        res.status(204).send({ error: false });
      }).catch(err => errorCatcher(res, err));
    }
  );

export default router;
