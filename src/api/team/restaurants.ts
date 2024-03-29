import { Response, Router } from "express";
import { Restaurant, Vote, Tag } from "../../db";
import { Restaurant as RestaurantInterface } from "../../interfaces";
import checkTeamRole from "../helpers/checkTeamRole";
import loggedIn from "../helpers/loggedIn";
import {
  restaurantPosted,
  restaurantDeleted,
  restaurantRenamed,
} from "../../actions/restaurants";
import voteApi from "./votes";
import restaurantTagApi from "./restaurantTags";

export default () => {
  const router = Router({ mergeParams: true });
  const apikey = process.env.GOOGLE_SERVER_APIKEY;

  const notFound = (res: Response) => {
    res
      .status(404)
      .json({ error: true, data: { message: "Restaurant not found." } });
  };

  return router
    .get("/", loggedIn, checkTeamRole(), async (req, res, next) => {
      try {
        const all = await Restaurant.findAllWithTagIds({
          teamId: req.team!.id,
        });

        res.status(200).json({ error: false, data: all });
      } catch (err) {
        next(err);
      }
    })
    .get(
      "/:id/place_url",
      loggedIn,
      checkTeamRole(),
      async (req, res, next) => {
        try {
          const r = await Restaurant.findByPk(parseInt(req.params.id, 10));

          if (r === null || r.teamId !== req.team!.id) {
            notFound(res);
          } else {
            const response = await fetch(
              `https://maps.googleapis.com/maps/api/place/details/json?key=${apikey}&placeid=${r.placeId}`
            );
            const json = await response.json();
            if (response.ok) {
              if (json.status !== "OK") {
                const newError = {
                  message: `Could not get info for restaurant. Google might have
removed its entry. Try removing it and adding it to Lunch again.`,
                };
                res.status(404).json({ error: true, newError });
              } else if (json.result && json.result.url) {
                res.redirect(json.result.url);
              } else {
                res.redirect(
                  `https://www.google.com/maps/place/${r.name}, ${r.address}`
                );
              }
            } else {
              next(json);
            }
          }
        } catch (err) {
          next(err);
        }
      }
    )
    .post("/", loggedIn, checkTeamRole(), async (req, res, next) => {
      const { name, placeId, lat, lng } = req.body;

      let { address } = req.body;
      address = address.replace(`${name}, `, "");

      try {
        const obj = await Restaurant.create(
          {
            name,
            placeId,
            address,
            lat,
            lng,
            teamId: req.team!.id,
            votes: [],
            tags: [],
          },
          { include: [Vote, Tag] }
        );

        const json = obj.toJSON();
        json.all_decision_count = 0;
        json.all_vote_count = 0;
        req.broadcast(req.team!.id, restaurantPosted(json, req.user!.id));
        res.status(201).send({ error: false, data: json });
      } catch (err) {
        const error = {
          message: "Could not save new restaurant. Has it already been added?",
        };
        next(error);
      }
    })
    .patch("/:id", loggedIn, checkTeamRole(), async (req, res, next) => {
      const id = parseInt(req.params.id, 10);
      const { name } = req.body;

      Restaurant.update(
        { name },
        {
          fields: ["name"],
          where: { id, teamId: req.team!.id },
          returning: true,
        }
      )
        .then(([count, rows]) => {
          if (count === 0) {
            notFound(res);
          } else {
            const json: Partial<RestaurantInterface> = {
              name: rows[0].toJSON().name,
            };
            req.broadcast(
              req.team!.id,
              restaurantRenamed(id, json, req.user!.id)
            );
            res.status(200).send({ error: false, data: json });
          }
        })
        .catch(() => {
          const error = { message: "Could not update restaurant." };
          next(error);
        });
    })
    .delete("/:id", loggedIn, checkTeamRole(), async (req, res, next) => {
      const id = parseInt(req.params.id, 10);
      try {
        const count = await Restaurant.destroy({
          where: { id, teamId: req.team!.id },
        });
        if (count === 0) {
          notFound(res);
        } else {
          req.broadcast(req.team!.id, restaurantDeleted(id, req.user!.id));
          res.status(204).send();
        }
      } catch (err) {
        next(err);
      }
    })
    .use("/:restaurantId/votes", voteApi())
    .use("/:restaurantId/tags", restaurantTagApi());
};
