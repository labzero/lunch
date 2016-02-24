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
    tableName: 'knex_migrations'
  }
};

const config = {};

config.development = config.production = settings;

module.exports = config;
