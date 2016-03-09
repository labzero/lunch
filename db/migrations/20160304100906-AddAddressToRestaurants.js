exports.up = (queryInterface, Sequelize) => queryInterface.addColumn('restaurants', 'address', {
  type: Sequelize.STRING,
  allowNull: false
});

exports.down = queryInterface => queryInterface.removeColumn('restaurants', 'address');
