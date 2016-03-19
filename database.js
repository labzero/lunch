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
  production: {}
};

Object.assign(config.development, settings);
Object.assign(config.production, settings);

module.exports = config;
