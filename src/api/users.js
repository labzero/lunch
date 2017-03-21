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
      let extraAttributes;
      if (hasRole(req.user, req.team, 'admin')) {
        extraAttributes = ['email'];
      }

      try {
        const users = await User.scope({ method: ['withTeamRole', req.team.id, extraAttributes] }).findAll({
          include: {
            attributes: [],
            model: Role,
            where: { team_id: req.team.id }
          }
        });

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
      const { email, name, type } = req.body;

      try {
        let user = await User.findOne({ where: { email }, include: [Role] });

        const UserWithTeamRole = User.scope({ method: ['withTeamRole', req.team.id, ['email']] });

        if (user) {
          if (!hasRole(user, req.team)) {
            await Role.create({ team_id: req.team.id, user_id: user.id, type });
            user = await UserWithTeamRole.findOne({
              where: { email },
              include: [Role]
            });
          } else {
            throw new Error('User already exists on this team.');
          }
        } else {
          user = await UserWithTeamRole.create({
            email,
            name,
            roles: [{
              team_id: req.team.id,
              type
            }]
          }, { include: [Role] });
        }

        res.status(201).json({ error: false, data: user });
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(err);
        const error = { message: 'Could not add user to team. They might already exist.' };
        errorCatcher(res, error);
      }
    }
  );

export default router;
