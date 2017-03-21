import { Router } from 'express';
import { Role, User } from '../models';
import hasRole from '../helpers/hasRole';
import errorCatcher from './helpers/errorCatcher';
import checkTeamRole from './helpers/checkTeamRole';
import loggedIn from './helpers/loggedIn';

const router = new Router({ mergeParams: true });

router
  .get(
    '/',
    loggedIn,
    checkTeamRole(),
    async (req, res) => {
      let attributes = ['id', 'name'];
      if (hasRole(req.user, req.team, 'admin')) {
        attributes = attributes.concat(['email']);
      }

      try {
        // TODO attributes not working
        const users = await User.findAllForTeam(req.team.id, attributes);

        res.status(200).json({ error: false, data: users });
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(err);
        errorCatcher(res, err);
      }
    }
  )
  .post(
    '/',
    loggedIn,
    checkTeamRole('admin'),
    async (req, res) => {
      const { email, type } = req.body;

      try {
        let user = await User.findOne({ where: { email } }, { include: [Role] });

        if (user) {
          if (!hasRole(user, req.team)) {
            await Role.create({ team_id: req.team.id, user_id: user.id, type });
            user = await User.findOne({ where: { email } }, { include: [Role] });
          } else {
            throw new Error('User already exists');
          }
        } else {
          user = await User.create({
            email,
            roles: [{
              team_id: req.team.id,
              type
            }]
          }, { include: [Role] });
        }

        const json = user.toJSON();
        res.status(201).send({ error: false, data: json });
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(err);
        const error = { message: 'Could not add user to team. It might already exist.' };
        errorCatcher(res, error);
      }
    }
  );

export default router;
