exports.up = (queryInterface, Sequelize) => queryInterface.addColumn('teams', 'default_zoom', {
  type: Sequelize.INTEGER
});

exports.down = queryInterface => queryInterface.removeColumn('teams', 'default_zoom');
