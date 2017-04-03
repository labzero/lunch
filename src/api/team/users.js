import { Router } from 'express';
import cors from 'cors';
import crypto from 'crypto';
import { Role, User } from '../../models';
import { TEAM_LIMIT } from '../../constants';
import getRole from '../../helpers/getRole';
import hasRole from '../../helpers/hasRole';
import canChangeRole from '../../helpers/canChangeRole';
import errorCatcher from '../helpers/errorCatcher';
import checkTeamRole from '../helpers/checkTeamRole';
import corsOptionsDelegate from '../helpers/corsOptionsDelegate';
import loggedIn from '../helpers/loggedIn';

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

  const getExtraAttributes = (req) => {
    if (hasRole(req.user, req.team, 'owner')) {
      return ['email'];
    }
    return undefined;
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
        const extraAttributes = getExtraAttributes(req);

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

        const extraAttributes = getExtraAttributes(req);

        try {
          if (!hasRole(req.user, req.team, type)) {
            return res.status(403).json({ error: true, data: { message: 'You cannot add a user with a role greater than your own.' } });
          }

          // WARNING: this retrieves all attributes (incl. password).
          // But it is overridden with the scoped findOne call below
          let userToAdd = await User.findOne({ where: { email }, include: [Role] });

          const UserWithTeamRole = User.scope({ method: ['withTeamRole', req.team.id, extraAttributes] });

          if (userToAdd) {
            if (userToAdd.roles.length >= TEAM_LIMIT) {
              return res.status(403).json({ error: true, data: { message: 'This user currently cannot be added to any more teams.' } });
            }
            if (hasRole(userToAdd, req.team)) {
              return res.status(409).json({ error: true, data: { message: 'User already exists on this team.' } });
            }
            await Role.create({ team_id: req.team.id, user_id: userToAdd.id, type });
            userToAdd = await UserWithTeamRole.findOne({
              where: { email },
              include: [Role]
            });

            return res.status(201).json({ error: false, data: userToAdd });
          }

          return crypto.randomBytes(20, async (err, buf) => {
            const resetPasswordToken = buf.toString('hex');

            let newUser = await User.create({
              email,
              name,
              reset_password_token: resetPasswordToken,
              reset_password_sent_at: new Date(),
              roles: [{
                team_id: req.team.id,
                type
              }]
            }, { include: [Role] });

            // Sequelize can't apply scopes on create, so just get user again.
            // Also will exclude hidden fields like password, token, etc.
            newUser = await UserWithTeamRole.findOne({ where: { id: newUser.id } });

            return res.status(201).json({ error: false, data: newUser });
          });
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

        const extraAttributes = getExtraAttributes(req);

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
              const user = await User.scope({ method: ['withTeamRole', req.team.id, extraAttributes] }).findOne({ where: { id } });
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
    .options('/:id', cors(corsOptionsDelegate)) // enable pre-flight request for DELETE request
    .delete(
      '/:id',
      cors(corsOptionsDelegate),
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
