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
      allowNull: false
    }
  },
  {
    scopes: {
      fromToday: {
        where: {
          created_at: {
            $gt: moment().subtract(12, 'hours').toDate()
          }
        }
      }
    },
    underscored: true
  }
);

export default Vote;
