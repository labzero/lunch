import moment from 'moment';
import Sequelize from 'sequelize';
import sequelize from './sequelize';
// import Restaurant from './Restaurant';
// import User from './User';

const Vote = sequelize.define('vote',
  {
    restaurant_id: Sequelize.INTEGER,
    user_id: Sequelize.INTEGER
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
