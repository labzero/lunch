exports.up = knex => knex.schema.createTable('votes', table => {
  table.increments('id').primary();
  table.integer('restaurant_id').references('id').inTable('restaurants');
  table.integer('user_id').references('id').inTable('users');
  table.timestamps();
});

exports.down = knex => knex.schema.dropTable('votes');
