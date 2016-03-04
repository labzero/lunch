exports.up = knex => knex.schema.table('restaurants', table => {
  table.string('address');
});

exports.down = knex => knex.schema.table('restaurants', table => {
  table.dropColumn('address');
});
