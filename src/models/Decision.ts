import dayjs from 'dayjs';
import { sequelize, DataTypes, Op } from './db';

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
    indexes: [
      {
        fields: ['createdAt', 'restaurantId']
      }
    ],
    scopes: {
      fromToday: () => ({
        where: {
          createdAt: {
            [Op.gt]: dayjs().subtract(12, 'hours').toDate()
          }
        }
      })
    },
  }
);

export default Decision;
