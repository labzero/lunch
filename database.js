const path = require('path');

if (process.env.NODE_ENV === 'test') {
  // eslint-disable-next-line global-require
  require('dotenv').config({
    path: path.resolve(process.cwd(), '.env.test'),
  });
}
require('dotenv').config();

const settings = {
  dialect: 'postgresql',
  database: process.env.DB_NAME,
  username: process.env.DB_USER,
  password: process.env.DB_PASS,
  host: process.env.DB_HOST || undefined,
};

const config = {
  development: {},
  test: {
    logging: false,
  },
  production: {}
};

Object.assign(config.development, settings);
Object.assign(config.test, settings);
Object.assign(config.production, settings);

module.exports = config;
