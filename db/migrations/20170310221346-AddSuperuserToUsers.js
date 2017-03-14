exports.up = (queryInterface, Sequelize) =>
  queryInterface.addColumn('users', 'superuser', {
    allowNull: false,
    type: Sequelize.BOOLEAN,
    defaultValue: false
  });

exports.down = queryInterface =>
  queryInterface.removeColumn('users', 'superuser');
