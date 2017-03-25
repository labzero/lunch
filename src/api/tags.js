import { Router } from 'express';
import { Tag } from '../models';
import errorCatcher from './helpers/errorCatcher';
import checkTeamRole from './helpers/checkTeamRole';
import loggedIn from './helpers/loggedIn';
import { tagDeleted } from '../actions/tags';

export default () => {
  const router = new Router({ mergeParams: true });

  return router
    .get(
      '/',
      loggedIn,
      checkTeamRole(),
      async (req, res) => {
        try {
          const all = await Tag.scope('orderedByRestaurant').findAll({ where: { team_id: req.team.id } });
          res.status(200).send({ error: false, data: all });
        } catch (err) {
          errorCatcher(res, err);
        }
      }
    )
    .delete(
      '/:id',
      loggedIn,
      checkTeamRole(),
      async (req, res) => {
        const id = parseInt(req.params.id, 10);
        try {
          const count = await Tag.destroy({ where: { id, team_id: req.team.id } });
          if (count === 0) {
            res.status(404).json({ error: true, data: { message: 'Tag not found.' } });
          } else {
            req.wss.broadcast(tagDeleted(id, req.user.id));
            res.status(204).send();
          }
        } catch (err) {
          errorCatcher(res, err);
        }
      }
    );
};
