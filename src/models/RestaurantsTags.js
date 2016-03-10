import { sequelize, DataTypes } from './db';

const RestaurantsTags = sequelize.define('restaurants_tags', {
  restaurant_id: {
    type: DataTypes.INTEGER,
    references: {
      model: 'restaurant',
      key: 'id'
    }
  },
  tag_id: {
    type: DataTypes.INTEGER,
    references: {
      model: 'tag',
      key: 'id'
    }
  }
}, {
  classMethods: {
    associate: function(models) {
      // associations can be defined here
    }
  }
});

export default RestaurantsTags
