import { sequelize, DataTypes } from './db';

const RestaurantsTags = sequelize.define('restaurants_tags', {
  restaurant_id: {
    type: DataTypes.INTEGER,
    references: {
      model: 'restaurant',
      key: 'id'
    },
    allowNull: false
  },
  tag_id: {
    type: DataTypes.INTEGER,
    references: {
      model: 'tag',
      key: 'id'
    },
    allowNull: false
  }
});

export default RestaurantsTags;
