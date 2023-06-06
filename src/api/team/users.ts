import { Request, Router } from "express";
import cors from "cors";
import { Invitation, Role, Team, User } from "../../db";
import { bsHost } from "../../config";
import { TEAM_LIMIT } from "../../constants";
import generateToken from "../../helpers/generateToken";
import generateUrl from "../../helpers/generateUrl";
import getRole from "../../helpers/getRole";
import hasRole from "../../helpers/hasRole";
import canChangeRole from "../../helpers/canChangeRole";
import checkTeamRole from "../helpers/checkTeamRole";
import corsOptionsDelegate from "../helpers/corsOptionsDelegate";
import loggedIn from "../helpers/loggedIn";
import { RoleType } from "../../interfaces";
import transporter from "../../mailers/transporter";

export default () => {
  const router = Router({ mergeParams: true });

  const getRoleToChange = async (
    currentUser: User,
    targetId: number,
    team: Team
  ) => {
    if (currentUser.id === targetId) {
      return getRole(currentUser, team);
    }
    return Role.findOne({ where: { teamId: team.id, userId: targetId } });
  };

  const hasOtherOwners = async (team: Team, id: number) => {
    const allTeamRoles = await Role.findAll({ where: { teamId: team.id } });
    return allTeamRoles.some(
      (role) => role.type === "owner" && role.userId !== id
    );
  };

  const getExtraAttributes = (req: Request) => {
    if (hasRole(req.user, req.team, "owner")) {
      return ["email"];
    }
    return undefined;
  };

  const canChangeUser = async (
    user: User,
    roleToChange: Role,
    target: RoleType | undefined,
    team: Team,
    noOtherOwners: () => void
  ) => {
    let currentUserRole;
    if (user.id === roleToChange.userId) {
      currentUserRole = roleToChange;
    } else {
      currentUserRole = getRole(user, team);
    }
    let allowed = false;
    if (user.superuser) {
      allowed = true;
    } else if (currentUserRole?.type === "owner") {
      if (user.id === roleToChange.userId) {
        const otherOwners = await hasOtherOwners(team, roleToChange.userId);
        if (otherOwners) {
          allowed = true;
        } else {
          return noOtherOwners();
        }
      } else {
        allowed = true;
      }
    } else if (target === undefined && user.id === roleToChange.userId) {
      allowed = true;
    } else if (currentUserRole) {
      allowed = canChangeRole(currentUserRole.type, roleToChange.type, target);
    }
    return allowed;
  };

  return router
    .get("/", loggedIn, checkTeamRole(), async (req, res, next) => {
      const extraAttributes = getExtraAttributes(req);

      try {
        const users = await User.scope({
          method: ["withTeamRole", req.team!.id, extraAttributes],
        }).findAll({
          include: {
            attributes: [],
            model: Role,
            where: { teamId: req.team!.id },
          },
        });

        res.status(200).json({ error: false, data: users });
      } catch (err) {
        next(err);
      }
    })
    .post("/", loggedIn, checkTeamRole("member"), async (req, res, next) => {
      const { email, name, type } = req.body;

      const extraAttributes = getExtraAttributes(req);

      try {
        if (!hasRole(req.user, req.team, type)) {
          return res.status(403).json({
            error: true,
            data: {
              message:
                "You cannot add a user with a role greater than your own.",
            },
          });
        }

        // WARNING: this retrieves all attributes (incl. password).
        // But it is overridden with the scoped findOne call below
        let userToAdd = await User.findOne({
          where: { email },
          include: [Role],
        });

        const UserWithTeamRole = User.scope({
          method: ["withTeamRole", req.team!.id, extraAttributes],
        });

        if (userToAdd) {
          if (
            !req.user!.get("superuser") &&
            userToAdd.roles.length >= TEAM_LIMIT
          ) {
            return res.status(403).json({
              error: true,
              data: {
                message:
                  "This user currently cannot be added to any more teams.",
              },
            });
          }
          if (hasRole(userToAdd, req.team, undefined, true)) {
            return res.status(409).json({
              error: true,
              data: { message: "User already exists on this team." },
            });
          }
          await Role.create({
            teamId: req.team!.id,
            userId: userToAdd.id,
            type,
          });

          // returns a promise but we're not going to wait to see if it succeeds.
          transporter
            .sendMail({
              name,
              email,
              subject: "You were added to a team!",
              text: `Hi there!

${req.user!.get("name")} invited you to the ${req.team!.get(
                "name"
              )} team on Lunch!

To get started, simply visit ${generateUrl(
                req,
                `${req.team!.get("slug")}.${bsHost}`
              )} and vote away.

Happy Lunching!`,
            })
            .then(() => undefined)
            .catch(() => undefined);

          userToAdd = await UserWithTeamRole.findOne({
            where: { email },
            include: [Role],
          });

          return res.status(201).json({ error: false, data: userToAdd });
        }

        const resetPasswordToken = await generateToken();

        let newUser = await User.create(
          {
            email,
            name,
            resetPasswordToken,
            resetPasswordSentAt: new Date(),
            roles: [
              {
                teamId: req.team!.id,
                type,
              },
            ],
          },
          { include: [Role] }
        );

        // returns a promise but we're not going to wait to see if it succeeds.
        Invitation.destroy({ where: { email } })
          .then(() => undefined)
          .catch(() => undefined);

        // returns a promise but we're not going to wait to see if it succeeds.
        transporter
          .sendMail({
            name,
            email,
            subject: "Welcome to Lunch!",
            text: `Hi there!

${req.user!.get("name")} invited you to the ${req.team!.get(
              "name"
            )} team on Lunch!

To get started, simply visit ${generateUrl(
              req,
              bsHost
            )} and log in with Google using the email address with which you've received this message.

If you'd like to log in using a password instead, just follow this URL to generate one:
${generateUrl(req, bsHost, `/password/edit?token=${resetPasswordToken}`)}

Happy Lunching!`,
          })
          .then(() => undefined)
          .catch(() => undefined);

        // Sequelize can't apply scopes on create, so just get user again.
        // Also will exclude hidden fields like password, token, etc.
        newUser = (await UserWithTeamRole.findOne({
          where: { id: newUser.id },
        })) as User;

        return res.status(201).json({ error: false, data: newUser });
      } catch (err) {
        return next(err);
      }
    })
    .patch(
      "/:id",
      loggedIn,
      checkTeamRole("member"),
      async (req, res, next) => {
        const id = parseInt(req.params.id, 10);

        const extraAttributes = getExtraAttributes(req);

        try {
          const roleToChange = await getRoleToChange(req.user!, id, req.team!);

          if (roleToChange) {
            const allowed = await canChangeUser(
              req.user!,
              roleToChange,
              req.body.type,
              req.team!,
              () =>
                res.status(403).json({
                  error: true,
                  data: {
                    message: `You cannot demote yourself if you are the only owner.
  Grant ownership to another user first.`,
                  },
                })
            );

            // in case of error response within canChangeUser
            if (typeof allowed !== "boolean") {
              return allowed;
            }

            if (allowed) {
              await roleToChange.update({ type: req.body.type });
              const user = await User.scope({
                method: ["withTeamRole", req.team!.id, extraAttributes],
              }).findOne({ where: { id } });
              return res.status(200).json({ error: false, data: user });
            }
            return res.status(403).json({
              error: true,
              data: {
                message: "You do not have permission to change this user.",
              },
            });
          }
          return res.status(404).json({
            error: true,
            data: { message: "User not found on team." },
          });
        } catch (err) {
          return next(err);
        }
      }
    )
    .options("/:id", cors(corsOptionsDelegate)) // enable pre-flight request for DELETE request
    .delete(
      "/:id",
      cors(corsOptionsDelegate),
      loggedIn,
      checkTeamRole("member"),
      async (req, res, next) => {
        const id = parseInt(req.params.id, 10);

        try {
          const roleToDelete = await getRoleToChange(req.user!, id, req.team!);

          if (roleToDelete) {
            const allowed = await canChangeUser(
              req.user!,
              roleToDelete,
              undefined,
              req.team!,
              () =>
                res.status(403).json({
                  error: true,
                  data: {
                    message: `You cannot remove yourself if you are the only owner.
  Transfer ownership to another user first.`,
                  },
                })
            );

            // in case of error response within canChangeUser
            if (typeof allowed !== "boolean") {
              return allowed;
            }

            if (allowed) {
              await roleToDelete.destroy();
              return res.status(204).send();
            }
            return res.status(403).json({
              error: true,
              data: {
                message: "You do not have permission to remove this user.",
              },
            });
          }
          return res.status(404).json({
            error: true,
            data: { message: "User not found on team." },
          });
        } catch (err) {
          return next(err);
        }
      }
    );
};
