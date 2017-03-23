import { Router } from 'express';
import { Role, User } from '../models';
import getRole from '../helpers/getRole';
import hasRole from '../helpers/hasRole';
import canChangeRole from '../helpers/canChangeRole';
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
      if (hasRole(req.user, req.team, 'member')) {
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
    checkTeamRole('member'),
    async (req, res) => {
      const { email, name, type } = req.body;

      try {
        if (!hasRole(req.user, req.team, type)) {
          return res.status(403).json({ error: true, data: { message: 'You cannot add a user with a role greater than your own.' } });
        }

        let userToAdd = await User.findOne({ where: { email }, include: [Role] });

        const UserWithTeamRole = User.scope({ method: ['withTeamRole', req.team.id, ['email']] });

        if (userToAdd) {
          if (!hasRole(userToAdd, req.team)) {
            await Role.create({ team_id: req.team.id, user_id: userToAdd.id, type });
            userToAdd = await UserWithTeamRole.findOne({
              where: { email },
              include: [Role]
            });
          } else {
            return res.status(409).json({ error: true, data: { message: 'User already exists on this team.' } });
          }
        } else {
          userToAdd = await User.create({
            email,
            name,
            roles: [{
              team_id: req.team.id,
              type
            }]
          }, { include: [Role] });

          // ugly hack: sequelize can't apply scopes on create, so just get user again
          userToAdd = await UserWithTeamRole.findOne({ where: { id: userToAdd.id } });
        }

        return res.status(201).json({ error: false, data: userToAdd });
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(err);
        const error = { message: 'Could not add user to team. They might already exist.' };
        return errorCatcher(res, error);
      }
    }
  )
  .delete(
    '/:id',
    loggedIn,
    checkTeamRole('member'),
    async (req, res) => {
      const id = parseInt(req.params.id, 10);
      const currentUserRole = getRole(req.user, req.team);

      try {
        let roleToDelete;
        if (req.user.id === id) {
          roleToDelete = currentUserRole;
        } else {
          roleToDelete = await Role.findOne({ where: { team_id: req.team.id, user_id: id } });
        }

        if (roleToDelete) {
          let allowed = false;
          if (req.user.superuser) {
            allowed = true;
          } else if (currentUserRole.type === 'owner') {
            if (req.user.id === id) {
              const allTeamRoles = await Role.findAll({ where: { team_id: req.team.id } });
              if (allTeamRoles.some(role => role.type === 'owner' && role.user_id !== id)) {
                allowed = true;
              } else {
                return res.status(403).json({
                  error: true,
                  data: {
                    message: `You cannot remove yourself if you are the only owner.
Transfer ownership to another user first.`
                  }
                });
              }
            } else {
              allowed = true;
            }
          } else {
            allowed = canChangeRole(currentUserRole.type, roleToDelete.type);
          }

          if (allowed) {
            await roleToDelete.destroy();
            return res.status(204).send();
          }
          return res.status(403).json({ error: true, data: { message: 'You do not have permission to remove this user.' } });
        }
        return res.status(404).json({ error: true, data: { message: 'User not found on team.' } });
      } catch (err) {
        return errorCatcher(res, err);
      }
    }
  );

export default router;
