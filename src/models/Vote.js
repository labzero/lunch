import dayjs from 'dayjs';
import { sequelize, DataTypes } from './db';

const Vote = sequelize.define(
  'vote',
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
          createdAt: {
            [DataTypes.Op.gt]: dayjs().subtract(12, 'hours').toDate()
          }
        }
      })
    },
    underscored: true
  },
  {
    indexes: [
      {
        fields: ['created_at', 'restaurant_id', 'user_id']
      }
    ]
  }
);

Vote.recentForRestaurantAndUser = (restaurantId, userId, transaction) => Vote.scope('fromToday').count({
  where: {
    user_id: userId,
    restaurant_id: restaurantId
  }
}, { transaction });

export default Vote;
