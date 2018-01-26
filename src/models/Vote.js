import moment from 'moment';
import { sequelize, DataTypes } from './db';

const Vote = sequelize.define('vote',
  {
    user_id: {
      type: DataTypes.INTEGER,
      references: {
        model: 'user',
        key: 'id'
      },
      allowNull: false
    },

    restaurant_id: {
      type: DataTypes.INTEGER,
      references: {
        model: 'restaurant',
        key: 'id'
      },
      allowNull: false,
      onDelete: 'cascade'
    }
  },
  {
    scopes: {
      fromToday: () => ({
        where: {
          created_at: {
            [DataTypes.Op.gt]: moment().subtract(12, 'hours').toDate()
          }
        }
      })
    },
    underscored: true
  }
);

Vote.recentForRestaurantAndUser = (restaurantId, userId) =>
  Vote.scope('fromToday').count({
    where: {
      user_id: userId,
      restaurant_id: restaurantId
    }
  });

export default Vote;
