exports.seed = (knex, Promise) => Promise.join(
  // Deletes ALL existing entries
  knex('restaurants').del(),

  // Inserts seed entries
  knex('restaurants').insert({ id: 1, name: 'Food Barn' }),
  knex('restaurants').insert({ id: 2, name: 'Exquisite Smorgasbord' }),
  knex('restaurants').insert({ id: 3, name: 'Dump' })
);
