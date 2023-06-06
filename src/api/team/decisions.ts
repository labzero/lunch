import { Router } from "express";
import dayjs from "dayjs";
import {
  Attributes,
  CreationAttributes,
  FindOptions,
  ModelStatic,
  Op,
} from "sequelize";
import { Decision } from "../../db";
import checkTeamRole from "../helpers/checkTeamRole";
import loggedIn from "../helpers/loggedIn";
import { decisionPosted, decisionsDeleted } from "../../actions/decisions";

export default () => {
  const router = Router({ mergeParams: true });

  return router
    .get("/", loggedIn, checkTeamRole(), async (req, res, next) => {
      try {
        const opts: FindOptions<Attributes<Decision>> = {
          where: { teamId: req.team!.id },
        };
        const days = parseInt(req.query.days as string, 10);
        if (!Number.isNaN(days)) {
          opts.where = {
            ...opts.where,
            createdAt: {
              [Op.gt]: dayjs().subtract(days, "days").toDate(),
            },
          };
        }

        const decisions = await Decision.findAll(opts);

        res.status(200).json({ error: false, data: decisions });
      } catch (err) {
        next(err);
      }
    })
    .post("/", loggedIn, checkTeamRole(), async (req, res, next) => {
      const restaurantId = parseInt(req.body.restaurantId, 10);
      try {
        const destroyOpts: FindOptions<Attributes<Decision>> = {
          where: { teamId: req.team!.id },
        };
        const daysAgo = parseInt(req.body.daysAgo, 10);
        let MaybeScopedDecision: typeof Decision | ModelStatic<Decision> =
          Decision;
        if (daysAgo > 0) {
          destroyOpts.where = {
            ...destroyOpts.where,
            createdAt: {
              [Op.gt]: dayjs()
                .subtract(daysAgo, "days")
                .subtract(12, "hours")
                .toDate(),
              [Op.lt]: dayjs()
                .subtract(daysAgo, "days")
                .add(12, "hours")
                .toDate(),
            },
          };
        } else {
          MaybeScopedDecision = MaybeScopedDecision.scope("fromToday");
        }

        const deselected = await MaybeScopedDecision.findAll(destroyOpts);
        await MaybeScopedDecision.destroy(destroyOpts);

        try {
          const createOpts: CreationAttributes<Decision> = {
            restaurantId,
            teamId: req.team!.id,
          };
          if (daysAgo > 0) {
            createOpts.createdAt = dayjs().subtract(daysAgo, "days").toDate();
          }
          const obj = await Decision.create(createOpts);

          const json = obj.toJSON();
          req.broadcast(
            req.team!.id,
            decisionPosted(json, deselected, req.user!.id)
          );
          res.status(201).send({ error: false, data: obj });
        } catch (err) {
          const error = { message: "Could not save decision." };
          next(error);
        }
      } catch (err) {
        next(err);
      }
    })
    .delete("/fromToday", loggedIn, checkTeamRole(), async (req, res, next) => {
      try {
        const decisions = await Decision.scope("fromToday").findAll({
          where: { teamId: req.team!.id },
        });
        await Decision.scope("fromToday").destroy({
          where: { teamId: req.team!.id },
        });

        req.broadcast(req.team!.id, decisionsDeleted(decisions, req.user!.id));
        res.status(204).send();
      } catch (err) {
        next(err);
      }
    });
};
