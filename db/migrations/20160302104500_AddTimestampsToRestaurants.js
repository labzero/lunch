exports.up = knex => knex.schema.table('restaurants', table => {
  table.timestamps();
});

exports.down = knex => knex.schema.table('restaurants', table => {
  table.dropColumns('updated_at', 'created_at');
});
