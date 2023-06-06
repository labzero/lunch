import { RequestHandler, Router } from "express";
import hasRole from "../helpers/hasRole";
import teamApi from "./main/teams";
import userApi from "./main/user";
import decisionApi from "./team/decisions";
import tagApi from "./team/tags";
import usersApi from "./team/users";
import restaurantApi from "./team/restaurants";
import { ExtWebSocket } from "../interfaces";

export default (): RequestHandler => {
  const mainRouter = Router();
  const teamRouter = Router();

  mainRouter.use("/teams", teamApi()).use("/user", userApi());

  teamRouter
    .use("/decisions", decisionApi())
    .use("/restaurants", restaurantApi())
    .use("/tags", tagApi())
    .use("/users", usersApi())
    .ws("/", async (ws: ExtWebSocket, req) => {
      if (hasRole(req.user, req.team)) {
        ws.teamId = req.team!.id;
      } else {
        ws.close(1008, "Not authorized for this team.");
      }
    });

  return (req, res, next) => {
    if (req.subdomain) {
      return teamRouter(req, res, next);
    }

    return mainRouter(req, res, next);
  };
};
