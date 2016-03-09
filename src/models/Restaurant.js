import Sequelize from 'sequelize';
import sequelize from './sequelize';
import Vote from './Vote';

const Restaurant = sequelize.define('restaurant', {
  name: Sequelize.STRING,
  address: Sequelize.STRING,
  lat: Sequelize.FLOAT,
  lng: Sequelize.FLOAT,
  place_id: Sequelize.STRING
}, {
  defaultScope: {
    order: 'votes.created_at ASC, created_at DESC'
  },
  underscored: true
});

Restaurant.hasMany(Vote);

export default Restaurant;
