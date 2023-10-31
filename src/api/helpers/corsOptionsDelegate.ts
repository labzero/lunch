import { CorsOptionsDelegate } from "cors";
import { Request } from "express";
import { hostname } from "../../config";

const corsOptionsDelegate: CorsOptionsDelegate<Request> = (req, callback) => {
  callback(null, {
    credentials: true,
    optionsSuccessStatus: 200, // some legacy browsers (IE11, various SmartTVs) choke on 204
    origin:
      process.env.NODE_ENV === "production"
        ? !!req.hostname.match(`${hostname}$`)
        : true,
  });
};

export default corsOptionsDelegate;
