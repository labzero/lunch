exports.up = function(queryInterface, Sequelize) {
  return queryInterface.createTable('restaurants_tags', {
    restaurant_id: {
      type: Sequelize.INTEGER
    },
    tag_id: {
      type: Sequelize.INTEGER
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
};

exports.down = function(queryInterface, Sequelize) {
  return queryInterface.dropTable('restaurants_tags');
};
