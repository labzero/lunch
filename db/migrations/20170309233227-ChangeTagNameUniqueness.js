exports.up = (queryInterface, Sequelize) =>
  queryInterface.changeColumn('tags', 'name', {
    type: Sequelize.STRING,
    allowNull: false,
    unique: false
  });

exports.down = (queryInterface, Sequelize) =>
  queryInterface.changeColumn('tags', 'name', {
    type: Sequelize.STRING,
    unique: true
  });
