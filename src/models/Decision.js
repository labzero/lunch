import { sequelize, DataTypes } from './db';
import moment from 'moment';

const Decision = sequelize.define('decision', {
  restaurant_id: DataTypes.INTEGER
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
