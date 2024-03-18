import { RequestHandler, Response, Router } from "express";
import cors from "cors";
import { bsHost } from "../../config";
import { Team, Role, User } from "../../db";
import reservedTeamSlugs from "../../constants/reservedTeamSlugs";
import { TEAM_LIMIT, TEAM_SLUG_REGEX } from "../../constants";
import generateUrl from "../../helpers/generateUrl";
import hasRole from "../../helpers/hasRole";
import transporter from "../../mailers/transporter";
import checkTeamRole from "../helpers/checkTeamRole";
import corsOptionsDelegate from "../helpers/corsOptionsDelegate";
import loggedIn from "../helpers/loggedIn";

const getTeam: RequestHandler = async (req, res, next) => {
  const id = parseInt(req.params.id, 10);
  const team = await Team.findOne({ where: { id } });
  if (team) {
    req.team = team; // eslint-disable-line no-param-reassign
    next();
  } else {
    next(new Error("Team doesn't exist"));
  }
};

const error409 = (res: Response, message: string) =>
  res.status(409).json({ error: true, data: { message } });

export default () => {
  const router = Router();

  return router
    .get("/", loggedIn, async (req, res, next) => {
      try {
        const teams = await Team.findAllForUser(req.user!);

        res.status(200).json({ error: false, data: teams });
      } catch (err) {
        next(err);
      }
    })
    .get("/all", loggedIn, async (req, res, next) => {
      if (!req.user?.superuser) {
        res.status(404).send();
      } else {
        try {
          const teams = await Team.findAllWithAdminData();

          res.status(200).json({ error: false, data: teams });
        } catch (err) {
          next(err);
        }
      }
    })
    .post("/", loggedIn, async (req, res, next) => {
      const { address, lat, lng, name, slug } = req.body;
      const message409 = "Could not create new team. It might already exist.";

      if (!req.user!.superuser) {
        const roles = await req.user!.$get("roles");
        if (roles.length >= TEAM_LIMIT) {
          return res.status(403).json({
            error: true,
            data: {
              message: `You currently can't join more than ${TEAM_LIMIT} teams.`,
            },
          });
        }
      }

      if (reservedTeamSlugs.indexOf(slug) > -1) {
        return error409(res, message409);
      }

      if (!slug.match(TEAM_SLUG_REGEX)) {
        return res.status(422).json({
          error: true,
          data: { message: "Team URL doesn't match the criteria." },
        });
      }

      try {
        const obj = await Team.create(
          {
            address,
            lat,
            lng,
            name,
            slug,
            roles: [
              {
                userId: req.user!.id,
                type: "owner",
              },
            ],
          },
          { include: [Role] }
        );

        const json = obj.toJSON();
        return res.status(201).send({ error: false, data: json });
      } catch (err: any) {
        if (err.name === "SequelizeUniqueConstraintError") {
          return error409(res, message409);
        }
        return next(err);
      }
    })
    .options("/:id", cors(corsOptionsDelegate)) // enable pre-flight request for DELETE/PATCH
    .delete(
      "/:id",
      cors(corsOptionsDelegate),
      loggedIn,
      getTeam,
      checkTeamRole("owner"),
      async (req, res, next) => {
        try {
          await req.team!.destroy();
          return res.status(204).send();
        } catch (err) {
          return next(err);
        }
      }
    )
    .patch(
      "/:id",
      cors(corsOptionsDelegate),
      loggedIn,
      getTeam,
      checkTeamRole(),
      async (req, res, next) => {
        const message409 =
          "Could not update team. Its new URL might already exist.";
        let fieldCount = 0;

        const allowedFields = [{ name: "defaultZoom", type: "number" }];

        if (hasRole(req.user, req.team, "owner")) {
          allowedFields.push(
            {
              name: "address",
              type: "string",
            },
            {
              name: "lat",
              type: "number",
            },
            {
              name: "lng",
              type: "number",
            },
            {
              name: "name",
              type: "string",
            },
            {
              name: "slug",
              type: "string",
            },
            {
              name: "sortDuration",
              type: "number",
            }
          );
        }

        const filteredPayload: {
          [key in (typeof allowedFields)[number]["type"]]: string;
        } = {};

        allowedFields.forEach((f) => {
          const value = req.body[f.name];
          // eslint-disable-next-line valid-typeof
          if (value && typeof value === f.type) {
            filteredPayload[f.name] = value;
            fieldCount += 1;
          }
        });

        if (fieldCount) {
          try {
            const oldSlug = req.team!.get("slug");

            if (
              oldSlug !== filteredPayload.slug &&
              reservedTeamSlugs.indexOf(filteredPayload.slug) > -1
            ) {
              return error409(res, message409);
            }

            await req.team!.update(filteredPayload);

            if (filteredPayload.slug && oldSlug !== filteredPayload.slug) {
              req.flash("success", "Team URL has been updated.");
              return req.session.save(async () => {
                const teamRoles = await Role.findAll({
                  where: { teamId: req.team!.get("id") },
                });
                const userIds = teamRoles.map((r) => r.get("userId"));
                const recipients = await User.findAll({
                  where: { id: userIds },
                });

                // returns a promise but we're not going to wait to see if it succeeds.
                transporter
                  .sendMail({
                    recipients,
                    subject: `${req.team!.get("name")}'s team URL has changed`,
                    text: `Hi there!

${req.user!.get("name")} has changed the URL of the ${req.team!.get(
                      "name"
                    )} team on Lunch.

From now on, the team can be accessed at ${generateUrl(
                      req,
                      `${filteredPayload.slug}.${bsHost}`
                    )}. Please update any bookmarks you might have created.

Happy Lunching!`,
                  })
                  .then(() => undefined)
                  .catch(() => undefined);

                return res.status(200).json({ error: false, data: req.team });
              });
            }
            return res.status(200).json({ error: false, data: req.team });
          } catch (err: any) {
            if (err.name === "SequelizeUniqueConstraintError") {
              return error409(res, message409);
            }
            return next(err);
          }
        } else {
          return res.status(422).json({
            error: true,
            data: { message: "Can't update any of the provided fields." },
          });
        }
      }
    );
};
