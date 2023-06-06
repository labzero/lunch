import { Router } from "express";
import { Tag } from "../../db";
import checkTeamRole from "../helpers/checkTeamRole";
import loggedIn from "../helpers/loggedIn";
import { tagDeleted } from "../../actions/tags";

export default () => {
  const router = Router({ mergeParams: true });

  return router
    .get("/", loggedIn, checkTeamRole(), async (req, res, next) => {
      try {
        const all = await Tag.scope("orderedByRestaurant").findAll({
          where: { teamId: req.team!.id },
        });
        res.status(200).send({ error: false, data: all });
      } catch (err) {
        next(err);
      }
    })
    .delete("/:id", loggedIn, checkTeamRole(), async (req, res, next) => {
      const id = parseInt(req.params.id, 10);
      try {
        const count = await Tag.destroy({
          where: { id, teamId: req.team!.id },
        });
        if (count === 0) {
          res
            .status(404)
            .json({ error: true, data: { message: "Tag not found." } });
        } else {
          req.broadcast(req.team!.id, tagDeleted(id, req.user!.id));
          res.status(204).send();
        }
      } catch (err) {
        next(err);
      }
    });
};
