exports.up = (queryInterface, Sequelize) => queryInterface.changeColumn('restaurants', 'place_id', {
  type: Sequelize.STRING,
  unique: false
}).then(() => queryInterface.sequelize.query('ALTER TABLE restaurants DROP CONSTRAINT restaurants_place_id_key;'));

exports.down = (queryInterface, Sequelize) => queryInterface.changeColumn('restaurants', 'place_id', {
  type: Sequelize.STRING,
  unique: true
});
