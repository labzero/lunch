/**
 * React Starter Kit (https://www.reactstarterkit.com/)
 *
 * Copyright © 2014-present Kriasoft, LLC. All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE.txt file in the root directory of this source tree.
 */

/* eslint-disable max-len */

export const port = process.env.PORT || 3000;
export const wsPort = module.hot ? Number(port) + 10 : port;
// https://expressjs.com/en/guide/behind-proxies.html
export const trustProxy = process.env.TRUST_PROXY || "loopback";
// API Gateway
export const api = {
  // API URL to be used in the client-side code
  clientUrl: process.env.API_CLIENT_URL || "",
  // API URL to be used in the server-side code
  serverUrl:
    process.env.API_SERVER_URL ||
    `http://localhost:${process.env.PORT || 3000}`,
};
export const host =
  process.env.WEBSITE_HOSTNAME ||
  (process.env.DOCKERCLOUD_SERVICE_FQDN
    ? `${process.env.DOCKERCLOUD_SERVICE_FQDN}:${port}`
    : undefined) ||
  `local.lunch.pink:${port}`;
export const hostname = host.match(/^([^:]*):?[0-9]{0,}/)![1];
export const bsHost = host;
export const domain = `.${hostname}`;
export const analytics = {
  googleMeasurementId: process.env.GOOGLE_MEASUREMENT_ID,
};
export const auth = {
  jwt: { secret: process.env.JWT_SECRET || "React Starter Kit" },
  session: { secret: process.env.SESSION_SECRET || "Lunch session" },
  sendgrid: { secret: process.env.SENDGRID_API_KEY },
};
export const googleApiKey = process.env.GOOGLE_CLIENT_APIKEY;
