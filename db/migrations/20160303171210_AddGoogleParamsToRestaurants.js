exports.up = knex => knex.schema.table('restaurants', table => {
  table.string('place_id').unique();
  table.decimal('lat');
  table.decimal('lng');
});

exports.down = knex => knex.schema.table('restaurants', table => {
  table.dropColumns('place_id', 'lat', 'lng');
});
