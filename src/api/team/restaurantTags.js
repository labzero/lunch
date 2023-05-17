import { Router } from "express";
import { Tag, RestaurantTag } from "../../models";
import checkTeamRole from "../helpers/checkTeamRole";
import loggedIn from "../helpers/loggedIn";
import {
  postedNewTagToRestaurant,
  postedTagToRestaurant,
  deletedTagFromRestaurant,
} from "../../actions/restaurants";

export default () => {
  const router = new Router({ mergeParams: true });

  return router
    .post("/", loggedIn, checkTeamRole(), async (req, res, next) => {
      const restaurantId = parseInt(req.params.restaurantId, 10);
      const alreadyAddedError = () => {
        const error = {
          message: "Could not add tag to restaurant. Is it already added?",
        };
        res.status(409).json({ error: true, data: error });
      };
      if (req.body.name !== undefined) {
        Tag.findOrCreate({
          where: {
            name: req.body.name.toLowerCase().trim(),
            teamId: req.team.id,
          },
        })
          .then(async ([tag]) => {
            try {
              await RestaurantTag.create({
                restaurantId,
                tagId: tag.id,
              });
              const json = tag.toJSON();
              json.restaurant_count = 1;
              req.broadcast(
                req.team.id,
                postedNewTagToRestaurant(restaurantId, json, req.user.id)
              );
              res.status(201).send({ error: false, data: json });
            } catch (err) {
              alreadyAddedError(err);
            }
          })
          .catch((err) => {
            next(err);
          });
      } else if (req.body.id !== undefined) {
        const id = parseInt(req.body.id, 10);
        try {
          const obj = await RestaurantTag.create({
            restaurantId,
            tagId: id,
          });

          const json = obj.toJSON();
          req.broadcast(
            req.team.id,
            postedTagToRestaurant(restaurantId, id, req.user.id)
          );
          res.status(201).send({ error: false, data: json });
        } catch (err) {
          alreadyAddedError(err);
        }
      } else {
        next();
      }
    })
    .delete("/:id", loggedIn, checkTeamRole(), async (req, res, next) => {
      const id = parseInt(req.params.id, 10);
      const restaurantId = parseInt(req.params.restaurantId, 10);
      try {
        await RestaurantTag.destroy({ where: { restaurantId, tagId: id } });
        req.broadcast(
          req.team.id,
          deletedTagFromRestaurant(restaurantId, id, req.user.id)
        );
        res.status(204).send();
      } catch (err) {
        next(err);
      }
    });
};
