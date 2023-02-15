import dayjs from 'dayjs';
import { sequelize, DataTypes } from './db';

const Decision = sequelize.define(
  'decision',
  {
    restaurantId: {
      type: DataTypes.INTEGER,
      references: {
        model: 'restaurant',
        key: 'id'
      },
      allowNull: false,
      onDelete: 'cascade'
    },
    teamId: DataTypes.INTEGER
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
        fields: ['createdAt', 'restaurantId']
      }
    ]
  }
);

export default Decision;
