import { sequelize, DataTypes } from './db';

const RestaurantTag = sequelize.define('restaurants_tags', {
  restaurant_id: {
    type: DataTypes.INTEGER,
    references: {
      model: 'restaurant',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade'
  },
  tag_id: {
    type: DataTypes.INTEGER,
    references: {
      model: 'tag',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade'
  }
}, {
  uniqueKeys: {
    unique: {
      fields: ['restaurant_id', 'tag_id']
    }
  },
  underscored: true
});
RestaurantTag.removeAttribute('id');

export default RestaurantTag;
