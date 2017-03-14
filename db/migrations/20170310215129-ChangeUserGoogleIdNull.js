exports.up = (queryInterface, Sequelize) =>
  queryInterface.changeColumn('users', 'google_id', {
    type: Sequelize.STRING
  });

exports.down = (queryInterface, Sequelize) =>
  queryInterface.changeColumn('users', 'google_id', {
    type: Sequelize.STRING,
    allowNull: false
  });
