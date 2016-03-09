exports.up = (queryInterface, Sequelize) => queryInterface.createTable('users', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  google_id: {
    type: Sequelize.STRING,
    allowNull: false
  },
  name: {
    type: Sequelize.STRING
  }
});

exports.down = queryInterface => queryInterface.dropTable('users');
