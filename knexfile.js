require('dotenv').config();

const settings = {
  client: 'postgresql',
  connection: {
    database: process.env.DB_NAME,
    user:     process.env.DB_USER,
    password: process.env.DB_PASS
  },
  pool: {
    min: 2,
    max: 10
  },
  migrations: {
    directory: './db/migrations',
    tableName: 'knex_migrations'
  }
};

const config = {
  development: {},
  production: {}
};

Object.assign(config.development, settings);
Object.assign(config.production, settings);

Object.assign(config.development, {
  debug: true,
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
