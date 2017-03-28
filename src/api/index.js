import { Router } from 'express';
import hasRole from '../helpers/hasRole';
import decisionApi from './decisions';
import tagApi from './tags';
import teamApi from './teams';
import userApi from './users';
import restaurantApi from './restaurants';

export default () => {
  const router = new Router();

  return router
    .use('/decisions', decisionApi())
    .use('/restaurants', restaurantApi())
    .use('/tags', tagApi())
    .use('/teams', teamApi())
    .use('/users', userApi())
    .ws('/', async (ws, req) => {
      if (!hasRole(req.user, req.team)) {
        ws.close(1008, 'Not authorized for this team.');
      } else {
        ws.teamId = req.team.id; // eslint-disable-line no-param-reassign
      }
    });
};
