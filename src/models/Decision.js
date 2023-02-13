import dayjs from 'dayjs';
import { sequelize, DataTypes } from './db';

const Decision = sequelize.define(
  'decision',
  {
    restaurant_id: {
      type: DataTypes.INTEGER,
      references: {
        model: 'restaurant',
        key: 'id'
      },
      allowNull: false,
      onDelete: 'cascade'
    },
    team_id: DataTypes.INTEGER
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
        fields: ['created_at', 'restaurant_id']
      }
    ]
  }
);

export default Decision;
