import { Router } from 'express';
import request from 'request';
import { Restaurant, Vote, Tag } from '../models';
import errorCatcher from './helpers/errorCatcher';
import checkTeamRole from './helpers/checkTeamRole';
import loggedIn from './helpers/loggedIn';
import { restaurantPosted, restaurantDeleted, restaurantRenamed } from '../actions/restaurants';
import voteApi from './votes';
import restaurantTagApi from './restaurantTags';

const router = new Router({ mergeParams: true });
const apikey = process.env.GOOGLE_SERVER_APIKEY;

const notFound = (res) => {
  res.status(404).json({ error: true, data: { message: 'Restaurant not found.' } });
};

router
  .get(
    '/',
    loggedIn,
    checkTeamRole(),
    async (req, res) => {
      try {
        const all = await Restaurant.findAllWithTagIds({ team_id: req.team.id });

        res.status(200).json({ error: false, data: all });
      } catch (err) {
        errorCatcher(res, err);
      }
    }
  ).get(
    '/:id/place_url',
    loggedIn,
    checkTeamRole(),
    async (req, res, next) => {
      try {
        const r = await Restaurant.findById(parseInt(req.params.id, 10));

        if (r === null || r.team_id !== req.team.id) {
          notFound(res);
        } else {
          request(`https://maps.googleapis.com/maps/api/place/details/json?key=${apikey}&placeid=${r.place_id}`,
            (error, response, body) => {
              if (!error && response.statusCode === 200) {
                const json = JSON.parse(body);
                if (json.status !== 'OK') {
                  const newError = { message: `Could not get info for restaurant. Google might have
  removed its entry. Try removing it and adding it to Lunch again.` };
                  errorCatcher(res, newError);
                } else if (json.result && json.result.url) {
                  res.redirect(json.result.url);
                } else {
                  res.redirect(`https://www.google.com/maps/place/${r.name}, ${r.address}`);
                }
              } else {
                // eslint-disable-next-line no-console
                console.error(error);
                next(error);
              }
            }
          );
        }
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(err);
        next(err);
      }
    }
  )
  .post(
    '/',
    loggedIn,
    checkTeamRole(),
    async (req, res) => {
      const { name, place_id, lat, lng } = req.body;

      let { address } = req.body;
      address = address.replace(`${name}, `, '');

      try {
        const obj = await Restaurant.create({
          name,
          place_id,
          address,
          lat,
          lng,
          team_id: req.team.id,
          votes: [],
          tags: []
        }, { include: [Vote, Tag] });

        const json = obj.toJSON();
        req.wss.broadcast(restaurantPosted(json, req.user.id));
        res.status(201).send({ error: false, data: json });
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(err);
        const error = { message: 'Could not save new restaurant. Has it already been added?' };
        errorCatcher(res, error);
      }
    }
  )
  .patch(
    '/:id',
    loggedIn,
    checkTeamRole(),
    async (req, res) => {
      const id = parseInt(req.params.id, 10);
      const { name } = req.body;

      Restaurant.update(
        { name },
        { fields: ['name'], where: { id, team_id: req.team.id }, returning: true }
      ).spread((count, rows) => {
        if (count === 0) {
          notFound(res);
        } else {
          const json = { name: rows[0].toJSON().name };
          req.wss.broadcast(restaurantRenamed(id, json, req.user.id));
          res.status(200).send({ error: false, data: json });
        }
      }).catch((e) => {
        // eslint-disable-next-line no-console
        console.error(e);
        const error = { message: 'Could not update restaurant.' };
        errorCatcher(res, error);
      });
    }
  )
  .delete(
    '/:id',
    loggedIn,
    checkTeamRole(),
    async (req, res) => {
      const id = parseInt(req.params.id, 10);
      try {
        const count = await Restaurant.destroy({ where: { id, team_id: req.team.id } });
        if (count === 0) {
          notFound(res);
        } else {
          req.wss.broadcast(restaurantDeleted(id, req.user.id));
          res.status(204).send({ error: false });
        }
      } catch (err) {
        // eslint-disable-next-line no-console
        console.error(err);
        errorCatcher(res, err);
      }
    }
  )
  .use('/:restaurant_id/votes', voteApi)
  .use('/:restaurant_id/tags', restaurantTagApi);

export default router;
