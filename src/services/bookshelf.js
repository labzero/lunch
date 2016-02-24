const config = require('../../knexfile.js');

const knex = require('knex')(config[process.env.NODE_ENV]);

const bookshelf = require('bookshelf')(knex);

export { bookshelf, knex };
