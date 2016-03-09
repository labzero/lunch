import Sequelize from 'sequelize';
import sequelize from './sequelize';
import Vote from './Vote';

const Restaurant = sequelize.define('restaurant', {
  name: Sequelize.STRING,
  address: Sequelize.STRING,
  lat: Sequelize.FLOAT,
  lng: Sequelize.FLOAT,
  place_id: Sequelize.STRING
}, { underscored: true });

Restaurant.hasMany(Vote);

export default Restaurant;
