import { Router } from 'express';
import Vote from '../models/Vote';
import { loggedIn, errorCatcher } from './ApiHelper';

const router = new Router({ mergeParams: true });

router
  .post(
    '/',
    loggedIn,
    async (req, res) => {
      Vote.create({
        restaurant_id: parseInt(req.params.restaurant_id, 10),
        user_id: req.user.id
      }).then(obj => {
        res.status(201).send({ error: false, data: obj });
      }).catch(() => {
        const error = { message: 'Could not vote. Did you already vote today?' };
        errorCatcher(res, error);
      });
    }
  )
  .delete(
    '/:id',
    loggedIn,
    async (req, res) => {
      Vote.destroy({ where: { id: req.params.id } }).then(() => {
        res.status(204).send({ error: false });
      }).catch(err => errorCatcher(res, err));
    }
  );

export default router;
