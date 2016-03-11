exports.up = (queryInterface, Sequelize) => queryInterface.createTable('restaurants_tags', {
  restaurant_id: {
    type: Sequelize.INTEGER,
    references: {
      model: 'restaurants',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade'
  },
  tag_id: {
    type: Sequelize.INTEGER,
    references: {
      model: 'tags',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade'
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

exports.down = queryInterface => queryInterface.dropTable('restaurants_tags');
