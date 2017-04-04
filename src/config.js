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
export const host = process.env.WEBSITE_HOSTNAME ||
                    (process.env.DOCKERCLOUD_SERVICE_FQDN ? `${process.env.DOCKERCLOUD_SERVICE_FQDN}:${port}` : undefined) ||
                    `local.lunch.pink:${port}`;
export const hostname = host.match(/^([^:]*):?[0-9]{0,}/)[1];

export const wsHost = process.env.WS_HOST;

export const analytics = {

  // https://analytics.google.com/
  google: { trackingId: process.env.GOOGLE_TRACKING_ID || 'UA-XXXXX-X' },

};

export const auth = {
  jwt: { secret: process.env.JWT_SECRET || 'React Starter Kit' },
  smtp: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
    service: process.env.SMTP_SERVICE
  }
};
