import { Router } from 'express';
import { Role, User } from '../models';
import getRole from '../helpers/getRole';
import hasRole from '../helpers/hasRole';
import canChangeRole from '../helpers/canChangeRole';
import errorCatcher from './helpers/errorCatcher';
import checkTeamRole from './helpers/checkTeamRole';
import loggedIn from './helpers/loggedIn';

export default () => {
  const router = new Router({ mergeParams: true });

  const getRoleToChange = async (currentUser, targetId, team) => {
    if (currentUser.id === targetId) {
      return getRole(currentUser, team);
    }
    return Role.findOne({ where: { team_id: team.id, user_id: targetId } });
  };

  const hasOtherOwners = async (team, id) => {
    const allTeamRoles = await Role.findAll({ where: { team_id: team.id } });
    return allTeamRoles.some(role => role.type === 'owner' && role.user_id !== id);
  };

  const canChangeUser = async (user, roleToChange, target, team, noOtherOwners) => {
    let currentUserRole;
    if (user.id === roleToChange.user_id) {
      currentUserRole = roleToChange;
    } else {
      currentUserRole = getRole(user, team);
    }
    let allowed = false;
    if (user.superuser) {
      allowed = true;
    } else if (currentUserRole.type === 'owner') {
      if (user.id === roleToChange.user_id) {
        const otherOwners = await hasOtherOwners(team, roleToChange.user_id);
        if (otherOwners) {
          allowed = true;
        } else {
          return noOtherOwners();
        }
      } else {
        allowed = true;
      }
    } else {
      allowed = canChangeRole(currentUserRole.type, roleToChange.type, target);
    }
    return allowed;
  };

  return router
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
          return errorCatcher(res, err);
        }
      }
    )
    .patch(
      '/:id',
      loggedIn,
      checkTeamRole('member'),
      async (req, res) => {
        const id = parseInt(req.params.id, 10);

        try {
          const roleToChange = await getRoleToChange(req.user, id, req.team);

          if (roleToChange) {
            const allowed = await canChangeUser(
              req.user, roleToChange, req.body.type, req.team, () => res.status(403).json({
                error: true,
                data: {
                  message: `You cannot demote yourself if you are the only owner.
  Grant ownership to another user first.`
                }
              })
            );

            // in case of error response within canChangeUser
            if (typeof allowed !== 'boolean') {
              return allowed;
            }

            if (allowed) {
              await roleToChange.update({ type: req.body.type });
              const user = await User.scope({ method: ['withTeamRole', req.team.id, ['email']] }).findOne({ where: { id } });
              return res.status(200).json({ error: false, data: user });
            }
            return res.status(403).json({ error: true, data: { message: 'You do not have permission to change this user.' } });
          }
          return res.status(404).json({ error: true, data: { message: 'User not found on team.' } });
        } catch (err) {
          return errorCatcher(res, err);
        }
      }
    )
    .delete(
      '/:id',
      loggedIn,
      checkTeamRole('member'),
      async (req, res) => {
        const id = parseInt(req.params.id, 10);

        try {
          const roleToDelete = await getRoleToChange(req.user, id, req.team);

          if (roleToDelete) {
            const allowed = await canChangeUser(
              req.user, roleToDelete, undefined, req.team, () => res.status(403).json({
                error: true,
                data: {
                  message: `You cannot remove yourself if you are the only owner.
  Transfer ownership to another user first.`
                }
              })
            );

            // in case of error response within canChangeUser
            if (typeof allowed !== 'boolean') {
              return allowed;
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
};
