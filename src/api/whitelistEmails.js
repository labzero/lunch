import { Router } from 'express';
import { WhitelistEmail } from '../models';
import { loggedIn, errorCatcher } from './ApiHelper';
import { whitelistEmailPosted, whitelistEmailDeleted } from '../actions/whitelistEmails';

const router = new Router();

router
  .post(
    '/',
    loggedIn,
    async (req, res) => {
      const { email } = req.body;
      WhitelistEmail.create({ email }).then(obj => {
        const json = obj.toJSON();
        req.wss.broadcast(whitelistEmailPosted(json, req.user.id));
        res.status(201).send({ error: false, data: json });
      }).catch(() => {
        const error = { message: 'Could add email to whitelist.' };
        errorCatcher(res, error);
      });
    }
  )
  .delete(
    '/:id',
    loggedIn,
    async (req, res) => {
      const id = parseInt(req.params.id, 10);
      WhitelistEmail.destroy({ where: { id } }).then(() => {
        req.wss.broadcast(whitelistEmailDeleted(id, req.user.id));
        res.status(204).send({ error: false });
      }).catch(err => errorCatcher(res, err));
    }
  );

export default router;
