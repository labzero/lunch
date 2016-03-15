exports.up = queryInterface => queryInterface.bulkInsert('restaurants', [
  { name: 'Food Barn', address: '123 main', created_at: new Date(), updated_at: new Date() },
  { name: 'Exquisite Smorgasbord', address: '123 main', created_at: new Date(), updated_at: new Date() },
  { name: 'The Dump', address: '123 main', created_at: new Date(), updated_at: new Date() }
]);

exports.down = queryInterface => queryInterface.bulkDelete('restaurants', [
  { name: 'Food Barn' },
  { name: 'Exquisite Smorgasbord' },
  { name: 'The Dump' }
]);
