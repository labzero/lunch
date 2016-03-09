exports.up = (queryInterface, Sequelize) => queryInterface.createTable('restaurants', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  name: {
    type: Sequelize.STRING,
    allowNull: false
  }
});

exports.down = queryInterface => queryInterface.dropTable('restaurants');
