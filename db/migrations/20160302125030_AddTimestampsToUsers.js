exports.up = knex => knex.schema.table('users', table => {
  table.timestamps();
});

exports.down = knex => knex.schema.table('users', table => {
  table.dropColumns('updated_at', 'created_at');
});
