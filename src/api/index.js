import { Router } from 'express';
import hasRole from '../helpers/hasRole';
import teamApi from './main/teams';
import userApi from './main/user';
import decisionApi from './team/decisions';
import tagApi from './team/tags';
import usersApi from './team/users';
import restaurantApi from './team/restaurants';

export default () => {
  const mainRouter = new Router();
  const teamRouter = new Router();

  mainRouter
    .use('/teams', teamApi())
    .use('/user', userApi());

  teamRouter
    .use('/decisions', decisionApi())
    .use('/restaurants', restaurantApi())
    .use('/tags', tagApi())
    .use('/users', usersApi())
    .ws('/', async (ws, req) => {
      if (hasRole(req.user, req.team)) {
        ws.teamId = req.team.id; // eslint-disable-line no-param-reassign
      } else {
        ws.close(1008, 'Not authorized for this team.');
      }
    });

  return (req, res, next) => {
    if (req.subdomain) {
      return teamRouter(req, res, next);
    }

    return mainRouter(req, res, next);
  };
};
