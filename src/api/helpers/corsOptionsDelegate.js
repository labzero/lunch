import { hostname } from '../../config';

export default (req, callback) => {
  callback(null, {
    credentials: true,
    optionsSuccessStatus: 200, // some legacy browsers (IE11, various SmartTVs) choke on 204
    origin: !!req.hostname.match(`${hostname}$`)
  });
};
