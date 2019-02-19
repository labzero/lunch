exports.up = (queryInterface, Sequelize) => queryInterface.addColumn('teams', 'slug', {
  type: Sequelize.STRING(63),
  unique: true,
});

exports.down = queryInterface => queryInterface.removeColumn('teams', 'slug');
