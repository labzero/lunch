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
  },
  team_id: DataTypes.INTEGER
}, {
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
});

export default Decision;
