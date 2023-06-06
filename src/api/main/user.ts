import { Router } from "express";
import getPasswordError from "../../helpers/getPasswordError";
import getUserPasswordUpdates from "../../helpers/getUserPasswordUpdates";
import { User } from "../../db";
import loggedIn from "../helpers/loggedIn";

export default () => {
  const router = Router();

  return router.patch("/", loggedIn, async (req, res, next) => {
    let fieldCount = 0;

    const allowedFields = [
      {
        name: "name",
        type: "string",
      },
      {
        name: "email",
        type: "string",
      },
      {
        name: "password",
        type: "string",
      },
    ];

    const filteredPayload: {
      [key in (typeof allowedFields)[number]["type"]]: string | boolean;
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
        if (filteredPayload.password) {
          const passwordError = getPasswordError(
            filteredPayload.password as string | undefined
          );
          if (passwordError) {
            return res
              .status(422)
              .json({ error: true, data: { message: passwordError } });
          }
          const passwordUpdates = await getUserPasswordUpdates(
            req.user!,
            filteredPayload.password as string
          );
          Object.assign(filteredPayload, passwordUpdates);
          delete filteredPayload.password;
        }
        if (filteredPayload.name) {
          if (req.user!.get("name") !== filteredPayload.name) {
            filteredPayload.namedChanged = true;
          }
        }
        await req.user!.update(filteredPayload);

        // get user again because now req.user contains password fields
        const user = await User.getSessionUser(req.user!.id);

        return res.status(200).json({ error: false, data: user });
      } catch (err: any) {
        if (err.name === "SequelizeUniqueConstraintError") {
          return res.status(422).json({
            error: true,
            data: { message: "Email is already taken." },
          });
        }
        return next(err);
      }
    }
    return res.status(422).json({
      error: true,
      data: { message: "Can't update any of the provided fields." },
    });
  });
};
