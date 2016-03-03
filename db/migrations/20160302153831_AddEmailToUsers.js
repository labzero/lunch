exports.up = knex => knex.schema.table('users', table => {
  table.string('email');
});

exports.down = knex => knex.schema.table('users', table => {
  table.dropColumn('email');
});
