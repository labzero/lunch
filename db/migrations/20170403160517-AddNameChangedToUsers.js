exports.up = (queryInterface, Sequelize) => queryInterface.addColumn('users', 'name_changed', {
  defaultValue: false,
  type: Sequelize.BOOLEAN
});

exports.down = queryInterface => queryInterface.removeColumn('users', 'name_changed');
