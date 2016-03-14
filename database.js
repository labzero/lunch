require('dotenv').config();

const settings = {
  dialect: 'postgresql',
  database: process.env.DB_NAME,
  username: process.env.DB_USER,
  password: process.env.DB_PASS
};

const config = {
  development: {},
  production: {}
};

Object.assign(config.development, settings);
Object.assign(config.production, settings);

Object.assign(config.development, {
  seeds: {
    directory: './db/seeds/development'
  }
});

Object.assign(config.production, {
  seeds: {
    directory: './db/seeds/production'
  }
});

module.exports = config;
