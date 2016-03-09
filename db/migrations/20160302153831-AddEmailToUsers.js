exports.up = (queryInterface, Sequelize) => queryInterface.addColumn('users', 'email', {
  type: Sequelize.STRING
});

exports.down = queryInterface => queryInterface.removeColumn('users', 'email');
