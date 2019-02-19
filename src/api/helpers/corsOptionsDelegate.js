import { hostname } from '../../config';

const isDev = typeof __DEV__ !== 'undefined' && __DEV__;

export default (req, callback) => {
  callback(null, {
    credentials: true,
    optionsSuccessStatus: 200, // some legacy browsers (IE11, various SmartTVs) choke on 204
    origin: isDev ? true : !!req.hostname.match(`${hostname}$`),
  });
};
