import { Router } from 'express';
import Tag from '../models/Tag';
import { loggedIn, errorCatcher } from './ApiHelper';

const router = new Router();

router
  .get('/', async (req, res) => {
    Tag.findAll().then(all => {
      res.status(200).send({ error: false, data: all });
    }).catch(err => errorCatcher(res, err));
  })
  .post(
    '/',
    loggedIn,
    async (req, res) => {
      const { name } = req.body;
      Tag.create({
        name
      }).then(obj => {
        const json = obj.toJSON();
        // req.wss.broadcast(tagPosted(json));
        res.status(201).send({ error: false, data: json });
      }).catch(() => {
        const error = { message: 'Could not save new tag. Has it already been added?' };
        errorCatcher(res, error);
      });
    }
  )
  .delete(
    '/:id',
    loggedIn,
    async (req, res) => {
      const id = parseInt(req.params.id, 10);
      Tag.destroy({ where: { id } }).then(() => {
        // req.wss.broadcast(tagDeleted(id));
        res.status(204).send({ error: false });
      }).catch(err => errorCatcher(res, err));
    }
  );

export default router;
