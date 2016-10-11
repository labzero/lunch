import moment from 'moment';
import { sequelize, DataTypes } from './db';

const Decision = sequelize.define('decision', {
  restaurant_id: {
    type: DataTypes.INTEGER,
    references: {
      model: 'restaurant',
      key: 'id'
    },
    allowNull: false,
    onDelete: 'cascade'
  }
}, {
  scopes: {
    fromToday: () => ({
      where: {
        created_at: {
          $gt: moment().subtract(12, 'hours').toDate()
        }
      }
    })
  },
  underscored: true
});

export default Decision;
