import dayjs from 'dayjs';
import { sequelize, DataTypes } from './db';

const Vote = sequelize.define(
  'vote',
  {
    userId: {
      type: DataTypes.INTEGER,
      references: {
        model: 'user',
        key: 'id'
      },
      allowNull: false
    },

    restaurantId: {
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
  },
  {
    indexes: [
      {
        fields: ['createdAt', 'restaurantId', 'userId']
      }
    ]
  }
);

Vote.recentForRestaurantAndUser = (restaurantId, userId, transaction) => Vote.scope('fromToday').count({
  where: {
    userId,
    restaurantId
  }
}, { transaction });

export default Vote;
