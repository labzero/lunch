exports.up = knex => knex.schema.createTable('restaurants', table => {
  table.increments('id').primary();
  table.string('name');
});

exports.down = knex => knex.schema.dropTable('restaurants');
