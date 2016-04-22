exports.up = (queryInterface, Sequelize) => queryInterface.createTable('decisions', {
  id: {
    type: Sequelize.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  restaurant_id: {
    type: Sequelize.INTEGER,

    references: {
      model: 'restaurants',
      key: 'id'
    },
    allowNull: false
  },
  created_at: {
    allowNull: false,
    type: Sequelize.DATE
  },
  updated_at: {
    allowNull: false,
    type: Sequelize.DATE
  }
});

exports.down = queryInterface => queryInterface.dropTable('decisions');
